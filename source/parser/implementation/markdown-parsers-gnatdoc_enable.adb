--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Implementation.Code_Spans;
with Markdown.Implementation.Indented_Code_Blocks.GNATdoc;
with Markdown.Implementation.List_Items;
with Markdown.Implementation.Paragraphs;

procedure Markdown.Parsers.GNATdoc_Enable
  (Self : in out Markdown_Parser'Class) is
begin
   Self.Register_Block
     (Markdown.Implementation.Indented_Code_Blocks.GNATdoc.Detector'Access);

   Self.Register_Block (Markdown.Implementation.List_Items.Detector'Access);
   Self.Register_Block (Markdown.Implementation.Paragraphs.Detector'Access);

   Self.Inline_Parser.Register
     (Markdown.Implementation.Code_Spans.Parse_Code_Span'Access);
end Markdown.Parsers.GNATdoc_Enable;
