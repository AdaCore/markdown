--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a indented code blocks

private with VSS.Regular_Expressions;

with VSS.String_Vectors;

package Markdown.Implementation.Indented_Code_Blocks is
   pragma Preelaborate;

   type Indented_Code_Block is new Abstract_Block with private;
   --  An indented code block

   function Text (Self : Indented_Code_Block)
     return VSS.String_Vectors.Virtual_String_Vector;
   --  Return nested annotated text

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a Indented_Code_Block

private

   type Indented_Code_Block is new Abstract_Block with record
      Indent : VSS.Strings.Character_Count := 4;  --  Overridden in GNATdoc
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
   end record;

   overriding function Create
     (Input : not null access Input_Position) return Indented_Code_Block;

   overriding procedure Append_Line
     (Self  : in out Indented_Code_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean);

   Indent : VSS.Regular_Expressions.Regular_Expression;
   --  Some spaces at the beginning of a string: "^ +"

end Markdown.Implementation.Indented_Code_Blocks;
