--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Markdown indented code block elements

with VSS.String_Vectors;
private with Markdown.Implementation.Indented_Code_Blocks;

package Markdown.Blocks.Indented_Code is
   pragma Preelaborate;

   type Indented_Code_Block is tagged private;
   --  An indented code block is composed of one or more indented chunks
   --  separated by blank lines. An indented chunk is a sequence of non-blank
   --  lines, each indented four or more spaces. The contents of the code block
   --  are the literal contents of the lines, including trailing line endings,
   --  minus four spaces of indentation. An indented code block has no info
   --  string.

   function Text (Self : Indented_Code_Block)
     return VSS.String_Vectors.Virtual_String_Vector;
   --  Return nested code lines

   function To_Block (Self : Indented_Code_Block) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block)
     return Indented_Code_Block;
   --  Convert the Block to Indented_Code_Block

private

   type Indented_Code_Block_Access is access all
     Markdown.Implementation.Indented_Code_Blocks.Indented_Code_Block'Class;

   type Indented_Code_Block is new Ada.Finalization.Controlled with record
      Data : Indented_Code_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out Indented_Code_Block);
   overriding procedure Finalize (Self : in out Indented_Code_Block);

end Markdown.Blocks.Indented_Code;
