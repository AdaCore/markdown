--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  This program accepts Markdown on stdin and prints HTML on stdout.
--  See https://github.com/commonmark/commonmark-spec for more details.

with Ada.Wide_Wide_Text_IO;

with VSS.Strings;

with Markdown.Annotations;
with Markdown.Block_Containers;
with Markdown.Blocks;
with Markdown.Blocks.Paragraphs;
with Markdown.Documents;
with Markdown.Parsers;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Cursors.Markers;

with HTML_Writers;

procedure Commonmark_Tests is
   pragma Assertion_Policy (Check);

   procedure Print_Block
     (Writer : in out HTML_Writers.Writer;
      Block  : Markdown.Blocks.Block);

   procedure Print_Blocks
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Block_Containers.Block_Container'Class);

   procedure Print_Annotated_Text
     (Writer : in out HTML_Writers.Writer;
      Text   : Markdown.Annotations.Annotated_Text);

   procedure Print_Annotated_Text
     (Writer : in out HTML_Writers.Writer;
      Text   : Markdown.Annotations.Annotated_Text)
   is
      use type VSS.Strings.Character_Count;

      procedure Print
        (From  : in out Positive;
         Next  : in out VSS.Strings.Cursors.Markers.Character_Marker;
         Limit : VSS.Strings.Character_Iterators.Character_Iterator);
      --  From is an index in Text.Annotation to start from
      --  Next is a not printed yet character in Text.Plain_Text
      --  Dont go after Limit position in Text.Plain_Text

      function "<="
        (Segment  : VSS.Strings.Cursors.Markers.Segment_Marker;
         Position : VSS.Strings.Character_Iterators.Character_Iterator)
         return Boolean
      is
        (VSS.Strings.Cursors.Abstract_Cursor'Class (Segment).
           Last_Character_Index <= Position.Character_Index);
      --  Check if Segment ends before Position

      -----------
      -- Print --
      -----------

      procedure Print
        (From  : in out Positive;
         Next  : in out VSS.Strings.Cursors.Markers.Character_Marker;
         Limit : VSS.Strings.Character_Iterators.Character_Iterator) is
      begin
         while From <= Text.Annotation.Last_Index and then
           Text.Annotation (From).Segment <= Limit
         loop
            --  Print annotation here
            null;
            From := From + 1;
         end loop;

         if Next.Character_Index <= Limit.Character_Index then
            Writer.Characters (Text.Plain_Text.Slice (Next, Limit));

            declare
               Iter : VSS.Strings.Character_Iterators.Character_Iterator :=
                 Text.Plain_Text.At_Character (Limit);
            begin
               if Iter.Forward then
                  Next := Iter.Marker;
               end if;
            end;
         end if;
      end Print;

      From  : Positive := Text.Annotation.First_Index;
      Next  : VSS.Strings.Cursors.Markers.Character_Marker :=
        Text.Plain_Text.At_First_Character.Marker;
   begin
      Print
        (From  => From,
         Next  => Next,
         Limit => Text.Plain_Text.At_Last_Character);
   end Print_Annotated_Text;

   -----------------
   -- Print_Block --
   -----------------

   procedure Print_Block
     (Writer : in out HTML_Writers.Writer;
      Block  : Markdown.Blocks.Block) is
   begin
      if Block.Is_Paragraph then
         Writer.Start_Element ("p");
         Print_Annotated_Text (Writer, Block.To_Paragraph.Text);
         Writer.End_Element ("p");
      else
         raise Program_Error;
      end if;
   end Print_Block;

   procedure Print_Blocks
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Block_Containers.Block_Container'Class) is
   begin
      for J in 1 .. List.Length loop
         declare
            Block : constant Markdown.Blocks.Block := List.Element (J);
         begin
            Print_Block (Writer, Block);
         end;
      end loop;
   end Print_Blocks;

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
      Print_Blocks (Writer, Document);
      --  Writer.End_Element ("html");
   end;
end Commonmark_Tests;
