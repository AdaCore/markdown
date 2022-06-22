--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Implementation.Paragraphs is

   -----------------
   -- Append_Line --
   -----------------

   overriding procedure Append_Line
     (Self  : in out Paragraph;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean)
   is
   begin
      Ok := Input.First.Has_Element and not CIP;

      if Ok then
         Self.Lines.Append (Input.Line.Unexpanded_Tail (Input.First));
      end if;
   end Append_Line;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Paragraph
   is
   begin
      return Result : Paragraph do
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
      if Input.First.Has_Element then  --  XXX: use Blank_Pattern here
         Tag := Paragraph'Tag;
         CIP := False;
      end if;
   end Detector;

   ----------
   -- Text --
   ----------

   function Text (Self : Paragraph)
     return Markdown.Annotations.Annotated_Text
   is
      First : Boolean := True;
   begin
      return Result : Markdown.Annotations.Annotated_Text do
         for Line of Self.Lines loop
            if First then
               First := False;
            else
               Result.Plain_Text.Append (' ');
            end if;

            Result.Plain_Text.Append (Line);
         end loop;
      end return;
   end Text;

end Markdown.Implementation.Paragraphs;
