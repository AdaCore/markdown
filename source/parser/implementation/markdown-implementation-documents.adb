--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Implementation.Documents is

   ----------------------------------
   -- Consume_Continuation_Markers --
   ----------------------------------

   overriding procedure Consume_Continuation_Markers
     (Self  : in out Document;
      Line  : in out Input_Position;
      Match :    out Boolean)
   is
   begin
      --  Document node always matches but doesn't consume any markers
      Match := True;
   end Consume_Continuation_Markers;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Document
   is
   begin
      --  Document isn't expected to be created with the Create function
      return raise Program_Error with "Unexpected Create";
   end Create;

end Markdown.Implementation.Documents;
