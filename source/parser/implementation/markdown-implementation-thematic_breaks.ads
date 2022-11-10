--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a markdown thematic break

package Markdown.Implementation.Thematic_Breaks is
   pragma Preelaborate;

   type Thematic_Break is new Abstract_Block with private;
   --  Thematic_Break block contains annotated inline content

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a Thematic_Break

private

   type Thematic_Break is new Abstract_Block with null record;

   overriding function Create
     (Input : not null access Input_Position) return Thematic_Break;

end Markdown.Implementation.Thematic_Breaks;
