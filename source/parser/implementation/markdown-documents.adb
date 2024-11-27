--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Blocks.Internals;

package body Markdown.Documents is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Document) is
      use type Markdown.Implementation.Abstract_Container_Block_Access;

   begin
      if Self.Data /= null then
         Markdown.Implementation.Reference (Self.Data);
      end if;
   end Adjust;

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
      Markdown.Implementation.Reference (Item);

      return Result : Markdown.Blocks.Block do
         Markdown.Blocks.Internals.Set (Result, Item);
      end return;
   end Element;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Document) is
      use type Markdown.Implementation.Abstract_Container_Block_Access;

   begin
      if Self.Data /= null then
         Markdown.Implementation.Unreference (Self.Data);
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

end Markdown.Documents;
