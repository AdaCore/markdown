--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Containers.Vectors;

with Markdown.Documents;
with VSS.Strings;
with Markdown.Implementation;
with Markdown.Inline_Parsers;

package Markdown.Parsers is
   pragma Preelaborate;

   type Markdown_Parser is tagged limited private;
   --  Markdown parser representation

   procedure Parse_Line
     (Self : in out Markdown_Parser'Class;
      Line : VSS.Strings.Virtual_String);
   --  Parse next line of Markdown text and update internal state of the parser

   function Document
     (Self : in out Markdown_Parser) return Markdown.Documents.Document;
   --  Return parsed document. After this call the Parse_Line has no effect.

private

   use Markdown.Implementation;

   package Block_Vectors is new Ada.Containers.Vectors
     (Positive, Abstract_Block_Access);

   type Abstract_Container_Block_Access is
     access all Abstract_Container_Block'Class;

   package Container_Vectors is new Ada.Containers.Vectors
     (Positive, Abstract_Container_Block_Access);

   package Block_Detector_Vectors is new Ada.Containers.Vectors
     (Positive, Block_Detector);

   type Parser_State is (Initial, Started, Completed);

   type Markdown_Parser is tagged limited record
      State    : Parser_State := Initial;
      Document : Markdown.Documents.Document;
      --  Resulting markdown document
      Open      : Container_Vectors.Vector;
      --  Current open container blocks, e.g. block-quote
      Open_Leaf : Abstract_Block_Access;
      --  Current open non-container block (if any), e.g. paragraph
      Block_Detectors  : Block_Detector_Vectors.Vector;
      --  Known block detectors
      Inline_Parser : Markdown.Inline_Parsers.Inline_Parser;
      --  Parser of inline markups (links, emphasis, code spans, etc)
   end record;

   procedure Register_Block
     (Self     : in out Markdown_Parser'Class;
      Detector : Block_Detector);
   --  Let the parser know a new block kind

   procedure Register_Block
     (Self     : in out Markdown_Parser'Class;
      Detector : Block_Detector;
      Replace  : Block_Detector);
   --  Replace registered block with new one

   procedure Register_Common_Mark_Blocks (Self : in out Markdown_Parser'Class);
   --  Register CommonMark block detectors

end Markdown.Parsers;
