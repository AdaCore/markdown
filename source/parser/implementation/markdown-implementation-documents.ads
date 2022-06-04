--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a markdown document

package Markdown.Implementation.Documents is
   pragma Preelaborate;

   type Document is new Abstract_Container_Block with private;
   --  The document is a root node of markdown document representation

private
   type Document is new Abstract_Container_Block with null record;

   overriding function Create (Input : not null access Input_Position)
     return Document;

   overriding procedure Consume_Continuation_Markers
     (Self  : in out Document;
      Line  : in out Input_Position;
      Match : out Boolean);

end Markdown.Implementation.Documents;
