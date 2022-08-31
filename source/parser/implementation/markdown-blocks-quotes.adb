--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

with Markdown.Blocks.Internals;
with Markdown.Implementation.Quotes;

package body Markdown.Blocks.Quotes is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Quote) is
   begin
      Markdown.Implementation.Reference (Self.Data);
   end Adjust;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self  : Quote;
      Index : Positive) return Markdown.Blocks.Block
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

   overriding procedure Finalize (Self : in out Quote) is
   begin
      Markdown.Implementation.Unreference (Self.Data);
   end Finalize;

   ----------------
   -- From_Block --
   ----------------

   function From_Block (Self : Markdown.Blocks.Block)
     return Quote is
   begin
      pragma Assert
        (not Self.Data.Assigned or else
           Self.Data.all in Implementation.Quotes.Quote'Class);

      System.Atomic_Counters.Increment (Self.Data.Counter);

      return (Ada.Finalization.Controlled with
                Data => Markdown.Implementation.Abstract_Container_Block_Access
                          (Self.Data));
   end From_Block;

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty (Self : Quote) return Boolean is
   begin
      return not Self.Data.Assigned or else Self.Data.Children.Is_Empty;
   end Is_Empty;

   ------------
   -- Length --
   ------------

   overriding function Length (Self : Quote) return Natural is
   begin
      return
        (if Self.Data.Assigned then Self.Data.Children.Last_Index else 0);
   end Length;

   --------------
   -- To_Block --
   --------------

   function To_Block (Self : Quote)
     return Markdown.Blocks.Block is
   begin
      return (Ada.Finalization.Controlled with Data =>
               Markdown.Implementation.Abstract_Block_Access (Self.Data));
   end To_Block;

end Markdown.Blocks.Quotes;
