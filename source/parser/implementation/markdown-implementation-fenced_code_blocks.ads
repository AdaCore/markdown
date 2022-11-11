--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a fenced code block

with VSS.String_Vectors;

package Markdown.Implementation.Fenced_Code_Blocks is
   pragma Preelaborate;

   type Fenced_Code_Block is new Abstract_Block with private;
   --  A fenced code block

   function Info_String (Self : Fenced_Code_Block)
     return VSS.Strings.Virtual_String;
   --  Return info string of the code block

   function Text (Self : Fenced_Code_Block)
     return VSS.String_Vectors.Virtual_String_Vector;
   --  Return nested code text

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a Fenced_Code_Block

private

   type Fenced_Code_Block is new Abstract_Block with record
      Indent        : VSS.Strings.Character_Count;
      Fence_Length  : VSS.Strings.Character_Count;
      Is_Tick_Fence : Boolean;
      Closed        : Boolean := False;
      Info_String   : VSS.Strings.Virtual_String;
      Lines         : VSS.String_Vectors.Virtual_String_Vector;
      Blank         : Natural := 0; --  Number of empty lines inside of a block
   end record;

   overriding function Create
     (Input : not null access Input_Position) return Fenced_Code_Block;

   overriding procedure Append_Line
     (Self  : in out Fenced_Code_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean);

   function Info_String (Self : Fenced_Code_Block)
     return VSS.Strings.Virtual_String is (Self.Info_String);

end Markdown.Implementation.Fenced_Code_Blocks;
