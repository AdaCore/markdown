--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Blocks of markdown. Blocks of some kinds could contain nested blocks.

private with Ada.Finalization;

private with Markdown.Implementation;

limited with Markdown.Blocks.Indented_Code;
limited with Markdown.Blocks.Lists;
limited with Markdown.Blocks.Paragraphs;
limited with Markdown.Blocks.Quotes;

package Markdown.Blocks is
   pragma Preelaborate;

   type Block is tagged private;
   --  Block element of a markdown document

   function Is_Paragraph (Self : Block'Class) return Boolean;
   --  Check if given block is a paragraph

   function Is_Indented_Code_Block (Self : Block'Class) return Boolean;
   --  Check if given block is an indented code block

   function Is_List (Self : Block'Class) return Boolean;
   --  Check if given block is a list of list items

   function Is_Quote (Self : Block'Class) return Boolean;
   --  Check if given block is a block quote

   function To_Paragraph (Self : Block)
     return Markdown.Blocks.Paragraphs.Paragraph
        with Pre => Self.Is_Paragraph;
   --  Convert the block to a Paragraph

   function To_Indented_Code_Block (Self : Block)
     return Markdown.Blocks.Indented_Code.Indented_Code_Block
        with Pre => Self.Is_Indented_Code_Block;
   --  Convert the block to an indented code block

   function To_Quote (Self : Block)
     return Markdown.Blocks.Quotes.Quote
        with Pre => Self.Is_Quote;
   --  Convert the block to an indented code block

   function To_List (Self : Block) return Markdown.Blocks.Lists.List
     with Pre => Self.Is_List;
   --  Convert the block to a list

private

   type Block is new Ada.Finalization.Controlled with record
      Data : Markdown.Implementation.Abstract_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out Block);
   overriding procedure Finalize (Self : in out Block);

end Markdown.Blocks;
