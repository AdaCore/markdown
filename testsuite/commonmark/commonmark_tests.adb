--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This program accepts Markdown on stdin and prints HTML on stdout.
--  See https://github.com/commonmark/commonmark-spec for more details.

with Ada.Wide_Wide_Text_IO;

with VSS.Strings;

with Markdown.Documents;
with Markdown.Parsers;

with HTML_Writers;
with Prints;

procedure Commonmark_Tests is
   Writer : HTML_Writers.Writer;
   Parser : Markdown.Parsers.Markdown_Parser;
begin
   while not Ada.Wide_Wide_Text_IO.End_Of_File loop
      declare
         Line : constant Wide_Wide_String := Ada.Wide_Wide_Text_IO.Get_Line;
         Text : constant VSS.Strings.Virtual_String :=
           VSS.Strings.To_Virtual_String (Line);
      begin
         Parser.Parse_Line (Text);
      end;
   end loop;

   declare
      Document : constant Markdown.Documents.Document := Parser.Document;
   begin
      --  Writer.Start_Element ("html");
      Prints.Print_Blocks (Writer, Document, Is_Tight => False);
      --  Writer.End_Element ("html");
   end;
end Commonmark_Tests;
