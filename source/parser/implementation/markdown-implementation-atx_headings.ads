--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a markdown ATX_Heading

with Markdown.Annotations;

package Markdown.Implementation.ATX_Headings is
   pragma Preelaborate;

   type ATX_Heading is new Abstract_Block with private;
   --  ATX_Heading block contains annotated inline content

   function Level (Self : ATX_Heading'Class) return Positive;
   --  The heading level is equal to the number of `#` characters in the
   --  opening sequence.

   function Text (Self : ATX_Heading)
     return Markdown.Annotations.Annotated_Text;
   --  Return nested annotated text

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a ATX_Heading

private

   type ATX_Heading is new Abstract_Block with record
      Level  : Positive range 1 .. 6;
      Title  : VSS.Strings.Virtual_String;
      Parser : access constant Markdown.Inline_Parsers.Inline_Parser;
   end record;

   overriding function Create
     (Input : not null access Input_Position) return ATX_Heading;

   overriding procedure Complete_Parsing
     (Self   : in out ATX_Heading;
      Parser : Markdown.Inline_Parsers.Inline_Parser);

   function Text (Self : ATX_Heading)
     return Markdown.Annotations.Annotated_Text is
       (Self.Parser.Parse (Self.Title.Split_Lines));

   function Level (Self : ATX_Heading'Class) return Positive
     is (Self.Level);

end Markdown.Implementation.ATX_Headings;
