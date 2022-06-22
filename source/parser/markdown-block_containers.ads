--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Common interface for all blocks with nested blocks

with Ada.Iterator_Interfaces;
with Markdown.Blocks;

package Markdown.Block_Containers is
   pragma Preelaborate;

   type Block_Container is interface
     with
       Constant_Indexing => Element,
       Default_Iterator  => Iterate,
       Iterator_Element  => Markdown.Blocks.Block;
   --  Block container is just a vector of markdown block elements

   function Is_Empty (Self : Block_Container) return Boolean is abstract;
   --  Check is the container has no nested blocks

   function Length (Self : Block_Container) return Natural is abstract;
   --  Return number of blocks in the container

   function Element
     (Self  : Block_Container;
      Index : Positive) return Markdown.Blocks.Block is abstract;
   --  Return a block with given index

   --  Syntax sugar for Ada 2012 user-defined iterator.
   --  This allows iteration in form of
   --
   --     for Block of Container loop
   --        ...
   --     end loop;
   --

   type Cursor is private;

   function Element
     (Self     : Block_Container'Class;
      Position : Cursor) return Markdown.Blocks.Block;

   function Has_Element (Self : Cursor) return Boolean
     with Inline;

   package Iterator_Interfaces is new Ada.Iterator_Interfaces
     (Cursor, Has_Element);

   type Reversible_Iterator is
     limited new Iterator_Interfaces.Reversible_Iterator with private;

   overriding function First (Self : Reversible_Iterator) return Cursor;

   overriding function Next
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor
        with Inline;

   overriding function Last (Self : Reversible_Iterator) return Cursor;

   overriding function Previous
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor
        with Inline;

   function Iterate (Self : Block_Container'Class) return Reversible_Iterator;
   --  Return an iterator over each element in the vector

private

   type Reversible_Iterator is
     limited new Iterator_Interfaces.Reversible_Iterator with
   record
      Last : Natural;
   end record;

   type Cursor is record
      Index : Natural;
   end record;

   function Has_Element (Self : Cursor) return Boolean is (Self.Index > 0);

end Markdown.Block_Containers;
