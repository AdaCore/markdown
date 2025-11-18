--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Simple parser for auto-links

with Markdown.Simple_Inline_Parsers;

package Markdown.Implementation.Auto_Links is
   pragma Preelaborate;

   procedure Parse_Auto_Link
     (Text : VSS.Strings.Virtual_String;
      From : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Span : out Markdown.Simple_Inline_Parsers.Inline_Span);
   --  Find next auto-link in Text staring From given position. Return
   --  `Is_Set => False` if not found.

   procedure Initialize;
   --  Prepare regexp patterns

end Markdown.Implementation.Auto_Links;
