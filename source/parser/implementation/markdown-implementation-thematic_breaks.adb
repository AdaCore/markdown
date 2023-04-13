--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Regular_Expressions;

package body Markdown.Implementation.Thematic_Breaks is

   Break_Pattern : constant Wide_Wide_String :=
     "^(?:   |  | |)(?:" &
     "(?:- *- *(?:- *)+)|" &
     "(?:_ *_ *(?:_ *)+)|" &
     "(?:\* *\* *(?:\* *)+))$";

   Break : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Break_Pattern

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Thematic_Break
   is
   begin
      return Result : Thematic_Break do
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
      Match  : VSS.Regular_Expressions.Regular_Expression_Match;

   begin
      if not Break.Is_Valid then  --  Construct Break regexp
         Break := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Break_Pattern));
      end if;

      CIP := True;  --  Suppress a warning about uninitialized parameter
      Match := Break.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match then
         Tag := Thematic_Break'Tag;
      end if;
   end Detector;

end Markdown.Implementation.Thematic_Breaks;
