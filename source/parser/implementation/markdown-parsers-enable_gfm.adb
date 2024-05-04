--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Implementation.Paragraphs;
with Markdown.Implementation.Paragraphs.Tables;

procedure Markdown.Parsers.Enable_GFM (Self : in out Markdown_Parser'Class) is
begin
   Self.Register_Common_Mark_Blocks;

   Self.Register_Block
     (Detector => Markdown.Implementation.Paragraphs.Tables.Detector'Access,
      Replace  => Markdown.Implementation.Paragraphs.Detector'Access);
end Markdown.Parsers.Enable_GFM;
