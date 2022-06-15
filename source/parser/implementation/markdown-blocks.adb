--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Paragraphs;

with Markdown.Implementation.Indented_Code_Blocks;
with Markdown.Implementation.Paragraphs;

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

   function Is_Paragraph (Self : Block'Class) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Markdown.Implementation.Paragraphs.Paragraph;
   end Is_Paragraph;

   ----------------------------
   -- Is_Indented_Code_Block --
   ----------------------------

   function Is_Indented_Code_Block (Self : Block'Class) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Markdown.Implementation.Indented_Code_Blocks.Indented_Code_Block;
   end Is_Indented_Code_Block;

   ----------------------------
   -- To_Indented_Code_Block --
   ----------------------------

   function To_Indented_Code_Block (Self : Block)
     return Markdown.Blocks.Indented_Code.Indented_Code_Block is
   begin
      return Markdown.Blocks.Indented_Code.From_Block (Self);
   end To_Indented_Code_Block;

   ------------------
   -- To_Paragraph --
   ------------------

   function To_Paragraph (Self : Block)
     return Markdown.Blocks.Paragraphs.Paragraph is
   begin
      return Markdown.Blocks.Paragraphs.From_Block (Self);
   end To_Paragraph;

end Markdown.Blocks;
