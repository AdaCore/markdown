--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal parser to process links, emphasis, code spans and other inline
--  items.

with VSS.String_Vectors;

with Markdown.Annotations;
with Markdown.Simple_Inline_Parsers;

--  private
private with Markdown.Emphasis_Delimiters;

package Markdown.Inline_Parsers is
   pragma Preelaborate;

   type Inline_Parser is tagged limited private;

   procedure Register
     (Self  : in out Inline_Parser'Class;
      Value : not null Simple_Inline_Parsers.Simple_Inline_Parser_Access);

   function Parse
     (Self  : Inline_Parser'Class;
      Lines : VSS.String_Vectors.Virtual_String_Vector)
     return Markdown.Annotations.Annotated_Text;

private

   type Inline_Parser is tagged limited record
      Scanner : Markdown.Emphasis_Delimiters.Scanner;
      Parsers : Markdown.Simple_Inline_Parsers.Simple_Parser_Vectors.Vector;
   end record;

end Markdown.Inline_Parsers;
