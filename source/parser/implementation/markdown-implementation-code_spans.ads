--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Simple parser for code spans

with Markdown.Simple_Inline_Parsers;

package Markdown.Implementation.Code_Spans is
   pragma Preelaborate;

   procedure Parse_Code_Span
     (Text : VSS.Strings.Virtual_String;
      From : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Span : out Markdown.Simple_Inline_Parsers.Inline_Span);
   --  Find next code span in Text staring From given position. Return
   --  `Is_Set => False` if not found.

end Markdown.Implementation.Code_Spans;
