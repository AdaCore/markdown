--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

with Markdown.List_Items.Internals;

package body Markdown.Blocks.Lists is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out List) is
   begin
      if Self.Data.Assigned then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   -------------
   -- Element --
   -------------

   function Element
     (Self  : List;
      Index : Positive) return Markdown.List_Items.List_Item
   is
      Item : constant Markdown.Implementation.Abstract_Block_Access :=
        Self.Data.Children (Index);
   begin
      Markdown.Implementation.Reference (Item);

      return Result : Markdown.List_Items.List_Item do
         Markdown.List_Items.Internals.Set (Result, Item);
      end return;
   end Element;

   function Element
     (Self     : List;
      Position : Cursor) return Markdown.List_Items.List_Item is
        (Self.Element (Position.Index));

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out List) is
   begin
      if Self.Data.Assigned then
         if System.Atomic_Counters.Decrement (Self.Data.Counter) then
            Markdown.Implementation.Free
              (Markdown.Implementation.Abstract_Block_Access (Self.Data));

         else
            Self.Data := null;
         end if;
      end if;
   end Finalize;

   -----------
   -- First --
   -----------

   overriding function First (Self : Reversible_Iterator) return Cursor is
     (Index => (if Self.Last >= 1 then 1 else 0));

   ----------------
   -- From_Block --
   ----------------

   function From_Block (Self : Markdown.Blocks.Block) return List is
   begin
      System.Atomic_Counters.Increment (Self.Data.Counter);

      return (Ada.Finalization.Controlled with Data =>
               List_Access (Self.Data));
   end From_Block;

   ----------------
   -- Is_Ordered --
   ----------------

   function Is_Ordered (Self : List'Class) return Boolean is
     (Self.Data.Is_Ordered);

   -------------
   -- Iterate --
   -------------

   function Iterate (Self : List'Class) return Reversible_Iterator is
     (Last => Self.Length);

   ----------
   -- Last --
   ----------

   overriding function Last (Self : Reversible_Iterator) return Cursor is
     (Index => (if Self.Last >= 1 then 1 else 0));

   ------------
   -- Length --
   ------------

   function Length (Self : List) return Natural is
   begin
      return
        (if Self.Data.Assigned then Self.Data.Children.Last_Index else 0);
   end Length;

   ----------
   -- Next --
   ----------

   overriding function Next
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor
   is
      Index : constant Natural :=
        (if Position.Index < Self.Last then Position.Index + 1 else 0);
   begin
      return (Index => Index);
   end Next;

   --------------
   -- Previous --
   --------------

   overriding function Previous
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor is
        (Index => (if Position.Index > 0 then Position.Index - 1 else 0));

   -----------
   -- Start --
   -----------

   function Start (Self : List'Class) return Natural is
     (Self.Data.Start);

   --------------
   -- To_Block --
   --------------

   function To_Block (Self : List) return Markdown.Blocks.Block is
   begin
      return (Ada.Finalization.Controlled with Data =>
               Markdown.Implementation.Abstract_Block_Access (Self.Data));
   end To_Block;

end Markdown.Blocks.Lists;
