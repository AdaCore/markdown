--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  A variant of indented code blocks used in GNATdoc.
--  It's indented with 3 or more spaces

package Markdown.Implementation.Indented_Code_Blocks.GNATdoc is
   pragma Preelaborate;

   type GNATdoc_Code_Block is new Indented_Code_Block with null record;

   overriding function Create
     (Input : not null access Input_Position) return GNATdoc_Code_Block;

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a gnatdoc code block

end Markdown.Implementation.Indented_Code_Blocks.GNATdoc;
