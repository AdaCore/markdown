--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with Ada.Unchecked_Deallocation;
with System.Atomic_Counters;

with Markdown.Blocks.Internals;

package body Markdown.Documents is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Document) is
   begin
      if Self.Data.Assigned then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Document) is
      procedure Free is new Ada.Unchecked_Deallocation
        (Markdown.Implementation.Abstract_Container_Block'Class,
         Abstract_Container_Block_Access);
   begin
      if not Self.Data.Assigned then
         null;
      elsif System.Atomic_Counters.Decrement (Self.Data.Counter) then

         for Item of Self.Data.Children loop
            if System.Atomic_Counters.Decrement (Item.Counter) then
               Markdown.Implementation.Free (Item);
            end if;
         end loop;

         Free (Self.Data);

      else
         Self.Data := null;
      end if;
   end Finalize;

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty (Self : Document) return Boolean is
   begin
      return not Self.Data.Assigned or else Self.Data.Children.Is_Empty;
   end Is_Empty;

   ------------
   -- Length --
   ------------

   overriding function Length (Self : Document) return Natural is
   begin
      return
        (if Self.Data.Assigned then Self.Data.Children.Last_Index else 0);
   end Length;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self  : Document;
      Index : Positive) return Markdown.Blocks.Block
   is
      Item : constant Markdown.Implementation.Abstract_Block_Access :=
        Self.Data.Children (Index);
   begin
      System.Atomic_Counters.Increment (Item.Counter);

      return Result : Markdown.Blocks.Block do
         Markdown.Blocks.Internals.Set (Result, Item);
      end return;
   end Element;

end Markdown.Documents;
