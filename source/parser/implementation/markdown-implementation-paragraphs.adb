--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Regular_Expressions;

package body Markdown.Implementation.Paragraphs is

   Cell_Pattern : constant Wide_Wide_String :=
     " *((?: *(?:[^ |\\]|\\.))*) *(\|)?";
   --  Group 1 - cell text with spaces stripped
   --  Group 2 - pipe separator if any

   Cell : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Cell_Pattern

   Delimiter_Pattern : constant Wide_Wide_String := ":?-+:?";
   --  The delimiter row consists of cells whose only content are hyphens (-),
   --  and optionally, a leading or trailing colon (:), or both

   Delimiter : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Delimiter_Pattern

   Anchored : constant VSS.Regular_Expressions.Match_Options :=
     [VSS.Regular_Expressions.Anchored_Match => True];

   procedure Split_Table_Row
     (Text  : VSS.Strings.Virtual_String;
      First : VSS.Strings.Character_Iterators.Character_Iterator;
      Cells : out VSS.String_Vectors.Virtual_String_Vector;
      Weak  : Boolean);
   --  Split Text into table cells vector according to GFM rules.
   --  If Weak = True then accept a first cell exev when it doesn't end with
   --  a pipe (|).

   function Is_Delimiter (Cell : VSS.Strings.Virtual_String) return Boolean is
     (Delimiter.Match (Cell, Anchored).Has_Match);

   function Is_Delimiter_Row
     (Cells : VSS.String_Vectors.Virtual_String_Vector) return Boolean is
       (for all Cell of Cells => Is_Delimiter (Cell));

   -----------------
   -- Append_Line --
   -----------------

   overriding procedure Append_Line
     (Self  : in out Paragraph;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean)
   is
      Cells : VSS.String_Vectors.Virtual_String_Vector;
   begin
      Ok := Input.First.Has_Element and not CIP;

      if Ok then

         if Self.Table.Column_Count > 0 then

            Split_Table_Row (Input.Line.Expanded, Input.First, Cells, True);

            if Cells.Length > Self.Table.Column_Count then
               for J in 1 .. Self.Table.Column_Count loop
                  Self.Table.Cells.Append (Cells (J));
               end loop;
            else
               Self.Table.Cells.Append (Cells);

               for J in Cells.Length + 1 .. Self.Table.Column_Count loop
                  Self.Table.Cells.Append (VSS.Strings.Empty_Virtual_String);
               end loop;
            end if;
         elsif Self.Lines.Length = 1 then
            --  Parse the table delimiter row
            Split_Table_Row (Input.Line.Expanded, Input.First, Cells, False);

            --  The header row must match the delimiter row in the number of
            --  cells. If not, a table will not be recognized:
            if Cells.Is_Empty
              or else not Is_Delimiter_Row (Cells)
              or else Self.Table.Cells.Length /= Cells.Length
            then
               Self.Table.Cells.Clear;
               Self.Lines.Append (Input.Line.Unexpanded_Tail (Input.First));
            else
               --  Turn the paragraph into table:
               Self.Table.Column_Count := Cells.Length;
               Self.Table.Cells.Append (Cells);
            end if;

         else

            Self.Lines.Append (Input.Line.Unexpanded_Tail (Input.First));
         end if;
      end if;
   end Append_Line;

   ----------------------
   -- Complete_Parsing --
   ----------------------

   overriding procedure Complete_Parsing
     (Self   : in out Paragraph;
      Parser : Markdown.Inline_Parsers.Inline_Parser) is
   begin
      Self.Parser := Parser'Unchecked_Access;
   end Complete_Parsing;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Paragraph
   is
   begin
      return Result : Paragraph do
         --  Keep first line as a table header:
         Split_Table_Row
           (Input.Line.Expanded, Input.First, Result.Table.Cells, False);

         Result.Lines.Append (Input.Line.Unexpanded_Tail (Input.First));
         --  Shift Input.First to end-of-line
         Input.First.Set_After_Last (Input.Line.Expanded);
      end return;
   end Create;

   --------------
   -- Detector --
   --------------

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph)
   is
   begin
      if not Cell.Is_Valid then  --  Construct regexps
         Cell := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Cell_Pattern));
         Delimiter := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Delimiter_Pattern));
      end if;

      if Input.First.Has_Element then  --  XXX: use Blank_Pattern here
         Tag := Paragraph'Tag;
         CIP := False;
      end if;
   end Detector;

   ---------------------
   -- Split_Table_Row --
   ---------------------

   procedure Split_Table_Row
     (Text  : VSS.Strings.Virtual_String;
      First : VSS.Strings.Character_Iterators.Character_Iterator;
      Cells : out VSS.String_Vectors.Virtual_String_Vector;
      Weak  : Boolean)
   is
      Next : VSS.Strings.Character_Iterators.Character_Iterator;
      Skip : Boolean := True;
   begin
      Next.Set_At (First);

      loop
         declare
            Match : constant VSS.Regular_Expressions.Regular_Expression_Match
              := Cell.Match (Text, Next);
         begin
            if Match.Has_Match and then not Match.Captured.Is_Empty then

               if not Weak and Skip and not Match.Has_Capture (2) then
                  null;  --  Ignore the very first cell if there is no pipe |
               elsif Skip and then Match.Captured (1).Is_Empty then
                  null;  --  Ignore the very first empty cell
               else
                  Cells.Append (Match.Captured (1));
               end if;

               exit when not Match.Has_Capture (2);

               Next.Set_At (Match.Last_Marker);
               Forward (Next);
               Skip := False;
            else

               exit;
            end if;
         end;
      end loop;
   end Split_Table_Row;

   ----------------------------
   -- Table_Column_Alignment --
   ----------------------------

   function Table_Column_Alignment
     (Self : Paragraph'Class; Column : Positive) return Natural
   is
      Text : constant VSS.Strings.Virtual_String := Self.Table.Cells
        (Self.Table.Column_Count + Column);
   begin
      if Text.Starts_With (":") then
         return (if Text.Ends_With (":") then 3 else 1);
      elsif Text.Ends_With (":") then
         return 2;
      else
         return 0;
      end if;
   end Table_Column_Alignment;

end Markdown.Implementation.Paragraphs;
