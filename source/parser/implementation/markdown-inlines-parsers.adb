--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
pragma Ada_2022;

with Ada.Containers.Generic_Anonymous_Array_Sort;
with Ada.Containers.Vectors;

with VSS.Characters;
with VSS.Regular_Expressions;
with VSS.Strings.Character_Iterators;

with Markdown.Implementation.HTML;
with VSS.Strings.Cursors.Markers;

package body Markdown.Inlines.Parsers is

   package HTML renames Markdown.Implementation.HTML;

   type Markup_Kind is (Emphasis, Link, Image, Simple);

   subtype Link_Or_Image is Markup_Kind range Link .. Image;

   type Markup (Kind : Markup_Kind := Emphasis) is record
      From   : VSS.Strings.Cursors.Markers.Character_Marker;
      To     : VSS.Strings.Cursors.Markers.Character_Marker;
      case Kind is
         when Link_Or_Image =>
            URL : VSS.Strings.Virtual_String;
            Title : VSS.String_Vectors.Virtual_String_Vector;
            Attributes : Markdown.Attribute_Lists.Attribute_List;
         when Emphasis =>
            null;
         when Simple =>
            Annotation : Markdown.Inlines.Inline;
            Text       : VSS.Strings.Virtual_String;
            --  Extra internal text for links/images
      end case;
   end record;

   function To_Emphasis
     (From   : VSS.Strings.Cursors.Markers.Character_Marker;
      Offset : VSS.Strings.Character_Count;
      Count  : VSS.Strings.Character_Index) return Markup;

   type Markup_Index is new Positive;

   package Markup_Vectors is new Ada.Containers.Vectors (Markup_Index, Markup);

   procedure Find_Delimiters
     (Scanner : in out Emphasis_Delimiters.Scanner;
      Text    : VSS.Strings.Virtual_String;
      From    : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Limit   : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      List    : in out Emphasis_Delimiters.Delimiter_Vectors.Vector);

   procedure Process_Emphasis
     (Markup    : in out Markup_Vectors.Vector;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      From      : Positive := 1;
      To        : Natural := Natural'Last);

   procedure Process_Links
     (Text      : VSS.Strings.Virtual_String;
      With_Attr : Boolean;
      Markup    : in out Markup_Vectors.Vector;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      Bottom    : Natural := 1);

   procedure Forward
     (Marker : in out VSS.Strings.Cursors.Markers.Character_Marker;
      Count  : VSS.Strings.Character_Count);

   function To_Annotated_Text
     (Start  : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Markup : Markup_Vectors.Vector)
      return Markdown.Inlines.Inline_Vector;

   procedure Parse_Link_Ahead
     (Text      : VSS.Strings.Virtual_String;
      With_Attr : Boolean;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      Close     : Positive;
      URL       : out VSS.Strings.Virtual_String;
      Title     : out VSS.Strings.Virtual_String;
      Attr      : out Markdown.Attribute_Lists.Attribute_List;
      Ok        : out Boolean);

   procedure Parse_Link_Destination
     (Text : VSS.Strings.Virtual_String;
      From : VSS.Strings.Cursors.Markers.Character_Marker;
      Last : out VSS.Strings.Cursors.Markers.Character_Marker;
      URL  : out VSS.Strings.Virtual_String;
      Ok   : out Boolean);

   function "<"
     (Left, Right : VSS.Strings.Cursors.Abstract_Character_Cursor'Class)
       return Boolean renames Markdown.Implementation."<";

   Link_Start_Pattern : constant Wide_Wide_String :=
     "^\]\([\t\n\v\f\r ]*\S";
   --  `](` with optional spaces plus one non-space character

   Link_Start : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Link_Start_Pattern

   Link_Destination_Pattern : constant Wide_Wide_String :=
     "^<((?:[^<>\\]|\\[^\n\r])*)>";
   --  zero or more characters between an opening < and a closing > that
   --  contains no line breaks or non-escaped < or > characters

   Link_Destination : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Link_Destination_Pattern

   Link_Title_Sub_Pattern : constant Wide_Wide_String :=
     """(?:[^""\\]|\\[^\f])*""" &
     --  zero or more characters between straight double-quote characters ("),
     --  including a " character only if it is backslash-escaped
     "|'(?:[^'\\]|\\[^\f])*'" &
     --  zero or more characters between straight single-quote characters ('),
     --  including a ' character only if it is backslash-escaped
     "|\((?:[^()\\]|\\[^\f])*\)"
     --  zero or more characters between matching parentheses ((...)),
     --  including a ( or ) character only if it is backslash-escaped.
   ;

   Link_Title_Pattern : constant Wide_Wide_String :=
     "^\s*(" & Link_Title_Sub_Pattern & ")?\s*\)";

   Link_Title : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Link_Title_Pattern

   Attribute : constant Wide_Wide_String :=
     "[.#]?" & HTML.Attribute_Name & "(?:" & HTML.Attribute_Value_Spec & ")?";

   Attribute_List : constant Wide_Wide_String :=
     "(?:" & Attribute & ")?(?:\s+" & Attribute & ")*";

   Attributes_Pattern : constant Wide_Wide_String :=
     "\{(\s*" & Attribute_List & "\s*)\}";

   Attributes : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Attributes_Pattern

   End_Of_Line_Pattern : constant Wide_Wide_String := "(.\\|\S *)?\n *";
   --  The first character in the group 1 matches the last character in the
   --  line (excluding markup). Like `abc__\n__`, where `abc` text of the line
   --  and `__\n__` is line break markup.

   End_Of_Line : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of End_Of_Line_Pattern

   -----------------
   -- Find_Markup --
   -----------------

   procedure Find_Delimiters
     (Scanner : in out Emphasis_Delimiters.Scanner;
      Text    : VSS.Strings.Virtual_String;
      From    : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Limit   : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      List    : in out Emphasis_Delimiters.Delimiter_Vectors.Vector)
   is
      Cursor : VSS.Strings.Character_Iterators.Character_Iterator;

      Is_Delimiter : Boolean;
      Item         : Emphasis_Delimiters.Delimiter;
   begin
      Cursor.Set_At (From);

      while Cursor < Limit loop
         Scanner.Read_Delimiter (Text, Cursor, Item, Is_Delimiter);

         if Is_Delimiter then
            List.Append (Item);
         end if;
      end loop;
   end Find_Delimiters;

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
     (Self : Inline_Parser'Class;
      Text : VSS.Strings.Virtual_String)
      return Markdown.Inlines.Inline_Vector
   is

      List    : Emphasis_Delimiters.Delimiter_Vectors.Vector;
      Markup  : Markup_Vectors.Vector;
      State   : Simple_Inline_Parsers.Inline_Span_Vectors.Vector;
      Scanner : Emphasis_Delimiters.Scanner;
      Cursor  : VSS.Strings.Character_Iterators.Character_Iterator :=
        Text.At_First_Character;
   begin
      if not Link_Start.Is_Valid then
         Link_Start := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Link_Start_Pattern));

         Link_Destination := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Link_Destination_Pattern));

         Link_Title := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Link_Title_Pattern));

         Attributes := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Attributes_Pattern));

         End_Of_Line := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (End_Of_Line_Pattern));
      end if;

      Simple_Inline_Parsers.Initialize
        (Self.Parsers, Text, Text.At_First_Character, State);

      --  Iterate over simple parsers and collect their findings into Markup.
      --  Parse intermediate spans to find emphasis/links delimiters and
      --  collect delimiters into List.

      while Cursor.Has_Element loop
         declare
            Span   : Simple_Inline_Parsers.Inline_Span;
            Ignore : Boolean;
            Item   : Parsers.Markup;
         begin

            Simple_Inline_Parsers.Get_Next_Inline
              (Self.Parsers, Text, State, Span);

            if Span.Is_Set then
               if Cursor < Span.From then
                  Find_Delimiters (Scanner, Text, Cursor, Span.From, List);
               end if;

               Item :=
                 (Kind       => Simple,
                  From       => Span.From,
                  To         => Span.To,
                  Annotation => Span.Annotation,
                  Text       => Span.Text);

               Markup.Append (Item);  --  Store begin markup

               Item.From := Span.To;
               Forward (Item.To, 1);

               Markup.Append (Item);  --  Store end markup

               Cursor.Set_At (Span.To);
               Ignore := Cursor.Forward;

               Scanner.Reset (After_Space => False);

            else

               Find_Delimiters
                 (Scanner, Text, Cursor, Text.After_Last_Character, List);

               Cursor.Set_After_Last (Text);
            end if;
         end;
      end loop;

      --  Extract links/images from delimiters' List into Markup
      Process_Links (Text, Self.Extension.Link_Attributes, Markup, List);
      --  Extract emphasis from delimiters' List into Markup
      Process_Emphasis (Markup, List);

      --  Convert Markup pairs into Result
      return To_Annotated_Text (Text.At_First_Character, Markup);

   end Parse;

   ----------------------
   -- Parse_Link_Ahead --
   ----------------------

   procedure Parse_Link_Ahead
     (Text      : VSS.Strings.Virtual_String;
      With_Attr : Boolean;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      Close     : Positive;
      URL       : out VSS.Strings.Virtual_String;
      Title     : out VSS.Strings.Virtual_String;
      Attr      : out Markdown.Attribute_Lists.Attribute_List;
      Ok        : out Boolean)
   is
      procedure To_Inline_Link
        (From  : VSS.Strings.Cursors.Markers.Character_Marker;
         To    : in out VSS.Strings.Cursors.Markers.Character_Marker;
         Ok    : out Boolean);

      --------------------
      -- To_Inline_Link --
      --------------------

      procedure To_Inline_Link
        (From  : VSS.Strings.Cursors.Markers.Character_Marker;
         To    : in out VSS.Strings.Cursors.Markers.Character_Marker;
         Ok    : out Boolean)
      is
         Last  : VSS.Strings.Cursors.Markers.Character_Marker;
         Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
           Link_Start.Match (Text, From);
      begin
         if not Match.Has_Match then
            Ok := False;  --  No ']('!
            return;
         end if;

         Parse_Link_Destination (Text, Match.Last_Marker, Last, URL, Ok);

         if Ok then
            Forward (Last, 1);  --  Skip last char of destination
         else  --  no link destination
            Last := From;
            Forward (Last, 2);  --  Skip `](`
         end if;

         declare
            Match : constant VSS.Regular_Expressions.Regular_Expression_Match
              := Link_Title.Match (Text, Last);
         begin
            Ok := Match.Has_Match;

            if Ok then
               if Match.Has_Capture (1) then
                  Title := Match.Captured (1);
                  --  Drop first and last characters (such as `'` or `"`).
                  Title := Title.Head_Before (Title.At_Last_Character);
                  Title := Title.Tail_After (Title.At_First_Character);
               end if;

               To := Match.Last_Marker;
               Forward (To, 1);  --  Skip `)`
            end if;
         end;

         if not Ok or not With_Attr then
            return;
         end if;

         declare
            Match : constant VSS.Regular_Expressions.Regular_Expression_Match
              := Attributes.Match (Text, Last);
         begin
            if Match.Has_Match then
               Attr.Parse (Match.Captured (1));
               To := Match.Last_Marker;
               Forward (To, 1);  --  Skip `}`
            end if;
         end;
      end To_Inline_Link;

   begin
      To_Inline_Link (Delimiter (Close).From, Delimiter (Close).To, Ok);
   end Parse_Link_Ahead;

   ----------------------------
   -- Parse_Link_Destination --
   ----------------------------

   procedure Parse_Link_Destination
     (Text : VSS.Strings.Virtual_String;
      From : VSS.Strings.Cursors.Markers.Character_Marker;
      Last : out VSS.Strings.Cursors.Markers.Character_Marker;
      URL  : out VSS.Strings.Virtual_String;
      Ok   : out Boolean)
   is
      use all type VSS.Characters.Virtual_Character;

      function Undo_Escape
        (X : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String
          is (X);  -- TO BE DONE

      Cursor : VSS.Strings.Character_Iterators.Character_Iterator;

   begin
      Cursor.Set_At (From);

      if not Cursor.Has_Element then
         Ok := False;
         return;

      elsif Cursor.Element = '<' then
         declare
            Match : constant VSS.Regular_Expressions.Regular_Expression_Match
              := Link_Destination.Match (Text, From);
         begin
            Ok := Match.Has_Match;

            if Ok then
               URL := Undo_Escape (Match.Captured (1));
               Last := Match.Last_Marker;
            end if;

            return;
         end;
      end if;

      declare
         Ignore    : Boolean;
         Is_Escape : Boolean := False;
         Count     : Natural := 0;  --  Count of unmatched '('
         Stop      : VSS.Strings.Cursors.Markers.Character_Marker;
         --  First unbalanced parentheses
      begin

         while Cursor.Has_Element loop
            declare
               Char : constant VSS.Characters.Virtual_Character :=
                 Cursor.Element;
            begin
               if Is_Escape then
                  Is_Escape := False;
               elsif Char = '\' then
                  Is_Escape := True;
               elsif Char <= ' ' then
                  exit;
               elsif Char = '(' then
                  if Count = 0 then
                     Stop := Cursor.Marker;
                  end if;

                  Count := Count + 1;
               elsif Char = ')' then
                  if Count = 0 then
                     exit;
                  else
                     Count := Count - 1;
                  end if;
               end if;

               Implementation.Forward (Cursor);
            end;
         end loop;

         if Count > 0 then
            Cursor.Set_At (Stop);
            Ignore := Cursor.Backward;
         elsif Is_Escape then
            Ignore := Cursor.Backward;
            Ignore := Cursor.Backward;
         else
            Ignore := Cursor.Backward;
         end if;

         URL := Undo_Escape (Text.Slice (From, Cursor));
         Last := Cursor.Marker;
         Ok := not URL.Is_Empty;
      end;
   end Parse_Link_Destination;

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

   -------------------
   -- Process_Links --
   -------------------

   procedure Process_Links
     (Text      : VSS.Strings.Virtual_String;
      With_Attr : Boolean;
      Markup    : in out Markup_Vectors.Vector;
      Delimiter : in out Emphasis_Delimiters.Delimiter_Vectors.Vector;
      Bottom    : Natural := 1)
   is
      use all type Markdown.Emphasis_Delimiters.Delimiter_Filter_Kind;
   begin
      for J in Markdown.Emphasis_Delimiters.Each
        (Delimiter, Filter => (Kind_Of, ']'))
      loop
         declare

            Closer_Index : constant Positive :=
              Emphasis_Delimiters.Delimiter_Vectors.To_Index (J);

            Closer : Markdown.Emphasis_Delimiters.Delimiter renames
              Delimiter (J);
         begin
            for K in reverse Markdown.Emphasis_Delimiters.Each
              (Delimiter,
               Filter => (Kind => Emphasis_Delimiters.Link_Or_Image),
               From   => Bottom,
               To     => Closer_Index - 1)
            loop
               declare

                  Opener_Index : constant Positive :=
                    Emphasis_Delimiters.Delimiter_Vectors.To_Index (K);

                  Opener : Markdown.Emphasis_Delimiters.Delimiter renames
                    Delimiter (K);

                  URL   : VSS.Strings.Virtual_String;
                  Title : VSS.Strings.Virtual_String;
                  Attr  : Markdown.Attribute_Lists.Attribute_List;
                  Ok    : Boolean;
               begin
                  Parse_Link_Ahead
                    (Text,
                     With_Attr,
                     Delimiter,
                     --  Opener_Index,
                     Closer_Index,
                     URL,
                     Title,
                     Attr,
                     Ok);

                  if Ok then
                     declare
                        Kind : constant Link_Or_Image :=
                          (case Opener.Kind is
                              when '!' => Image,
                              when others => Link);
                        First : Parsers.Markup :=
                          (Kind, Opener.From, Opener.From,
                           URL, Title.Split_Lines, Attr);
                        Last  : constant Parsers.Markup :=
                          (Kind, Closer.From, Closer.To,
                           URL, First.Title, Attribute_Lists.Empty);
                     begin
                        Forward (First.To, (if Kind = Image then 2 else 1));

                        Markup.Append (First);
                        Markup.Append (Last);

                        Process_Emphasis
                          (Markup, Delimiter, Opener_Index, Closer_Index);

                        --  Delete all delimiter before ')'
                        for M
                          in Markdown.Emphasis_Delimiters.Each
                               (Delimiter,
                                Filter => (Before, Closer.To.Character_Index),
                                From   => Opener_Index)
                        loop
                           Delimiter (M).Is_Deleted := True;
                        end loop;

                        if Kind = Image then
                           Opener.Is_Deleted := True;
                        else
                           for M in Markdown.Emphasis_Delimiters.Each
                             (Delimiter,
                              Filter => (Kind_Of, '['),
                              From   => Bottom,
                              To     => Closer_Index - 1)
                           loop
                              Delimiter (M).Is_Deleted := True;
                           end loop;
                        end if;

                        exit;

                     end;
                  end if;
               end;
            end loop;

            Closer.Is_Deleted := True;
         end;
      end loop;
   end Process_Links;

   --------------
   -- Register --
   --------------

   procedure Register
     (Self  : in out Inline_Parser'Class;
      Value : not null Simple_Inline_Parsers.Simple_Inline_Parser_Access) is
   begin
      Self.Parsers.Append (Value);
   end Register;

   --------------------
   -- Set_Extensions --
   --------------------

   procedure Set_Extensions
     (Self  : in out Inline_Parser;
      Value : Extension_Set) is
   begin
      Self.Extension := Value;
   end Set_Extensions;

   -----------------------
   -- To_Annotated_Text --
   -----------------------

   function To_Annotated_Text
     (Start  : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Markup : Markup_Vectors.Vector)
      return Markdown.Inlines.Inline_Vector
   is
      use type VSS.Strings.Character_Index;

      Map : array
        (Positive range 1 .. Natural (Markup.Length)) of Markup_Index;

      subtype Positive_2 is Positive range 1 .. 2;

      type Inline_Array is array (Positive_2 range <>) of
        Markdown.Inlines.Inline;

      function To_Annotation
        (Item : Parsers.Markup;
         Open : Boolean) return Inline_Array;

      function Less (Left, Right : Positive) return Boolean;

      procedure Swap (Left, Right : Positive);

      function From (Index : Positive) return VSS.Strings.Character_Index;

      procedure Append_Text
        (Result : in out Markdown.Inlines.Inline_Vector;
         Text   : in out VSS.Strings.Virtual_String);
      --  Append Text to Result and search for '\n' to detect line breaks

      -----------------
      -- Append_Text --
      -----------------

      procedure Append_Text
        (Result : in out Markdown.Inlines.Inline_Vector;
         Text   : in out VSS.Strings.Virtual_String)
      is
         Cursor : VSS.Strings.Character_Iterators.Character_Iterator :=
           Text.Before_First_Character;
      begin
         if Text.Is_Empty then
            return;
         end if;

         --  Find '\n' and replace ith with soft/hard line breaks markup

         while Cursor.Forward loop
            declare
               Match : constant
                 VSS.Regular_Expressions.Regular_Expression_Match :=
                   End_Of_Line.Match (Text, Cursor);
            begin
               if not Match.Has_Match then
                  --  No '\n', append rest of the text
                  Result.Append
                    (Inline'(Markdown.Inlines.Text, Text.Tail_From (Cursor)));

                  Cursor.Set_At_Last (Text);

               elsif Match.Has_Capture (1) then
                  --  Have spaces or backslash before '\n'
                  if Match.Captured (1).Ends_With ('\')
                    or else Match.Captured (1).Ends_With ("  ")
                  then
                     --  Append "text" excluding spaces and '\' and Hard_Line
                     Result.Append
                       (Inline'
                          (Markdown.Inlines.Text,
                           Text.Slice (Cursor, Match.First_Marker (1))));

                     Result.Append
                       (Inline'(Kind => Markdown.Inlines.Hard_Line_Break));

                     Cursor.Set_At (Match.Last_Marker);

                  else
                     --  Append "text" excluding spaces
                     Result.Append
                       (Inline'
                          (Markdown.Inlines.Text,
                           Text.Slice (Cursor, Match.First_Marker (1))));

                     Result.Append
                       (Inline'(Kind => Markdown.Inlines.Soft_Line_Break));

                     Cursor.Set_At (Match.Last_Marker);

                  end if;
               elsif Match.First_Marker.Character_Index
                 - Cursor.Character_Index
                 < 2
               then
                  --  We have no text and zero or one space
                  Result.Append
                    (Inline'(Kind => Markdown.Inlines.Soft_Line_Break));

                  Cursor.Set_At (Match.Last_Marker);

               else
                  --  We have no text and two or more spaces
                  Result.Append
                    (Inline'(Kind => Markdown.Inlines.Hard_Line_Break));

                  Cursor.Set_At (Match.Last_Marker);
               end if;
            end;
         end loop;

         Text.Clear;
      end Append_Text;

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
         return From (Left) < From (Right)
           or else (From (Left) = From (Right) and Map (Left) < Map (Right));
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
        (Item : Parsers.Markup;
         Open : Boolean) return Inline_Array
      is
      begin
         case Item.Kind is
            when Emphasis =>
               if Item.To.Character_Index - Item.From.Character_Index = 1 then
                  return
                    [(if Open then (Kind => Markdown.Inlines.Start_Emphasis)
                     else (Kind => Markdown.Inlines.End_Emphasis))];
               else
                  return
                    [(if Open then (Kind => Markdown.Inlines.Start_Strong)
                     else (Kind => Markdown.Inlines.End_Strong))];
               end if;
            when Link =>
               return
                 [(if Open then
                    (Markdown.Inlines.Start_Link,
                     Item.URL,
                     Item.Title,
                     Item.Attributes)
                  else (Kind => Markdown.Inlines.End_Link))];
            when Image =>
               return
                 [(if Open then
                    (Markdown.Inlines.Start_Image,
                     Item.URL,
                     Item.Title,
                     Item.Attributes)
                  else (Kind => Markdown.Inlines.End_Image))];
            when Simple =>
               if Open then
                  case Item.Annotation.Kind is
                     when Code_Span =>
                        return [Item.Annotation];
                     when Start_Link =>
                        return
                          [Item.Annotation,
                           (Markdown.Inlines.Text, Text => Item.Text)];
                     when others =>
                        return raise Program_Error;
                  end case;
               else
                  case Item.Annotation.Kind is
                     when Code_Span =>
                        return [];
                     when Start_Link =>
                        return [(Kind => End_Link)];
                     when others =>
                        return raise Program_Error;
                  end case;
               end if;
         end case;
      end To_Annotation;

      procedure Sort is new Ada.Containers.Generic_Anonymous_Array_Sort
        (Index_Type => Positive,
         Less       => Less,
         Swap       => Swap);

      Index  : Positive := Map'First;
      Cursor : VSS.Strings.Character_Iterators.Character_Iterator;
      Text   : VSS.Strings.Virtual_String;
   begin
      Cursor.Set_At (Start);

      for J in Map'Range loop
         Map (J) := Markup_Index (J);
      end loop;

      Sort (1, Map'Last);

      return Result : Markdown.Inlines.Inline_Vector do

         --  Fill Result
         while Cursor.Has_Element loop
            if Index in Map'Range and then
              From (Index) = Cursor.Character_Index
            then
               Append_Text (Result, Text);

               declare
                  Item : Parsers.Markup renames Markup (Map (Index));
               begin
                  for Each of
                    To_Annotation (Item, Open => Map (Index) mod 2 = 1)
                  loop
                     Result.Append (Each);
                  end loop;

                  Cursor.Set_At (Item.To);
                  Index := Index + 1;

               end;
            else
               Text.Append (Cursor.Element);
               Markdown.Implementation.Forward (Cursor);
               --  Read_Character (Cursor, Text);
            end if;
         end loop;

         Append_Text (Result, Text);
      end return;
   end To_Annotated_Text;

   -----------------
   -- To_Emphasis --
   -----------------

   function To_Emphasis
     (From   : VSS.Strings.Cursors.Markers.Character_Marker;
      Offset : VSS.Strings.Character_Count;
      Count  : VSS.Strings.Character_Index) return Markup is
   begin
      return Result : Markup (Emphasis) do
         Result.From := From;
         Forward (Result.From, Offset);
         Result.To := Result.From;
         Forward (Result.To, Count);
      end return;
   end To_Emphasis;

end Markdown.Inlines.Parsers;
