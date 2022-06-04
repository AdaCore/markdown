--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with Markdown.Implementation;

package Markdown.Blocks.Internals is
   pragma Preelaborate;

   procedure Set
     (Self : in out Block;
      Data : Markdown.Implementation.Abstract_Block_Access);

end Markdown.Blocks.Internals;
