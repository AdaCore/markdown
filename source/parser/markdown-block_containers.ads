--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Common interface for all blocks with nested blocks

with Markdown.Blocks;

package Markdown.Block_Containers is
   pragma Preelaborate;

   type Block_Container is interface
     with
       Constant_Indexing => Element;
   --  Block container is just a vector of markdown block elements

   function Is_Empty (Self : Block_Container) return Boolean is abstract;
   --  Check is the container has no nested blocks

   function Length (Self : Block_Container) return Natural is abstract;
   --  Return number of blocks in the container

   function Element
     (Self  : Block_Container;
      Index : Positive) return Markdown.Blocks.Block is abstract;
   --  Return a block with given index

end Markdown.Block_Containers;
