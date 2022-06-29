--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Markdown list of items

with Ada.Iterator_Interfaces;

with Markdown.List_Items;
private with Markdown.Implementation.Lists;

package Markdown.Blocks.Lists is
   pragma Preelaborate;

   type List is tagged private
     with
       Constant_Indexing => Element,
       Default_Iterator  => Iterate,
       Iterator_Element  => Markdown.List_Items.List_Item;
   --  List contains list items

   function Is_Ordered (Self : List'Class) return Boolean;
   --  Return True if list has an ordered list markers.

   function Start (Self : List'Class) return Natural
     with Pre => Self.Is_Ordered;
   --  An integer to start counting from for the list items.

   function Length (Self : List) return Natural;
   --  Return number of list items in the list

   function Element
     (Self  : List;
      Index : Positive) return Markdown.List_Items.List_Item;
   --  Return a list item with given index

   function To_Block (Self : List) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block) return List;
   --  Convert the Block to List

   --  Syntax sugar for Ada 2012 user-defined iterator.
   --  This allows iteration in form of
   --
   --     for Item of The_List loop
   --        ...
   --     end loop;

   type Cursor is private;

   function Element
     (Self     : List;
      Position : Cursor) return Markdown.List_Items.List_Item;

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

   function Iterate (Self : List'Class) return Reversible_Iterator;
   --  Return an iterator over each element in the vector

private

   type List_Access is access all
     Markdown.Implementation.Lists.List;

   type List is new Ada.Finalization.Controlled with record
      Data : List_Access;
   end record;

   overriding procedure Adjust (Self : in out List);
   overriding procedure Finalize (Self : in out List);

   type Cursor is record
      Index : Natural;
   end record;

   function Has_Element (Self : Cursor) return Boolean is (Self.Index > 0);

   function To_Index (Self : Cursor) return Natural is (Self.Index);

   type Reversible_Iterator is
     limited new Iterator_Interfaces.Reversible_Iterator with
   record
      Last : Natural;
   end record;

end Markdown.Blocks.Lists;
