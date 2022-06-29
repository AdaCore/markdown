--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Regular_Expressions;

package body Markdown.Implementation.Indented_Code_Blocks is

   Indent_4 : VSS.Regular_Expressions.Regular_Expression;
   --  4 spaces at the beginning of a string: "^ {4}"

   Blank_3 : VSS.Regular_Expressions.Regular_Expression;
   --  Zero to 3 whites-paces: " {0,3}"

   -----------------
   -- Append_Line --
   -----------------

   overriding procedure Append_Line
     (Self  : in out Indented_Code_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean)
   is
      pragma Unreferenced (CIP);

      Anchored_Match : constant VSS.Regular_Expressions.Match_Options :=
        (VSS.Regular_Expressions.Anchored_Match => True);

      Cursor  : VSS.Strings.Character_Iterators.Character_Iterator;
   begin
      if Indent_4.Match (Input.Line.Expanded, Input.First).Has_Match then
         Ok := True;
         Cursor.Set_At (Input.First);
         Forward (Cursor, 4);
         Self.Lines.Append (Input.Line.Unexpanded_Tail (Cursor));
      elsif Blank_3.Match
        (Input.Line.Expanded, Input.First, Anchored_Match).Has_Match
      then
         Ok := True;
         Self.Lines.Append (VSS.Strings.Empty_Virtual_String);
      else
         Ok := False;
      end if;
   end Append_Line;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Indented_Code_Block is
   begin
      return Result : Indented_Code_Block do
         Forward (Input.First, 4);
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
      CIP   : out Can_Interrupt_Paragraph) is
   begin
      if not Blank_3.Is_Valid then  --  Construct Blank_3 regexp
         Blank_3 := VSS.Regular_Expressions.To_Regular_Expression
           ("   |  | |");  --  XXX: Replace with " {0,3}"
      end if;

      if not Indent_4.Is_Valid then  --  Construct Indent_4 regexp
         Indent_4 := VSS.Regular_Expressions.To_Regular_Expression
           ("^    ");  --  XXX: Replace with "^ {4}"
      end if;

      if Indent_4.Match (Input.Line.Expanded, Input.First).Has_Match then
         Tag := Indented_Code_Block'Tag;
         CIP := False;
      end if;
   end Detector;

   ----------
   -- Text --
   ----------

   function Text
     (Self : Indented_Code_Block)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      First : Natural;
      Last  : Natural;
   begin
      for J in 1 .. Self.Lines.Length loop
         First := J;

         exit when not Self.Lines (J).Is_Empty;
      end loop;

      for J in reverse 1 .. Self.Lines.Length loop
         Last := J;

         exit when not Self.Lines (J).Is_Empty;
      end loop;

      if First = 1 and Last = Self.Lines.Length then
         return Self.Lines;
      else
         --  Drop leading and trailing empty lines
         return Result : VSS.String_Vectors.Virtual_String_Vector do
            for J in First .. Last loop
               Result.Append (Self.Lines (J));
            end loop;
         end return;
      end if;
   end Text;

end Markdown.Implementation.Indented_Code_Blocks;
