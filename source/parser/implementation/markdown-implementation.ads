--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal markdown types and methods

with Ada.Containers.Vectors;
with Ada.Tags;
with Ada.Unchecked_Deallocation;

with System.Atomic_Counters;

with VSS.Strings;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Cursors;

with Markdown.Inline_Parsers;

package Markdown.Implementation is
   pragma Preelaborate;

   type Abstract_Block is tagged;
   --  A root type for any internal block representation

   type Abstract_Block_Access is access all Abstract_Block'Class;

   procedure Reference (Self : Abstract_Block_Access);

   type Abstract_Block is abstract tagged limited record
      Counter : System.Atomic_Counters.Atomic_Counter;
   end record;

   function Assigned (Value : access Abstract_Block'Class) return Boolean is
     (Value /= null);
   --  If Value is not null

   function Is_Container (Self : Abstract_Block) return Boolean is (False);
   --  If Self is a container block

   type Input_Line is tagged record
      Text     : VSS.Strings.Virtual_String;
      --  One line of the markdown document without end of line characters
      Expanded : VSS.Strings.Virtual_String;
      --  Text with all tabulation characters expanded to spaces
   end record;
   --  One line of the markdown including original and tab expanded values

   function Unexpanded_Tail
     (Self : Input_Line;
      From : VSS.Strings.Character_Iterators.Character_Iterator)
        return VSS.Strings.Virtual_String;
   --  Get From as a position in Self.Expanded and return a slice of Self.Text,
   --  that corresponds to Self.Expanded.Tail (From)

   function Unexpanded_Tail
     (Self : Input_Line;
      From : VSS.Strings.Character_Iterators.Character_Iterator;
      To   : VSS.Strings.Character_Iterators.Character_Iterator)
        return VSS.Strings.Virtual_String;
   --  The same as before, but with `To`.

   type Input_Line_Access is access constant Input_Line;

   type Input_Position is record
      Line  : not null Input_Line_Access;
      First : VSS.Strings.Character_Iterators.Character_Iterator;
      --  The position to read from Line.Expanded string
   end record;

   not overriding function Create
     (Input : not null access Input_Position) return Abstract_Block
        is abstract;
   --  Create a new block for given input line. Input should match a
   --  corresponding detector. The Input.First is shifted to the next position

   subtype Can_Interrupt_Paragraph is Boolean;
   --  if a line can interrupt a paragraph

   not overriding procedure Append_Line
     (Self  : in out Abstract_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean) is null;
   --  Append an input line to the block. CIP = True if another block is
   --  detected at the given position and it can interrupt a paragraph.
   --  Return Ok if input was appended to the block.

   not overriding procedure Complete_Parsing
     (Self   : in out Abstract_Block;
      Parser : Markdown.Inline_Parsers.Inline_Parser) is null;
   --  Adjust block state at the end of parse process

   package Block_Vectors is new Ada.Containers.Vectors
     (Positive, Abstract_Block_Access);

   type Abstract_Container_Block is abstract new Abstract_Block with record
      Children : Block_Vectors.Vector;
   end record;
   --  A root type for block containing other blocks as children

   overriding function Is_Container (Self : Abstract_Container_Block)
     return Boolean is (True);

   not overriding procedure Consume_Continuation_Markers
     (Self  : in out Abstract_Container_Block;
      Line  : in out Input_Position;
      Match : out Boolean) is abstract;
   --  Set Match to True if Line has continuation markers for the block. If so
   --  shift Line.First to skip the marker.

   overriding procedure Complete_Parsing
     (Self   : in out Abstract_Container_Block;
      Parser : Markdown.Inline_Parsers.Inline_Parser);
   --  For all container blocks iterate over children and
   --  create List node when needed and move List_Items inside.

   type Abstract_Container_Block_Access is access all
     Abstract_Container_Block'Class;

   procedure Reference (Self : Abstract_Container_Block_Access);

   procedure Unreference (Self : in out Abstract_Container_Block_Access);

   type Block_Detector is access procedure
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector checks if given input line starts some markdown block. If
   --  so it returns Tag of the corresponding block type and CIP if the block
   --  can interrupt a paragraph. The markdown parser then construct an object
   --  of that type with Create method.

   procedure Free is new Ada.Unchecked_Deallocation
     (Abstract_Block'Class, Abstract_Block_Access);

   procedure Forward
     (Cursor : in out VSS.Strings.Character_Iterators.Character_Iterator;
      Count  : VSS.Strings.Character_Index := 1);
   --  Move Cursor forward

   use type VSS.Strings.Character_Index;

   function "<"
     (Left, Right : VSS.Strings.Cursors.Abstract_Character_Cursor'Class)
       return Boolean is
         (Left.Character_Index < Right.Character_Index);

end Markdown.Implementation;
