--
--  Copyright (C) 2021-2024, AdaCore
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

   function Table_Columns (Self : Paragraph'Class) return Natural;
   function Table_Rows (Self : Paragraph'Class) return Natural;

   function Table_Cell
     (Self   : Paragraph'Class;
      Row    : Positive;
      Column : Positive) return Markdown.Annotations.Annotated_Text;

   function Table_Column_Alignment
     (Self : Paragraph'Class; Column : Positive) return Natural;
   --  return 0 for undefined alignment, 1, 2, 3 for left, right and center

private

   type Table_Properties is record
      Column_Count : Natural := 0;
      Cells        : VSS.String_Vectors.Virtual_String_Vector;
   end record;
   --  Table related information if the paragraph is actually a table

   type Paragraph is new Abstract_Block with record
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
      Table  : Table_Properties;
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

   function Table_Columns (Self : Paragraph'Class) return Natural is
      (Self.Table.Column_Count);

   function Table_Rows (Self : Paragraph'Class) return Natural is
     (if Self.Table.Column_Count > 0
      then Self.Table.Cells.Length / Self.Table.Column_Count
      else 0);

   function Table_Cell
     (Self   : Paragraph'Class;
      Row    : Positive;
      Column : Positive) return Markdown.Annotations.Annotated_Text is
        (Self.Parser.Parse
          (Self.Table.Cells ((Row - 1) * Self.Table.Column_Count + Column)));

end Markdown.Implementation.Paragraphs;
