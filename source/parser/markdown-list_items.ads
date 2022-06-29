--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  The list item contains nested blocks and always enclosed by a list block.

private with Ada.Finalization;

with Markdown.Block_Containers;
with Markdown.Blocks;
private with Markdown.Implementation.List_Items;

package Markdown.List_Items is
   pragma Preelaborate;

   type List_Item is new Markdown.Block_Containers.Block_Container
     with private;
   --  Markdown list item contains nested block elements

   function Is_Ordered (Self : List_Item'Class) return Boolean;
   --  Return True if list item has an ordered list marker.

private

   type List_Item is new Ada.Finalization.Controlled
     and Markdown.Block_Containers.Block_Container with
   record
      Data : Markdown.Implementation.List_Items.List_Item_Access;
   end record;

   overriding procedure Adjust (Self : in out List_Item);
   overriding procedure Finalize (Self : in out List_Item);
   overriding function Is_Empty (Self : List_Item) return Boolean;
   overriding function Length (Self : List_Item) return Natural;

   overriding function Element
     (Self  : List_Item;
      Index : Positive) return Markdown.Blocks.Block;

end Markdown.List_Items;
