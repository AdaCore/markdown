--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body Markdown.List_Items.Internals is

   ---------
   -- Set --
   ---------

   procedure Set
     (Self : in out List_Item;
      Data : Markdown.Implementation.Abstract_Block_Access) is
   begin
      pragma Assert (not Is_Assigned (Self.Data));
      Self.Data :=
        Markdown.Implementation.List_Items.List_Item_Access (Data);
   end Set;

end Markdown.List_Items.Internals;
