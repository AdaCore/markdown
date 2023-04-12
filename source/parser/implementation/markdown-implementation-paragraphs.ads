--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal representation of a markdown paragraph

with VSS.String_Vectors;

with Markdown.Annotations;

package Markdown.Implementation.Paragraphs is
   pragma Preelaborate;

   type Paragraph is new Abstract_Block with private;
   --  Paragraph block contains annotated inline content

   function Text (Self : Paragraph)
     return Markdown.Annotations.Annotated_Text;
   --  Return nested annotated text

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a paragraph

private

   type Paragraph is new Abstract_Block with record
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
      Parser : access constant Markdown.Inline_Parsers.Inline_Parser;
   end record;

   overriding function Create
     (Input : not null access Input_Position) return Paragraph;

   overriding procedure Append_Line
     (Self  : in out Paragraph;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean);

   overriding procedure Complete_Parsing
     (Self   : in out Paragraph;
      Parser : Markdown.Inline_Parsers.Inline_Parser);

   function Text (Self : Paragraph)
     return Markdown.Annotations.Annotated_Text is
       (Self.Parser.Parse (Self.Lines));

end Markdown.Implementation.Paragraphs;
