--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Regular_Expressions;

package body Markdown.Implementation.Indented_Code_Blocks is

   Blank_3 : VSS.Regular_Expressions.Regular_Expression;
   --  Zero to 3 whites-paces

   Four_Spaces : VSS.Regular_Expressions.Regular_Expression;
   --  4 white-spaces

   function Skip_Four_Spaces (Text : VSS.Strings.Virtual_String)
     return VSS.Strings.Virtual_String;
   --  Skip first 4 spaces and return rest of text

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

      Match : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      if not Blank_3.Is_Valid then
         Blank_3 := VSS.Regular_Expressions.To_Regular_Expression
           (" ?|  |   ");  --  XXX: Replace with " {0,3}"
      end if;

      if Input.Line.Expanded.Starts_With ("    ") then
         Ok := True;
         Self.Lines.Append (Skip_Four_Spaces (Input.Line.Expanded));
      elsif Blank_3.Match (Input.Line.Expanded, Anchored_Match).Has_Match then
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
     (Input : not null access Input_Position) return Indented_Code_Block
   is
   begin
      pragma Assert (Input.Line.Expanded.Starts_With ("    "));

      return Result : Indented_Code_Block do
         Result.Lines.Append (Skip_Four_Spaces (Input.Line.Expanded));
         --  Shift Input.First to end-of-line
         while Input.First.Forward loop
            null;
         end loop;
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
      if Input.Line.Expanded.Starts_With ("    ") then
         Tag := Indented_Code_Block'Tag;
         CIP := False;
      end if;
   end Detector;

   ------------------
   -- Skip_Four_Spaces --
   ------------------

   function Skip_Four_Spaces (Text : VSS.Strings.Virtual_String)
     return VSS.Strings.Virtual_String
   is
      Match : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      if not Four_Spaces.Is_Valid then
         Four_Spaces := VSS.Regular_Expressions.To_Regular_Expression ("    ");
      end if;
      Match := Four_Spaces.Match (Text);

      return Text.Tail_After (Match.Last_Marker);
   end Skip_Four_Spaces;

   ----------
   -- Text --
   ----------

   function Text
     (Self : Indented_Code_Block)
      return VSS.String_Vectors.Virtual_String_Vector is
   begin
      return Self.Lines;
   end Text;

end Markdown.Implementation.Indented_Code_Blocks;
