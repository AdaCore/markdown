--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with Markdown.Annotations;
with Markdown.Block_Containers;
with Markdown.Blocks;
with Markdown.Blocks.Lists;

with HTML_Writers;

package Prints is

   procedure Print_Block
     (Writer : in out HTML_Writers.Writer;
      Block  : Markdown.Blocks.Block);

   procedure Print_List
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Blocks.Lists.List);

   procedure Print_Blocks
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Block_Containers.Block_Container'Class);

   procedure Print_Annotated_Text
     (Writer : in out HTML_Writers.Writer;
      Text   : Markdown.Annotations.Annotated_Text);

end Prints;
