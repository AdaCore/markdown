--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Markdown table block elements (GitHub Flavored Markdown extension).

with Markdown.Inlines;
private with Markdown.Implementation.Paragraphs;

package Markdown.Blocks.Tables is
   pragma Preelaborate;

   type Table is tagged private;
   --  GFM enables the table extension, where an additional leaf block type is
   --  available.
   --
   --  A table is an arrangement of data with rows and columns, consisting of
   --  a single header row, a delimiter row separating the header from the
   --  data, and zero or more data rows.

   function Rows (Self : Table) return Natural;
   function Columns (Self : Table) return Positive;

   function Header (Self : Table; Column : Positive)
     return Markdown.Inlines.Inline_Vector;
   --  Return annotated text nested in a header column

   function Cell (Self : Table; Row, Column : Positive)
     return Markdown.Inlines.Inline_Vector;
   --  Return annotated text nested in a cell

   type Column_Alignment is (Undefined, Left, Right, Center);

   function Alignment
     (Self : Table; Column : Positive) return Column_Alignment;

   function To_Block (Self : Table) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block) return Table;
   --  Convert the Block to Table

private

   type Paragraph_Access is access all
     Markdown.Implementation.Paragraphs.Paragraph'Class;

   type Table is new Ada.Finalization.Controlled with record
      Data : Paragraph_Access;
   end record;

   overriding procedure Adjust (Self : in out Table);
   overriding procedure Finalize (Self : in out Table);

end Markdown.Blocks.Tables;
