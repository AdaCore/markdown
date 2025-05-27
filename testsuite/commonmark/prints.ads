--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Inlines;
with Markdown.Block_Containers;
with Markdown.Blocks;
with Markdown.Blocks.Lists;

with HTML_Writers;

package Prints is

   procedure Print_Block
     (Writer   : in out HTML_Writers.Writer;
      Block    : Markdown.Blocks.Block;
      Is_Tight : Boolean);

   procedure Print_List
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Blocks.Lists.List);

   procedure Print_Blocks
     (Writer   : in out HTML_Writers.Writer;
      List     : Markdown.Block_Containers.Block_Container'Class;
      Is_Tight : Boolean);

   procedure Print_Annotated_Text
     (Writer : in out HTML_Writers.Writer;
      Text   : Markdown.Inlines.Annotated_Text);

end Prints;
