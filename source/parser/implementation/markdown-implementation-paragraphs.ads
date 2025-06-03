--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal representation of a markdown paragraph

with VSS.String_Vectors;

with Markdown.Inlines;

package Markdown.Implementation.Paragraphs is
   pragma Preelaborate;

   type Paragraph is new Abstract_Block with private;
   --  Paragraph block contains annotated inline content

   function Text (Self : Paragraph) return Markdown.Inlines.Inline_Vector;
   --  Return nested annotated text

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a paragraph

   function Table_Columns (Self : Paragraph) return Natural is (0);
   --  If paragraph contains a table (GFM extension) return columns count

   function Table_Rows (Self : Paragraph) return Natural is (0);
   --  If paragraph contains a table (GFM extension) return rows count

   function Table_Cell
     (Self   : Paragraph;
      Row    : Positive;
      Column : Positive) return Markdown.Inlines.Inline_Vector is
        (raise Constraint_Error);
   --  If paragraph contains a table (GFM extension) return a cell

   function Table_Column_Alignment
     (Self : Paragraph; Column : Positive) return Natural is (0);
   --  return 0 for undefined alignment, 1, 2, 3 for left, right and center

private

   type Paragraph is new Abstract_Block with record
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
      Parser :
        access constant Markdown.Inlines.Parsers.Inline_Parser;
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
      Parser : Markdown.Inlines.Parsers.Inline_Parser);

   function Text (Self : Paragraph) return Markdown.Inlines.Inline_Vector is
     (Self.Parser.Parse (Self.Lines));

end Markdown.Implementation.Paragraphs;
