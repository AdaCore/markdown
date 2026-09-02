--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body Markdown.Implementation.Fenced_Code_Blocks.GNATdoc is

   Max_Indent : constant VSS.Strings.Character_Count := 2;
   --  Maximum indentation of a code fence

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position)
      return GNATdoc_Fenced_Code_Block
   is
      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Fence.Match (Input.Line.Expanded, Input.First);
   begin
      pragma Assert (Match.Has_Match);

      return Result : GNATdoc_Fenced_Code_Block do
         Result.Max_Indent := Max_Indent;
         Result.Indent := Match.Marker (1).Character_Length;
         Result.Is_Tick_Fence := Match.Has_Capture (2);

         if Result.Is_Tick_Fence then
            Result.Fence_Length := Match.Marker (2).Character_Length;
            Result.Info_String := Match.Captured (3);
         else
            Result.Fence_Length := Match.Marker (4).Character_Length;
            Result.Info_String := Match.Captured (5);
         end if;

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
      Match : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      Fenced_Code_Blocks.Initialize;

      Match := Fence.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match
        and then Match.Marker (1).Character_Length <= Max_Indent
      then
         Tag := GNATdoc_Fenced_Code_Block'Tag;
         CIP := True;  --  A code fence can interrupt a paragraph
      end if;
   end Detector;

end Markdown.Implementation.Fenced_Code_Blocks.GNATdoc;
