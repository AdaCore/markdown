--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Implementation;

package Markdown.List_Items.Internals is
   pragma Preelaborate;

   procedure Set
     (Self : in out List_Item;
      Data : Markdown.Implementation.Abstract_Block_Access);

end Markdown.List_Items.Internals;
