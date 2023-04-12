--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Markdown thematic break block elements

private with Markdown.Implementation.Thematic_Breaks;

package Markdown.Blocks.Thematic_Breaks is
   pragma Preelaborate;

   type Thematic_Break is tagged private;
   --  A line consisting of 0-3 spaces of indentation, followed by a sequence
   --  of three or more matching `-`, `_`, or `*` characters, each followed
   --  optionally by any number of spaces or tabs, forms a thematic break.

   function To_Block (Self : Thematic_Break) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block) return Thematic_Break;
   --  Convert the Block to Thematic_Break

private

   type Thematic_Break_Access is access all
     Markdown.Implementation.Thematic_Breaks.Thematic_Break;

   type Thematic_Break is new Ada.Finalization.Controlled with record
      Data : Thematic_Break_Access;
   end record;

   overriding procedure Adjust (Self : in out Thematic_Break);
   overriding procedure Finalize (Self : in out Thematic_Break);

end Markdown.Blocks.Thematic_Breaks;
