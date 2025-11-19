--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal representation of a markdown HTML blocks

with VSS.String_Vectors;

package Markdown.Implementation.HTML_Blocks is
   pragma Preelaborate;

   type HTML_Block is new Abstract_Block with private;
   --  HTML_Block block contains annotated inline content

   function Text (Self : HTML_Block)
     return VSS.String_Vectors.Virtual_String_Vector;
   --  Return nested code text

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a HTML_Block

   procedure Initialize;
   --  Prepare regexp patterns

private

   subtype HTML_Block_Kind is Positive range 1 .. 7;
   --  There are seven kinds of HTML block, ...

   type HTML_Block is new Abstract_Block with record
      Closed : Boolean := False;
      Kind   : HTML_Block_Kind;
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
   end record;

   overriding function Create
     (Input : not null access Input_Position) return HTML_Block;

   overriding procedure Append_Line
     (Self  : in out HTML_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean);

   function Text (Self : HTML_Block)
     return VSS.String_Vectors.Virtual_String_Vector is (Self.Lines);

end Markdown.Implementation.HTML_Blocks;
