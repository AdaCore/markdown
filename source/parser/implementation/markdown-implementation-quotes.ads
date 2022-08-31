--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a block quote

package Markdown.Implementation.Quotes is

   pragma Preelaborate;

   type Quote is new Abstract_Container_Block with private;
   --  The quote is a node for markdown block quote representation

   type Quote_Access is access all Quote;

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a block quote

private
   type Quote is new Abstract_Container_Block with null record;

   overriding function Create (Input : not null access Input_Position)
     return Quote;

   overriding procedure Consume_Continuation_Markers
     (Self  : in out Quote;
      Input : in out Input_Position;
      Ok    : out Boolean);

end Markdown.Implementation.Quotes;
