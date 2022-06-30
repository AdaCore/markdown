--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Strings.Cursors;

package body Markdown.Implementation.Indented_Code_Blocks is

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

      use type VSS.Strings.Character_Count;

      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Indent.Match (Input.Line.Expanded, Input.First);

      Cursor  : VSS.Strings.Character_Iterators.Character_Iterator;
   begin
      if Match.Has_Match and then
        Match.Marker.Character_Length >= Self.Indent
      then
         Ok := True;
         Cursor.Set_At (Input.First);
         Forward (Cursor, 4);
         Self.Lines.Append (Input.Line.Unexpanded_Tail (Cursor));
      elsif not Input.First.Has_Element
        or else
          (Match.Has_Match and then
            VSS.Strings.Cursors.Abstract_Segment_Cursor'Class
              (Match.Marker).Last_Character_Index
                = Input.Line.Expanded.Character_Length)
      then
         --  Line is empty or contains only spaces and shorten then indent (4)
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
      CIP   : out Can_Interrupt_Paragraph)
   is
      use type VSS.Strings.Character_Count;

      Match : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      if not Indent.Is_Valid then  --  Construct Indent regexp
         Indent := VSS.Regular_Expressions.To_Regular_Expression
           ("^  *");  --  XXX: Replace with "^ +"
      end if;

      Match := Indent.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match and then Match.Marker.Character_Length >= 4 then
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
