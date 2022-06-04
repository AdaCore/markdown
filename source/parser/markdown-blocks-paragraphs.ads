--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Markdown paragraph block elements

with Markdown.Annotations;
private with Markdown.Implementation.Paragraphs;

package Markdown.Blocks.Paragraphs is
   pragma Preelaborate;

   type Paragraph is tagged private;
   --  Paragraph block contains annotated inline content

   function Text (Self : Paragraph)
     return Markdown.Annotations.Annotated_Text;
   --  Return nested annotated text

   function To_Block (Self : Paragraph) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block) return Paragraph;
   --  Convert the Block to Paragraph

private

   type Paragraph_Access is access all
     Markdown.Implementation.Paragraphs.Paragraph;

   type Paragraph is new Ada.Finalization.Controlled with record
      Data : Paragraph_Access;
   end record;

   overriding procedure Adjust (Self : in out Paragraph);
   overriding procedure Finalize (Self : in out Paragraph);

end Markdown.Blocks.Paragraphs;
