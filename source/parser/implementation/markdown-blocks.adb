--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with System.Atomic_Counters;

with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Blocks.Quotes;

with Markdown.Implementation.Indented_Code_Blocks;
with Markdown.Implementation.Lists;
with Markdown.Implementation.Paragraphs;
with Markdown.Implementation.Quotes;

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

   ----------------------------
   -- Is_Indented_Code_Block --
   ----------------------------

   function Is_Indented_Code_Block (Self : Block'Class) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Implementation.Indented_Code_Blocks.Indented_Code_Block'Class;
   end Is_Indented_Code_Block;

   -------------
   -- Is_List --
   -------------

   function Is_List (Self : Block'Class) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Markdown.Implementation.Lists.List;
   end Is_List;

   ------------------
   -- Is_Paragraph --
   ------------------

   function Is_Paragraph (Self : Block'Class) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Markdown.Implementation.Paragraphs.Paragraph;
   end Is_Paragraph;

   --------------
   -- Is_Quote --
   --------------

   function Is_Quote (Self : Block'Class) return Boolean is
   begin
      return Self.Data.Assigned
        and then Self.Data.all in
          Markdown.Implementation.Quotes.Quote;
   end Is_Quote;

   ----------------------------
   -- To_Indented_Code_Block --
   ----------------------------

   function To_Indented_Code_Block (Self : Block)
     return Markdown.Blocks.Indented_Code.Indented_Code_Block is
   begin
      return Markdown.Blocks.Indented_Code.From_Block (Self);
   end To_Indented_Code_Block;

   -------------
   -- To_List --
   -------------

   function To_List (Self : Block) return Markdown.Blocks.Lists.List is
   begin
      return Markdown.Blocks.Lists.From_Block (Self);
   end To_List;

   ------------------
   -- To_Paragraph --
   ------------------

   function To_Paragraph (Self : Block)
     return Markdown.Blocks.Paragraphs.Paragraph is
   begin
      return Markdown.Blocks.Paragraphs.From_Block (Self);
   end To_Paragraph;

   --------------
   -- To_Quote --
   --------------

   function To_Quote (Self : Block)
     return Markdown.Blocks.Quotes.Quote is
   begin
      return Markdown.Blocks.Quotes.From_Block (Self);
   end To_Quote;

end Markdown.Blocks;
