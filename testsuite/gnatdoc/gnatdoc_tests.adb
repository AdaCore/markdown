--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  This program accepts Markdown on stdin and prints HTML on stdout.
--  It uses gnatdoc specific blocks parsers.

with Ada.Wide_Wide_Text_IO;

with VSS.Strings;

with Markdown.Documents;
with Markdown.Parsers;
with Markdown.Parsers.GNATdoc_Enable;

with HTML_Writers;
with Prints;

procedure GNATdoc_Tests is
   Writer : HTML_Writers.Writer;
   Parser : Markdown.Parsers.Markdown_Parser;
begin
   Markdown.Parsers.GNATdoc_Enable (Parser);

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
      Prints.Print_Blocks (Writer, Document);
   end;
end GNATdoc_Tests;