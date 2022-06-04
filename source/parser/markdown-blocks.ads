--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Blocks of markdown. Blocks of some kinds could contain nested blocks.

private with Ada.Finalization;

private with Markdown.Implementation;

limited with Markdown.Blocks.Paragraphs;

package Markdown.Blocks is
   pragma Preelaborate;

   type Block is tagged private;
   --  Block element of a markdown document

   function Is_Paragraph (Self : Block) return Boolean;
   --  Check if given block is a paragraph

   function To_Paragraph (Self : Block)
     return Markdown.Blocks.Paragraphs.Paragraph
        with Pre => Self.Is_Paragraph;
   --  Convert the block to a Paragraph

private

   type Block is new Ada.Finalization.Controlled with record
      Data : Markdown.Implementation.Abstract_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out Block);
   overriding procedure Finalize (Self : in out Block);

end Markdown.Blocks;
