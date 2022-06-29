--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.List_Items.Internals is

   ---------
   -- Set --
   ---------

   procedure Set
     (Self : in out List_Item;
      Data : Markdown.Implementation.Abstract_Block_Access) is
   begin
      pragma Assert (not Self.Data.Assigned);
      Self.Data :=
        Markdown.Implementation.List_Items.List_Item_Access (Data);
   end Set;

end Markdown.List_Items.Internals;
