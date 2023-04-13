--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body Markdown.Blocks.Internals is

   ---------
   -- Set --
   ---------

   procedure Set
     (Self : in out Block;
      Data : Markdown.Implementation.Abstract_Block_Access) is
   begin
      pragma Assert (not Self.Data.Assigned);
      Self.Data := Data;
   end Set;

end Markdown.Blocks.Internals;
