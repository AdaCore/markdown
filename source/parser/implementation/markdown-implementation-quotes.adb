--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Regular_Expressions;

package body Markdown.Implementation.Quotes is

   Prefix_Pattern : constant Wide_Wide_String := "^(?:   |  | |)>(?: |)";

   Prefix : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Prefix_Pattern

   ----------------------------------
   -- Consume_Continuation_Markers --
   ----------------------------------

   overriding procedure Consume_Continuation_Markers
     (Self  : in out Quote;
      Input : in out Input_Position;
      Ok    : out Boolean)
   is
      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Prefix.Match (Input.Line.Expanded, Input.First);

   begin
      Ok := Match.Has_Match;

      if Ok then
         --  Skip marker and all spaces if any
         Input.First.Set_At (Match.Last_Marker);
         Forward (Input.First);
      end if;
   end Consume_Continuation_Markers;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Quote
   is
      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Prefix.Match (Input.Line.Expanded, Input.First);

   begin
      pragma Assert (Match.Has_Match);
      --  Skip marker and all spaces if any
      Input.First.Set_At (Match.Last_Marker);
      Forward (Input.First);

      return Quote'(others => <>);
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
      if not Prefix.Is_Valid then  --  Construct Prefix regexp
         Prefix := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Prefix_Pattern));
      end if;

      CIP := True;  --  Suppress a warning about uninitialized parameter
      Match := Prefix.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match then
         Tag := Quote'Tag;
      end if;
   end Detector;

end Markdown.Implementation.Quotes;
