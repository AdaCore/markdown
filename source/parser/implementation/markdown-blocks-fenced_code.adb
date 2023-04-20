--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with System.Atomic_Counters;

package body Markdown.Blocks.Fenced_Code is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Fenced_Code_Block) is
   begin
      if Self.Data.Assigned then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Fenced_Code_Block) is
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
     return Fenced_Code_Block is
   begin
      System.Atomic_Counters.Increment (Self.Data.Counter);

      return (Ada.Finalization.Controlled with Data =>
               Fenced_Code_Block_Access (Self.Data));
   end From_Block;

   -----------------
   -- Info_String --
   -----------------

   function Info_String (Self : Fenced_Code_Block)
     return VSS.Strings.Virtual_String is
   begin
      return Self.Data.Info_String;
   end Info_String;

   ----------
   -- Text --
   ----------

   function Text (Self : Fenced_Code_Block)
     return VSS.String_Vectors.Virtual_String_Vector is
   begin
      return Self.Data.Text;
   end Text;

   --------------
   -- To_Block --
   --------------

   function To_Block (Self : Fenced_Code_Block)
     return Markdown.Blocks.Block is
   begin
      return (Ada.Finalization.Controlled with Data =>
               Markdown.Implementation.Abstract_Block_Access (Self.Data));
   end To_Block;

end Markdown.Blocks.Fenced_Code;