--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with System.Atomic_Counters;

package body Markdown.Blocks.Thematic_Breaks is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Thematic_Break) is
   begin
      if Is_Assigned (Self.Data) then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Thematic_Break) is
   begin
      if Is_Assigned (Self.Data) then
         if System.Atomic_Counters.Decrement (Self.Data.Counter) then
            Markdown.Implementation.Free
              (Markdown.Implementation.Abstract_Block_Access (Self.Data));

         else
            Self.Data := null;
         end if;
      end if;
   end Finalize;

   ----------------
   -- From_Block --
   ----------------

   function From_Block (Self : Markdown.Blocks.Block) return Thematic_Break is
   begin
      System.Atomic_Counters.Increment (Self.Data.Counter);

      return (Ada.Finalization.Controlled with Data =>
               Thematic_Break_Access (Self.Data));
   end From_Block;

   --------------
   -- To_Block --
   --------------

   function To_Block (Self : Thematic_Break) return Markdown.Blocks.Block is
   begin
      return (Ada.Finalization.Controlled with Data =>
               Markdown.Implementation.Abstract_Block_Access (Self.Data));
   end To_Block;

end Markdown.Blocks.Thematic_Breaks;
