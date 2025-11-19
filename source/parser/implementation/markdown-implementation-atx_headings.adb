--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Regular_Expressions;

package body Markdown.Implementation.ATX_Headings is

   Prefix_Pattern : constant Wide_Wide_String :=
     "^(?:   |  | |)(######|#####|####|###|##|#)(?: |$)";

   Suffix_Pattern : constant Wide_Wide_String := " +#* *$";

   Prefix : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Prefix_Pattern

   Suffix : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Suffix_Pattern

   ----------------------
   -- Complete_Parsing --
   ----------------------

   overriding procedure Complete_Parsing
     (Self   : in out ATX_Heading;
      Parser : Markdown.Inlines.Parsers.Inline_Parser) is
   begin
      Self.Parser := Parser'Unchecked_Access;
   end Complete_Parsing;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return ATX_Heading
   is
      Prefix_Match  : constant VSS.Regular_Expressions.Regular_Expression_Match
        := Prefix.Match (Input.Line.Expanded, Input.First);

      Suffix_Match  : constant VSS.Regular_Expressions.Regular_Expression_Match
        := Suffix.Match (Input.Line.Expanded, Input.First);

   begin
      pragma Assert (Prefix_Match.Has_Match);

      return Result : ATX_Heading do
         Result.Level := Positive (Prefix_Match.Marker (1).Character_Length);

         Input.First.Set_At (Prefix_Match.Last_Marker);

         if Suffix_Match.Has_Match then
            declare
               Last   : VSS.Strings.Character_Iterators.Character_Iterator;
               Ignore : Boolean;
            begin
               Last.Set_At (Suffix_Match.First_Marker);
               Ignore := Last.Backward;

               Result.Title := Input.Line.Unexpanded_Tail (Input.First, Last);
            end;
         else
            Result.Title := Input.Line.Unexpanded_Tail (Input.First);
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
      Match  : VSS.Regular_Expressions.Regular_Expression_Match;

   begin
      Initialize;

      CIP := True;  --  Suppress a warning about uninitialized parameter
      Match := Prefix.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match then
         Tag := ATX_Heading'Tag;
      end if;
   end Detector;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      if not Prefix.Is_Valid then  --  Construct Prefix regexp
         Prefix := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Prefix_Pattern));

         Suffix := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Suffix_Pattern));

         pragma Assert (Prefix.Is_Valid and Suffix.Is_Valid);
      end if;
   end Initialize;

end Markdown.Implementation.ATX_Headings;
