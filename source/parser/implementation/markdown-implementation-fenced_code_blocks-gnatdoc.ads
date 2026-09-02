--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  A variant of fenced code blocks used in GNATdoc.
--  Its code fences are indented with 2 or less spaces, because indented
--  code blocks of GNATdoc start at 3 spaces.

package Markdown.Implementation.Fenced_Code_Blocks.GNATdoc is
   pragma Preelaborate;

   type GNATdoc_Fenced_Code_Block is new Fenced_Code_Block with null record;

   overriding function Create
     (Input : not null access Input_Position)
      return GNATdoc_Fenced_Code_Block;

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a gnatdoc fenced code block.
   --  Regexp patterns are prepared by Fenced_Code_Blocks.Initialize, this
   --  variant has no patterns of its own.

end Markdown.Implementation.Fenced_Code_Blocks.GNATdoc;
