--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Block_Containers is

   -------------
   -- Element --
   -------------

   function Element (Self : Block_Container'Class; Position : Cursor)
      return Markdown.Blocks.Block is (Self.Element (Position.Index));

   -----------
   -- First --
   -----------

   overriding function First (Self : Reversible_Iterator) return Cursor is
     (Index => (if Self.Last >= 1 then 1 else 0));

   -------------
   -- Iterate --
   -------------

   function Iterate (Self : Block_Container'Class)
      return Reversible_Iterator is (Last => Self.Length);

   ----------
   -- Last --
   ----------

   overriding function Last (Self : Reversible_Iterator) return Cursor is
      (Index => (if Self.Last >= 1 then 1 else 0));

   ----------
   -- Next --
   ----------

   overriding function Next
     (Self : Reversible_Iterator; Position : Cursor) return Cursor
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
     (Self : Reversible_Iterator; Position : Cursor) return Cursor is
       (Index => (if Position.Index > 0 then Position.Index - 1 else 0));

end Markdown.Block_Containers;
