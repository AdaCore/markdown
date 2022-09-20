--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal parser to process links, emphasis, code spans and other inlines

with VSS.String_Vectors;
with Markdown.Annotations;

package Markdown.Inline_Parsers is
   pragma Preelaborate;

   type Inline_Parser is tagged limited private;

   function Parse_Inlines
     (Self  : Inline_Parser;
      Lines : VSS.String_Vectors.Virtual_String_Vector)
     return Markdown.Annotations.Annotated_Text;

private

   type Inline_Parser is tagged limited record
      null;
   end record;

end Markdown.Inline_Parsers;
