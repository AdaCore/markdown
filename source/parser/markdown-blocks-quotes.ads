--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Markdown block quote elements

with Markdown.Block_Containers;
private with Markdown.Implementation;

package Markdown.Blocks.Quotes is
   pragma Preelaborate;

   type Quote is new Markdown.Block_Containers.Block_Container
     with private;
   --  A block quote marker consists of 0-3 spaces of initial indent, plus
   --  1) the character `>` together with a following space, or
   --  2) a single character `>` not followed by a space.

   function To_Block (Self : Quote) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block)
     return Quote;
   --  Convert the Block to Quote

private

   type Quote is new Ada.Finalization.Controlled
     and Markdown.Block_Containers.Block_Container with
   record
      Data : Markdown.Implementation.Abstract_Container_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out Quote);
   overriding procedure Finalize (Self : in out Quote);
   overriding function Is_Empty (Self : Quote) return Boolean;
   overriding function Length (Self : Quote) return Natural;

   overriding function Element
     (Self  : Quote;
      Index : Positive) return Markdown.Blocks.Block;

end Markdown.Blocks.Quotes;
