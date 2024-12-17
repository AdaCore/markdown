--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with System.Atomic_Counters;

package body Markdown.Blocks.Tables is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Table) is
   begin
      if Is_Assigned (Self.Data) then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   ---------------
   -- Alignment --
   ---------------

   function Alignment
     (Self : Table; Column : Positive) return Column_Alignment is
       (Column_Alignment'Val (Self.Data.Table_Column_Alignment (Column)));

   ----------
   -- Cell --
   ----------

   function Cell (Self : Table; Row, Column : Positive)
     return Markdown.Annotations.Annotated_Text is
        (Self.Data.Table_Cell (Row + 2, Column));

   -------------
   -- Columns --
   -------------

   function Columns (Self : Table) return Positive is
     (Self.Data.Table_Columns);

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Table) is
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

   function From_Block (Self : Markdown.Blocks.Block) return Table is
   begin
      System.Atomic_Counters.Increment (Self.Data.Counter);

      return (Ada.Finalization.Controlled with Data =>
               Paragraph_Access (Self.Data));
   end From_Block;

   ------------
   -- Header --
   ------------

   function Header (Self : Table; Column : Positive)
      return Markdown.Annotations.Annotated_Text is
        (Self.Data.Table_Cell (1, Column));

   ----------
   -- Rows --
   ----------

   function Rows (Self : Table) return Natural is
     (Self.Data.Table_Rows - 2);

   --------------
   -- To_Block --
   --------------

   function To_Block (Self : Table) return Markdown.Blocks.Block is
   begin
      return (Ada.Finalization.Controlled with Data =>
               Markdown.Implementation.Abstract_Block_Access (Self.Data));
   end To_Block;

end Markdown.Blocks.Tables;
