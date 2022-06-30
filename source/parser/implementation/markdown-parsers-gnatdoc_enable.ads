--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

procedure Markdown.Parsers.GNATdoc_Enable
  (Self : in out Markdown_Parser'Class);
--  Register gnatdoc specific block handlers
pragma Preelaborate (Markdown.Parsers.GNATdoc_Enable);