--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Implementation.Indented_Code_Blocks.GNATdoc is

   overriding function Create
     (Input : not null access Input_Position) return GNATdoc_Code_Block
   is
      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Indent.Match (Input.Line.Expanded, Input.First);
   begin
      return Result : GNATdoc_Code_Block do
         Result.Indent := Match.Marker.Character_Length;
         Forward (Input.First, Result.Indent);
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

      if Match.Has_Match and then Match.Marker.Character_Length >= 3 then
         Tag := GNATdoc_Code_Block'Tag;
         CIP := False;
      end if;
   end Detector;

end Markdown.Implementation.Indented_Code_Blocks.GNATdoc;
