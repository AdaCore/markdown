--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal representation of a markdown paragraph

with VSS.String_Vectors;

with Markdown.Inlines;

package Markdown.Implementation.Paragraphs.Tables is
   pragma Preelaborate;

   type Paragraph is new Paragraphs.Paragraph with private;
   --  Paragraph block contains annotated inline content

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a paragraph

   overriding function Table_Columns (Self : Paragraph) return Natural;
   overriding function Table_Rows (Self : Paragraph) return Natural;

   overriding function Table_Cell
     (Self   : Paragraph;
      Row    : Positive;
      Column : Positive) return Markdown.Inlines.Annotated_Text;

   overriding function Table_Column_Alignment
     (Self : Paragraph; Column : Positive) return Natural;
   --  return 0 for undefined alignment, 1, 2, 3 for left, right and center

private

   type Paragraph is new Paragraphs.Paragraph with record
      Column_Count : Natural := 0;
      Cells        : VSS.String_Vectors.Virtual_String_Vector;
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
      Parser : Markdown.Inlines.Inline_Parsers.Inline_Parser);

   overriding function Table_Columns (Self : Paragraph) return Natural is
      (Self.Column_Count);

   overriding function Table_Rows (Self : Paragraph) return Natural is
     (if Self.Column_Count > 0
      then Self.Cells.Length / Self.Column_Count
      else 0);

   overriding function Table_Cell
     (Self   : Paragraph;
      Row    : Positive;
      Column : Positive) return Markdown.Inlines.Annotated_Text is
        (Self.Parser.Parse
          (Self.Cells ((Row - 1) * Self.Column_Count + Column)));

end Markdown.Implementation.Paragraphs.Tables;
