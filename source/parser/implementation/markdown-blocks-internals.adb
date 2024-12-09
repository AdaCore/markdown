--
--  Copyright (C) 2021-2024, AdaCore
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
      pragma Assert (not Markdown.Implementation.Is_Assigned (Self.Data));
      Self.Data := Data;
   end Set;

end Markdown.Blocks.Internals;
