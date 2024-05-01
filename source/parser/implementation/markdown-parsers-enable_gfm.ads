--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

procedure Markdown.Parsers.Enable_GFM (Self : in out Markdown_Parser'Class);
--  Register GitHub Flavored Markdown specific block handlers
pragma Preelaborate (Markdown.Parsers.Enable_GFM);
