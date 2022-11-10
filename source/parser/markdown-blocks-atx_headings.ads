--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Markdown ATX heading elements

with Markdown.Annotations;
private with Markdown.Implementation.ATX_Headings;

package Markdown.Blocks.ATX_Headings is
   pragma Preelaborate;

   type ATX_Heading is tagged private;
   --  An ATX heading consists of a string of characters, parsed as inline
   --  content, between an opening sequence of 1–6 unescaped `#` characters
   --  and an optional closing sequence of any number of non-escaped `#`
   --  characters.

   subtype Heading_Level is Positive range 1 .. 6;

   function Level (Self : ATX_Heading'Class) return Heading_Level;
   --  The heading level is equal to the number of `#` characters in the
   --  opening sequence.

   function Text (Self : ATX_Heading)
     return Markdown.Annotations.Annotated_Text;
   --  Return nested annotated text

   function To_Block (Self : ATX_Heading) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block)
     return ATX_Heading;
   --  Convert the Block to ATX_Heading

private

   type ATX_Heading_Access is access all
     Markdown.Implementation.ATX_Headings.ATX_Heading'Class;

   type ATX_Heading is new Ada.Finalization.Controlled with record
      Data : ATX_Heading_Access;
   end record;

   overriding procedure Adjust (Self : in out ATX_Heading);
   overriding procedure Finalize (Self : in out ATX_Heading);

   function Level (Self : ATX_Heading'Class) return Heading_Level is
     (Self.Data.Level);

end Markdown.Blocks.ATX_Headings;
