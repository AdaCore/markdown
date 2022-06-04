--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

with Markdown.Implementation.Paragraphs;
with Markdown.Blocks.Paragraphs;

package body Markdown.Blocks is

   ------------
   -- Adjust --
   ------------

   overriding procedure Adjust (Self : in out Block) is
   begin
      if Self.Data.Assigned then
         System.Atomic_Counters.Increment (Self.Data.Counter);
      end if;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Block) is
   begin
      if Self.Data.Assigned then
         if System.Atomic_Counters.Decrement (Self.Data.Counter) then
            Markdown.Implementation.Free (Self.Data);

         else
            Self.Data := null;
         end if;
      end if;
   end Finalize;

   ------------------
   -- Is_Paragraph --
   ------------------

   function Is_Paragraph (Self : Block) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Markdown.Implementation.Paragraphs.Paragraph;
   end Is_Paragraph;

   ------------------
   -- To_Paragraph --
   ------------------

   function To_Paragraph (Self : Block)
     return Markdown.Blocks.Paragraphs.Paragraph is
   begin
      return Markdown.Blocks.Paragraphs.From_Block (Self);
   end To_Paragraph;

end Markdown.Blocks;
