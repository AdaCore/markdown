--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

with Markdown.Blocks.Internals;

package body Markdown.List_Items is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out List_Item) is
   begin
      if Self.Data.Assigned then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self : List_Item; Index : Positive) return Markdown.Blocks.Block
   is
      Item : constant Markdown.Implementation.Abstract_Block_Access :=
        Self.Data.Children (Index);
   begin
      Markdown.Implementation.Reference (Item);

      return Result : Markdown.Blocks.Block do
         Markdown.Blocks.Internals.Set (Result, Item);
      end return;
   end Element;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out List_Item) is
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

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty (Self : List_Item) return Boolean is
   begin
      return not Self.Data.Assigned or else Self.Data.Children.Is_Empty;
   end Is_Empty;

   ----------------
   -- Is_Ordered --
   ----------------

   function Is_Ordered (Self : List_Item'Class) return Boolean is
   begin
      return Self.Data.Is_Ordered;
   end Is_Ordered;

   ------------
   -- Length --
   ------------

   overriding function Length (Self : List_Item) return Natural is
   begin
      return
        (if Self.Data.Assigned then Self.Data.Children.Last_Index else 0);
   end Length;

end Markdown.List_Items;
