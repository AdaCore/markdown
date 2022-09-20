--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Inline_Parsers is

   -------------------
   -- Parse_Inlines --
   -------------------

   function Parse_Inlines
     (Self  : Inline_Parser;
      Lines : VSS.String_Vectors.Virtual_String_Vector)
      return Markdown.Annotations.Annotated_Text
   is
      First : Boolean := True;
   begin
      return Result : Markdown.Annotations.Annotated_Text do
         for Line of Lines loop
            if First then
               First := False;
            else
               Result.Plain_Text.Append (' ');
            end if;

            Result.Plain_Text.Append (Line);
         end loop;
      end return;
   end Parse_Inlines;

end Markdown.Inline_Parsers;
