--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Characters;

with Markdown.Implementation;

package body Markdown.Emphasis_Delimiters is

   subtype Character_Iterator is
     VSS.Strings.Character_Iterators.Character_Iterator;

   Space_Pattern : constant Wide_Wide_String := "[\p{Zs} ]|\t|\n|\r|\f";

   ASCII_Punctuation : constant Wide_Wide_String :=
     "-!""#$%&'()*+,./:;<=>?@[^_`{|}~";

   Punctuation_Pattern : constant Wide_Wide_String :=
     "[" & ASCII_Punctuation &
     "\p{Pc}\p{Pd}\p{Pe}\p{Pf}\p{Pi}\p{Po}\p{Ps}]|\]";

   Pattern : constant Wide_Wide_String :=
     "^(" & Space_Pattern & ")|^(" & Punctuation_Pattern & ")";

   procedure Initialize (Self : in out Scanner'Class);

   function Get_State
     (Self   : Scanner'Class;
      Text   : VSS.Strings.Virtual_String;
      Cursor : Character_Iterator) return Scanner_State;

   function Count_Character (Cursor : Character_Iterator)
     return VSS.Strings.Character_Index
       with Pre => Cursor.Has_Element;
   --  Count length of delimiter run (number of stars in a row, etc)

   procedure Forward
     (Cursor : in out Character_Iterator;
      Count  : VSS.Strings.Character_Index := 1)
     renames Markdown.Implementation.Forward;

   type Iterator is limited new
     Delimiter_Vectors.Vector_Iterator_Interfaces.Reversible_Iterator with
      record
         List   : not null access constant Delimiter_Vectors.Vector;
         Filter : Delimiter_Filter;
         First  : Positive;
         Last   : Natural;
      end record;

   overriding function First (Self : Iterator) return Delimiter_Vectors.Cursor;

   overriding function Last (Self : Iterator) return Delimiter_Vectors.Cursor;

   overriding function Next
     (Self  : Iterator;
      Index : Delimiter_Vectors.Cursor) return Delimiter_Vectors.Cursor;

   overriding function Previous
     (Self  : Iterator;
      Index : Delimiter_Vectors.Cursor) return Delimiter_Vectors.Cursor;

   function Check
     (Item   : Delimiter;
      Filter : Delimiter_Filter) return Boolean;

   -----------
   -- Check --
   -----------

   function Check
     (Item   : Delimiter;
      Filter : Delimiter_Filter) return Boolean
   is
      use type VSS.Strings.Character_Index;
   begin
      if not Item.Is_Deleted then
         case Filter.Kind is
            when Before =>
               return Item.From.Character_Index < Filter.Index;
            when Emphasis_Open =>
               return Item.Kind = Filter.Emphasis and then Item.Can_Open;
            when Emphasis_Close =>
               return Item.Kind in Emphasis_Kind and then Item.Can_Close;
            when Kind_Of =>
               return Item.Kind = Filter.Given_Kind;
            when Link_Or_Image =>
               return Item.Kind in '!' | '[';
            when Any_Element =>
               return True;
         end case;
      end if;

      return False;
   end Check;

   ---------------------
   -- Count_Character --
   ---------------------

   function Count_Character (Cursor : Character_Iterator)
     return VSS.Strings.Character_Index
   is
      use type VSS.Characters.Virtual_Character;
      use type VSS.Strings.Character_Index;

      Char   : constant VSS.Characters.Virtual_Character := Cursor.Element;
      Next   : Character_Iterator;
      Result : VSS.Strings.Character_Index := 1;
   begin
      Next.Set_At (Cursor);

      while Next.Forward and then Next.Element = Char loop
         Result := Result + 1;
      end loop;

      return Result;
   end Count_Character;

   ----------
   -- Each --
   ----------

   function Each
     (Self   : aliased Delimiter_Vectors.Vector;
      Filter : Delimiter_Filter := (Kind => Any_Element);
      From   : Positive := 1;
      To     : Natural := Natural'Last)
        return Delimiter_Vectors.Vector_Iterator_Interfaces
          .Reversible_Iterator'Class
             is (Iterator'(Self'Access,
                           Filter,
                           From,
                           Natural'Min (To, Self.Last_Index)));

   -----------
   -- First --
   -----------

   overriding function First
     (Self : Iterator) return Delimiter_Vectors.Cursor
   is
   begin
      for J in Self.First .. Self.Last loop
         if Check (Self.List (J), Self.Filter) then
            return Self.List.To_Cursor (J);
         end if;
      end loop;

      return Delimiter_Vectors.No_Element;
   end First;

   ---------------
   -- Get_State --
   ---------------

   function Get_State
     (Self   : Scanner'Class;
      Text   : VSS.Strings.Virtual_String;
      Cursor : Character_Iterator) return Scanner_State
   is
      use type VSS.Strings.Virtual_String;

      Match : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      if Cursor.Has_Element then
         Match := Self.Pattern.Match (Text, Cursor);
      else
         return
           (Is_White_Space => True,
            Is_Punctuation => False,
            Is_Exclamation => False);
      end if;

      if not Match.Has_Match then
         return
           (Is_White_Space => False,
            Is_Punctuation => False,
            Is_Exclamation => False);
      elsif Match.Has_Capture (1) then
         return
           (Is_White_Space => True,
            Is_Punctuation => False,
            Is_Exclamation => False);
      elsif Match.Has_Capture (2) then
         return
           (Is_White_Space => False,
            Is_Punctuation => True,
            Is_Exclamation => Match.Captured (2) = "!");
      else
         raise Program_Error;
      end if;
   end Get_State;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out Scanner'Class) is
   begin
      Self.Pattern := VSS.Regular_Expressions.To_Regular_Expression
        (VSS.Strings.To_Virtual_String (Pattern));

      pragma Assert (Self.Pattern.Is_Valid);
   end Initialize;

   ----------
   -- Last --
   ----------

   overriding function Last
     (Self : Iterator) return Delimiter_Vectors.Cursor is
   begin
      for J in reverse Self.First .. Self.Last loop
         if Check (Self.List (J), Self.Filter) then
            return Self.List.To_Cursor (J);
         end if;
      end loop;

      return Delimiter_Vectors.No_Element;
   end Last;

   ----------
   -- Next --
   ----------

   overriding function Next
     (Self  : Iterator;
      Index : Delimiter_Vectors.Cursor) return Delimiter_Vectors.Cursor is
   begin
      if Delimiter_Vectors.Has_Element (Index) then
         for J in Delimiter_Vectors.To_Index (Index) + 1 .. Self.Last loop
            if Check (Self.List (J), Self.Filter) then
               return Self.List.To_Cursor (J);
            end if;
         end loop;
      end if;

      return Delimiter_Vectors.No_Element;
   end Next;

   --------------
   -- Previous --
   --------------

   overriding function Previous
     (Self  : Iterator;
      Index : Delimiter_Vectors.Cursor) return Delimiter_Vectors.Cursor is
   begin
      if Delimiter_Vectors.Has_Element (Index) then
         for J in reverse
           Self.First .. Delimiter_Vectors.To_Index (Index) - 1
         loop
            if Check (Self.List (J), Self.Filter) then
               return Self.List.To_Cursor (J);
            end if;
         end loop;
      end if;

      return Delimiter_Vectors.No_Element;
   end Previous;

   --------------------
   -- Read_Delimiter --
   --------------------

   procedure Read_Delimiter
     (Self   : in out Scanner;
      Text   : VSS.Strings.Virtual_String;
      Cursor : in out VSS.Strings.Character_Iterators.Character_Iterator;
      Item   : out Delimiter;
      Found  : out Boolean)
   is
      Follow : Scanner_State;
   begin
      if not Cursor.Has_Element then
         Found := False;
         return;
      elsif not Self.Pattern.Is_Valid then
         Self.Initialize;
      end if;

      case Cursor.Element is
         when '*' =>
            declare
               Next   : Delimiter :=
                 (Kind   => '*',
                  From   => Cursor.Marker,
                  Count  => Count_Character (Cursor),
                  others => False);
            begin
               Forward (Cursor, Next.Count);
               Follow := Self.Get_State (Text, Cursor);  --  Get_Follow_State

               --  Left flanking
               Next.Can_Open := not Follow.Is_White_Space and then
                 (not Follow.Is_Punctuation or else
                   (Self.State.Is_White_Space or Self.State.Is_Punctuation));

               --  Right flanking
               Next.Can_Close := not Self.State.Is_White_Space and then
                 (not Self.State.Is_Punctuation or else
                   (Follow.Is_White_Space or Follow.Is_Punctuation));

               Self.State := Follow;
               Item := Next;
               Found := True;
            end;

         when '_' =>
            declare
               Left_Flanking  : Boolean;
               Right_Flanking : Boolean;
               Next           : Delimiter :=
                 (Kind   => '_',
                  From   => Cursor.Marker,
                  Count  => Count_Character (Cursor),
                  others => False);
            begin
               Forward (Cursor, Next.Count);
               Follow := Self.Get_State (Text, Cursor);  --  Get_Follow_State

               Left_Flanking := not Follow.Is_White_Space and then
                 (not Follow.Is_Punctuation or else
                   (Self.State.Is_White_Space or Self.State.Is_Punctuation));

               --  Right flanking
               Right_Flanking := not Self.State.Is_White_Space and then
                 (not Self.State.Is_Punctuation or else
                   (Follow.Is_White_Space or Follow.Is_Punctuation));

               Next.Can_Open := Left_Flanking and
                 (not Right_Flanking or else Self.State.Is_Punctuation);

               Next.Can_Close := Right_Flanking and
                 (not Left_Flanking or else Follow.Is_Punctuation);

               Self.State := Follow;
               Item := Next;
               Found := True;
            end;

         when '[' =>
            if Self.State.Is_Exclamation then
               Found := Cursor.Backward;  --  Step back to `!`
               Item := (Kind       => '!',  --  ![ found
                        From       => Cursor.Marker,
                        Is_Deleted => False);
               Forward (Cursor);
            else
               Item := (Kind       => '[',
                        From       => Cursor.Marker,
                        Is_Deleted => False);
            end if;

            Self.State := Self.Get_State (Text, Cursor);
            Forward (Cursor);
            Found := True;

         when ']' =>
            Self.State := Self.Get_State (Text, Cursor);
            Item := (Kind       => ']',
                     From       => Cursor.Marker,
                     To         => Cursor.Marker,
                     Is_Deleted => False);
            Forward (Cursor);
            Found := True;

         when '\' =>
            Self.State := Self.Get_State (Text, Cursor);
            Forward (Cursor, 2);
            Found := False;

         when others =>
            Self.State := Self.Get_State (Text, Cursor);
            Forward (Cursor);
            Found := False;

      end case;
   end Read_Delimiter;

   -----------
   -- Reset --
   -----------

   procedure Reset (Self : in out Scanner) is
   begin
      Self.State := (others => <>);
   end Reset;

end Markdown.Emphasis_Delimiters;
