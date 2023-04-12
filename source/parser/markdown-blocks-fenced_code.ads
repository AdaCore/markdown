--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Markdown fenced code block elements

with VSS.String_Vectors;
with VSS.Strings;
private with Markdown.Implementation.Fenced_Code_Blocks;

package Markdown.Blocks.Fenced_Code is
   pragma Preelaborate;

   type Fenced_Code_Block is tagged private;
   --  A code fence is a sequence of at least three consecutive backtick
   --  characters (`) or tildes (~). (Tildes and backticks cannot be mixed.) A
   --  fenced code block begins with a code fence, indented no more than three
   --  spaces.

   function Info_String (Self : Fenced_Code_Block)
     return VSS.Strings.Virtual_String;
   --  The line with the opening code fence may optionally contain some text
   --  following the code fence; this is trimmed of leading and trailing
   --  whitespace and called the info string.

   function Text (Self : Fenced_Code_Block)
     return VSS.String_Vectors.Virtual_String_Vector;
   --  Return nested code lines

   function To_Block (Self : Fenced_Code_Block) return Markdown.Blocks.Block;
   --  Convert to Block type

   function From_Block (Self : Markdown.Blocks.Block)
     return Fenced_Code_Block;
   --  Convert the Block to Fenced_Code_Block

private

   type Fenced_Code_Block_Access is access all
     Markdown.Implementation.Fenced_Code_Blocks.Fenced_Code_Block'Class;

   type Fenced_Code_Block is new Ada.Finalization.Controlled with record
      Data : Fenced_Code_Block_Access;
   end record;

   overriding procedure Adjust (Self : in out Fenced_Code_Block);
   overriding procedure Finalize (Self : in out Fenced_Code_Block);

end Markdown.Blocks.Fenced_Code;
