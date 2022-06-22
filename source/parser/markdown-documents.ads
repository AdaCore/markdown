--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  The document is a root node of markdown document representation

private with Ada.Finalization;

with Markdown.Block_Containers;
with Markdown.Blocks;
private with Markdown.Implementation;

package Markdown.Documents is
   pragma Preelaborate;

   type Document is new Markdown.Block_Containers.Block_Container
     with private;
   --  Markdown document contains nested block elements

   --  procedure Append
   --  (Self  : in out Document;
   --   Block : Markdown.Blocks.Block);
   --  Append a new markdown block to the document

private

   type Document is new Ada.Finalization.Controlled
     and Markdown.Block_Containers.Block_Container with
   record
      Data : Markdown.Implementation.Abstract_Container_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out Document);
   overriding procedure Finalize (Self : in out Document);
   overriding function Is_Empty (Self : Document) return Boolean;
   overriding function Length (Self : Document) return Natural;

   overriding function Element
     (Self  : Document;
      Index : Positive) return Markdown.Blocks.Block;

end Markdown.Documents;
