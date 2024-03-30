--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Markdown HTML block elements

with VSS.String_Vectors;
private with Markdown.Implementation.HTML_Blocks;

package Markdown.Blocks.HTML is
   pragma Preelaborate;

   type HTML_Block is tagged private;
   --  An HTML block is a group of lines that is treated as raw HTML (and will
   --  not be escaped in HTML output).

   function Text (Self : HTML_Block'Class)
     return VSS.String_Vectors.Virtual_String_Vector;
   --  Return nested HTML lines

   function To_Block (Self : HTML_Block) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block)
     return HTML_Block;
   --  Convert the Block to HTML_Block

private

   type HTML_Block_Access is access all
     Markdown.Implementation.HTML_Blocks.HTML_Block'Class;

   type HTML_Block is new Ada.Finalization.Controlled with record
      Data : HTML_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out HTML_Block);
   overriding procedure Finalize (Self : in out HTML_Block);

   function Text (Self : HTML_Block'Class)
     return VSS.String_Vectors.Virtual_String_Vector is
       (Self.Data.Text);

end Markdown.Blocks.HTML;
