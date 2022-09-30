--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--
pragma Ada_2022;

with Ada.Containers.Generic_Anonymous_Array_Sort;
with Ada.Containers.Vectors;

with VSS.Implementation.Strings;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Cursors.Internals;
with VSS.Strings.Cursors.Markers.Internals;
with VSS.Strings.Cursors.Markers;
with VSS.Strings.Internals;
with VSS.Strings;

with Markdown.Implementation;

package body Markdown.Inline_Parsers is

   type Markup_Kind is (Emphasis, Link);

   type Markup (Kind : Markup_Kind := Emphasis) is record
      From   : VSS.Strings.Cursors.Markers.Character_Marker;
      To     : VSS.Strings.Cursors.Markers.Character_Marker;
      --  TO DO: Replace with Segment_Marker
      case Kind is
         when Link =>
            URL : VSS.Strings.Virtual_String;
            Title : VSS.String_Vectors.Virtual_String_Vector;
         when Emphasis =>
            null;
      end case;
   end record;

   function To_Emphasis
     (From   : VSS.Strings.Cursors.Markers.Character_Marker;
      Offset : VSS.Strings.Character_Count;
      Count  : VSS.Strings.Character_Index) return Markup;

   type Markup_Index is new Positive;

   package Markup_Vectors is new Ada.Containers.Vectors (Markup_Index, Markup);

   procedure Find_Markup
     (Self   : Inline_Parser;
      Text   : VSS.Strings.Virtual_String;
      Markup : out Markup_Vectors.Vector);

   procedure Process_Emphasis
     (Markup    : in out Markup_Vectors.Vector;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      From      : Positive := 1;
      To        : Natural := Natural'Last);

   procedure Forward
     (Marker : in out VSS.Strings.Cursors.Markers.Character_Marker;
      Count  : VSS.Strings.Character_Count);

   function To_Annotated_Text
     (Text   : VSS.Strings.Virtual_String;
      Markup : Markup_Vectors.Vector)
      return Markdown.Annotations.Annotated_Text;

   procedure Read_Character
     (Cursor : in out VSS.Strings.Character_Iterators.Character_Iterator;
      Result : in out VSS.Strings.Virtual_String);

   -----------------
   -- Find_Markup --
   -----------------

   procedure Find_Markup
     (Self   : Inline_Parser;
      Text   : VSS.Strings.Virtual_String;
      Markup : out Markup_Vectors.Vector)
   is
      pragma Unreferenced (Self);

      Cursor : VSS.Strings.Character_Iterators.Character_Iterator :=
        Text.At_First_Character;

      Is_Delimiter : Boolean;
      Item         : Emphasis_Delimiters.Delimiter;
      Scanner      : Emphasis_Delimiters.Scanner;
      List         : Emphasis_Delimiters.Delimiter_Vectors.Vector;
   begin
      Scanner.Reset;

      while Cursor.Has_Element loop
         Scanner.Read_Delimiter (Text, Cursor, Item, Is_Delimiter);

         if Is_Delimiter then
            List.Append (Item);
         end if;
      end loop;

      Process_Emphasis (Markup, List);
   end Find_Markup;

   -------------
   -- Forward --
   -------------

   procedure Forward
     (Marker : in out VSS.Strings.Cursors.Markers.Character_Marker;
      Count  : VSS.Strings.Character_Count)
   is
      use type VSS.Strings.Character_Count;

   begin
      if Count > 0 then
         declare
            Iterator : VSS.Strings.Character_Iterators.Character_Iterator;
         begin
            Iterator.Set_At (Marker);
            Markdown.Implementation.Forward (Iterator, Count);
            Marker := Iterator.Marker;
         end;
      end if;
   end Forward;

   -----------
   -- Parse --
   -----------

   function Parse
     (Self  : Inline_Parser;
      Lines : VSS.String_Vectors.Virtual_String_Vector)
        return Markdown.Annotations.Annotated_Text
   is
      Text : constant VSS.Strings.Virtual_String :=
        Lines.Join_Lines (VSS.Strings.LF, False);
      Markup : Markup_Vectors.Vector;
   begin
      Self.Find_Markup (Text, Markup);

      return To_Annotated_Text (Text, Markup);
   end Parse;

   ----------------------
   -- Process_Emphasis --
   ----------------------

   procedure Process_Emphasis
     (Markup    : in out Markup_Vectors.Vector;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      From      : Positive := 1;
      To        : Natural := Natural'Last)
   is
      use Emphasis_Delimiters;
      use type VSS.Strings.Character_Index;

      function "+" (Cursor : Emphasis_Delimiters.Delimiter_Vectors.Cursor)
        return Extended_Delimiter_Index
          renames Emphasis_Delimiters.Delimiter_Vectors.To_Index;

      Openers_Bottom : array
        (Emphasis_Kind, VSS.Strings.Character_Count range 0 .. 2)
          of Extended_Delimiter_Index
            := [others => [others => 0]];
   begin
      for J in Each (Delimiter, (Kind => Emphasis_Close), From, To) loop
         declare
            Closer : Emphasis_Delimiters.Delimiter renames Delimiter (J);
            Found  : Boolean := False;
         begin
            Each_Open_Emphasis :
            for K in reverse Each
              (Delimiter,
               Filter => (Emphasis_Open, Closer.Kind),
               From => Delimiter_Index'Max
                 (From,
                  Openers_Bottom (Closer.Kind, Closer.Count mod 3)),
               To   => +J - 1)
            loop
               declare
                  Opener : Emphasis_Delimiters.Delimiter renames Delimiter (K);
                  Count  : VSS.Strings.Character_Index range 1 .. 2;
               begin
                  while not Opener.Is_Deleted and then
                     --  If one of the delimiters can both open and close
                     --  emphasis, then the sum of the lengths of the
                     --  delimiter runs containing the opening and closing
                     --  delimiters must not be a multiple of 3 unless both
                     --  lengths are multiples of 3.
                    (not ((Opener.Can_Open and Opener.Can_Close) or
                          (Closer.Can_Open and Closer.Can_Close))
                     or else (Opener.Count + Closer.Count) mod 3 /= 0
                     or else (Opener.Count mod 3 = 0 and
                                 Closer.Count mod 3 = 0))
                  loop
                     Found := True;

                     Count := VSS.Strings.Character_Index'Min
                       (2,
                        VSS.Strings.Character_Index'Min
                          (Opener.Count, Closer.Count));

                     Markup.Append
                       (To_Emphasis
                          (Opener.From, Opener.Count - Count, Count));

                     Markup.Append (To_Emphasis (Closer.From, 0, Count));

                     for M in +K + 1 .. +J - 1 loop
                        Delimiter (M).Is_Deleted := True;
                     end loop;

                     if Opener.Count = Count then
                        Opener.Is_Deleted := True;
                     else
                        Opener.Count := Opener.Count - Count;
                     end if;

                     if Closer.Count = Count then
                        Closer.Is_Deleted := True;
                        exit Each_Open_Emphasis;
                     else
                        Closer.Count := Closer.Count - Count;
                        Forward (Closer.From, Count);
                        --  Closer.From := Closer.From  + Count;
                     end if;
                  end loop;
               end;
            end loop Each_Open_Emphasis;

            if not Found then
               if not Closer.Can_Open then
                  Closer.Is_Deleted := True;
               end if;

               Openers_Bottom (Closer.Kind, Closer.Count mod 3) := +J;
            end if;
         end;
      end loop;
   end Process_Emphasis;

   --------------------
   -- Read_Character --
   --------------------

   procedure Read_Character
     (Cursor : in out VSS.Strings.Character_Iterators.Character_Iterator;
      Result : in out VSS.Strings.Virtual_String) is
   begin
      Result.Append (Cursor.Element);
      Markdown.Implementation.Forward (Cursor);
   end Read_Character;

   -----------------------
   -- To_Annotated_Text --
   -----------------------

   function To_Annotated_Text
     (Text   : VSS.Strings.Virtual_String;
      Markup : Markup_Vectors.Vector)
      return Markdown.Annotations.Annotated_Text
   is
      use type VSS.Strings.Character_Index;

      Map : array
        (Positive range 1 .. Natural (Markup.Length)) of Markup_Index;

      type Annotation_Info is record
         Index  : Positive;
         Markup : Markup_Index;
         From   : VSS.Implementation.Strings.Cursor;
         To     : VSS.Implementation.Strings.Cursor;
      end record;

      List : array
        (Markup_Index range 1 .. Markup.Last_Index / 2) of Annotation_Info :=
          [others => (Index => 1, others => <>)];

      function To_Annotation
        (Text : in out VSS.Strings.Virtual_String;
         Info : Annotation_Info) return Markdown.Annotations.Annotation;

      function Next_Char
        (Text : VSS.Strings.Virtual_String)
         return VSS.Implementation.Strings.Cursor is
           (VSS.Strings.Cursors.Internals.First_Cursor_Access_Constant
              (Text.After_Last_Character).all);

      function Current_Char
        (Text : VSS.Strings.Virtual_String)
         return VSS.Implementation.Strings.Cursor is
           (VSS.Strings.Cursors.Internals.First_Cursor_Access_Constant
              (Text.At_Last_Character).all);

      function Less (Left, Right : Positive) return Boolean;

      procedure Swap (Left, Right : Positive);

      function From (Index : Positive) return VSS.Strings.Character_Index;

      ----------
      -- From --
      ----------

      function From (Index : Positive) return VSS.Strings.Character_Index is
         X : VSS.Strings.Cursors.Abstract_Character_Cursor'Class renames
           VSS.Strings.Cursors.Abstract_Character_Cursor'Class
             (Markup (Map (Index)).From);
      begin
         return X.Character_Index;
      end From;

      ----------
      -- Less --
      ----------

      function Less (Left, Right : Positive) return Boolean is
      begin
         return From (Left) < From (Right);
      end Less;

      ----------
      -- Swap --
      ----------

      procedure Swap (Left, Right : Positive) is
         Temp : constant Markup_Index := Map (Left);
      begin
         Map (Left) := Map (Right);
         Map (Right) := Temp;
      end Swap;

      -------------------
      -- To_Annotation --
      -------------------

      function To_Annotation
        (Text : in out VSS.Strings.Virtual_String;
         Info : Annotation_Info) return Markdown.Annotations.Annotation
      is
         function Segment return VSS.Strings.Cursors.Markers.Segment_Marker is
           (VSS.Strings.Cursors.Markers.Internals.New_Segment_Marker
              (VSS.Strings.Internals.To_Magic_String_Access
                 (Text'Unchecked_Access).all,
               Info.From,
               Info.To));

         Item : Inline_Parsers.Markup renames Markup (Info.Markup);
      begin
         case Item.Kind is
            when Emphasis =>
               if Item.To.Character_Index - Item.From.Character_Index = 1 then
                  return (Markdown.Annotations.Emphasis, Segment);
               else
                  return (Markdown.Annotations.Strong, Segment);
               end if;
            when Link =>
               raise Program_Error;
         end case;
      end To_Annotation;

      procedure Sort is new Ada.Containers.Generic_Anonymous_Array_Sort
        (Index_Type => Positive,
         Less       => Less,
         Swap       => Swap);

      Index  : Positive := Map'First;
      Last   : Natural := 0;  --  Annotation index
      Cursor : VSS.Strings.Character_Iterators.Character_Iterator :=
        Text.At_First_Character;
   begin
      for J in Map'Range loop
         Map (J) := Markup_Index (J);
      end loop;

      Sort (1, Map'Last);

      return Result : Markdown.Annotations.Annotated_Text do

         --  Fill Result.Plain_Text and annotation info List
         while Cursor.Has_Element loop
            if Index in Map'Range and then
              From (Index) = Cursor.Character_Index
            then
               declare
                  Item : Inline_Parsers.Markup renames Markup (Map (Index));
               begin
                  if Map (Index) mod 2 = 1 then  --  Open markup
                     Last := Last + 1;

                     List ((Map (Index) + 1) / 2) :=
                       (Last,
                        Map (Index),
                        Next_Char (Result.Plain_Text),
                        To => <>);
                  else
                     List (Map (Index) / 2).To :=
                       Current_Char (Result.Plain_Text);
                  end if;

                  Cursor.Set_At (Item.To);
                  Index := Index + 1;
               end;
            else
               Read_Character (Cursor, Result.Plain_Text);
            end if;
         end loop;

         Result.Annotation.Append ((others => <>), Natural'Pos (Last));

         for X of List loop
            Result.Annotation.Replace_Element
              (X.Index, To_Annotation (Result.Plain_Text, X));
         end loop;
      end return;

      --  Marker :=
      --    VSS.Strings.Cursors.Markers.Internals.New_Segment_Marker
      --      (Result.Plain_Text.Get_Owner,
      --       First => From,
      --       Last  => To);

   end To_Annotated_Text;

   -----------------
   -- To_Emphasis --
   -----------------

   function To_Emphasis
     (From   : VSS.Strings.Cursors.Markers.Character_Marker;
      Offset : VSS.Strings.Character_Count;
      Count  : VSS.Strings.Character_Index) return Markup
   is
   begin
      return Result : Markup (Emphasis) do
         Result.From := From;
         Forward (Result.From, Offset);
         Result.To := Result.From;
         Forward (Result.To, Count);
      end return;
   end To_Emphasis;

end Markdown.Inline_Parsers;
