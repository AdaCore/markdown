--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

package body Markdown.Blocks.Indented_Code is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Indented_Code_Block) is
   begin
      if Self.Data.Assigned then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Indented_Code_Block) is
   begin
      if Self.Data.Assigned then
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

   function From_Block (Self : Markdown.Blocks.Block)
     return Indented_Code_Block is
   begin
      System.Atomic_Counters.Increment (Self.Data.Counter);

      return (Ada.Finalization.Controlled with Data =>
               Indented_Code_Block_Access (Self.Data));
   end From_Block;

   ----------
   -- Text --
   ----------

   function Text (Self : Indented_Code_Block)
     return VSS.String_Vectors.Virtual_String_Vector is
   begin
      return Self.Data.Text;
   end Text;

   --------------
   -- To_Block --
   --------------

   function To_Block (Self : Indented_Code_Block)
     return Markdown.Blocks.Block is
   begin
      return (Ada.Finalization.Controlled with Data =>
               Markdown.Implementation.Abstract_Block_Access (Self.Data));
   end To_Block;

end Markdown.Blocks.Indented_Code;
