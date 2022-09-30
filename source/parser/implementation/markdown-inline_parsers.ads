--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal parser to process links, emphasis, code spans and other inline
--  items.

with VSS.String_Vectors;

with Markdown.Annotations;
private with Markdown.Emphasis_Delimiters;

package Markdown.Inline_Parsers is
   pragma Preelaborate;

   type Inline_Parser is tagged limited private;

   function Parse
     (Self  : Inline_Parser;
      Lines : VSS.String_Vectors.Virtual_String_Vector)
     return Markdown.Annotations.Annotated_Text;

private

   type Inline_Parser is tagged limited record
      Scanner : Markdown.Emphasis_Delimiters.Scanner;
   end record;

end Markdown.Inline_Parsers;
