--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Ada.Tags.Generic_Dispatching_Constructor;

with Markdown.Documents.Internals;
with Markdown.Implementation.ATX_Headings;
with Markdown.Implementation.Auto_Links;
with Markdown.Implementation.Code_Spans;
with Markdown.Implementation.Documents;
with Markdown.Implementation.Fenced_Code_Blocks;
with Markdown.Implementation.HTML_Blocks;
with Markdown.Implementation.Indented_Code_Blocks;
with Markdown.Implementation.List_Items;
with Markdown.Implementation.Paragraphs;
with Markdown.Implementation.Quotes;
with Markdown.Implementation.Thematic_Breaks;

package body Markdown.Parsers is

   procedure Find_Block_Start
     (Self : Markdown_Parser'Class;
      Line : Input_Position;
      Tag  : out Ada.Tags.Tag;
      CIP  : out Can_Interrupt_Paragraph);
   --  Find the block that could start in given line. Return its tag and CIP.

   procedure Create_Block
     (Line       : aliased in out Input_Position;
      Tag        : Ada.Tags.Tag;
      Containers : in out Container_Vectors.Vector;
      Leaf       : out Abstract_Block_Access);
   --  Create new block with given Tag and consume related characters from Line
   --  If the block is a container block append it to the Containers, otherwise
   --  put it into Leaf.

   procedure Start_Parsing (Self : in out Markdown_Parser'Class);
   procedure Complete_Parsing (Self : in out Markdown_Parser'Class);
   --  Complete parsing and produce Self.Document

   ----------------------
   -- Complete_Parsing --
   ----------------------

   procedure Complete_Parsing (Self : in out Markdown_Parser'Class) is
   begin
      Self.State := Completed;

      Self.Open.First_Element.Complete_Parsing (Self.Inline_Parser);

      Markdown.Documents.Internals.Set
        (Self.Document, Self.Open.First_Element.all);
   end Complete_Parsing;

   ------------------
   -- Create_Block --
   ------------------

   procedure Create_Block
     (Line       : aliased in out Input_Position;
      Tag        : Ada.Tags.Tag;
      Containers : in out Container_Vectors.Vector;
      Leaf       : out Abstract_Block_Access)
   is
      function Constructor is new Ada.Tags.Generic_Dispatching_Constructor
        (Abstract_Block, Input_Position, Create);

      Block  : Abstract_Block_Access;
   begin
      Block := new Abstract_Block'Class'(Constructor (Tag, Line'Access));

      if not Containers.Is_Empty then
         Containers.Last_Element.Children.Append (Block);
      end if;

      if Block.Is_Container then
         Containers.Append (Abstract_Container_Block_Access (Block));
      else
         Leaf := Block;
      end if;
   end Create_Block;

   --------------
   -- Document --
   --------------

   function Document
     (Self : in out Markdown_Parser) return Markdown.Documents.Document is
   begin
      case Self.State is
         when Initial =>
            Self.Start_Parsing;
            Self.Complete_Parsing;
         when Started =>
            Self.Complete_Parsing;
         when Completed =>
            null;
      end case;

      return Self.Document;
   end Document;

   ----------------------
   -- Find_Block_Start --
   ----------------------

   procedure Find_Block_Start
     (Self : Markdown_Parser'Class;
      Line : Input_Position;
      Tag  : out Ada.Tags.Tag;
      CIP  : out Can_Interrupt_Paragraph)
   is
      use type Ada.Tags.Tag;
   begin
      Tag := Ada.Tags.No_Tag;

      for Detector of Self.Block_Detectors loop
         Detector (Line, Tag, CIP);

         exit when Tag /= Ada.Tags.No_Tag;
      end loop;
   end Find_Block_Start;

   ----------------
   -- Parse_Line --
   ----------------

   procedure Parse_Line
     (Self : in out Markdown_Parser'Class;
      Line : VSS.Strings.Virtual_String)
   is
      use type Ada.Tags.Tag;

      Done           : Boolean := False;
      Tag            : Ada.Tags.Tag;
      Open           : Container_Vectors.Vector;
      --  Subset of Self.Open block which are still open after this line
      New_Containers : Container_Vectors.Vector;
      New_Leaf       : Abstract_Block_Access;
      CIP            : Can_Interrupt_Paragraph;
      Expanded_Line  : aliased Input_Line := (Line, Line);
      Input          : aliased Input_Position :=
        (Line  => Expanded_Line'Unchecked_Access,
         First => Expanded_Line.Expanded.At_First_Character);
      Match          : Boolean := False;
   begin
      case Self.State is
         when Initial =>
            Self.Start_Parsing;
         when Completed =>
            return;
         when Started =>
            null;
      end case;

      --  First we iterate through the open container blocks. Each block
      --  imposes a condition that the line must satisfy if the block is to
      --  remain open. For example, a block quote requires a '>' character. We
      --  consume such continuation markers and keep list of such blocks in
      --  Open vector.
      for Block of Self.Open loop
         Block.Consume_Continuation_Markers (Input, Match);

         exit when not Match;

         Open.Append (Block);
      end loop;

      --  Try to find a new block and check if it can interrupt paragraph
      Self.Find_Block_Start (Input, Tag, CIP);

      --  Try to append Input to Self.Open_Leaf if any, taking CIP into account
      if not Match then
         Self.Open_Leaf := null;
      elsif Self.Open_Leaf.Assigned then
         Match := False;
         Self.Open_Leaf.Append_Line (Input, CIP, Match);

         if Match then
            Done := True;
            Tag := Ada.Tags.No_Tag;
         else
            Self.Open_Leaf := null;
         end if;
      end if;

      --  Otherwise create new blocks
      if not Done and Input.First.Has_Element then
         while Tag /= Ada.Tags.No_Tag and not New_Leaf.Assigned loop
            Create_Block (Input, Tag, New_Containers, New_Leaf);
            Self.Find_Block_Start (Input, Tag, CIP);
         end loop;

         Self.Open_Leaf := New_Leaf;
         --  pragma Assert (Blank_Pattern.Find_Match (Input).Is_Matched);
      end if;

      Self.Open.Move (Source => Open);  --  Replace Self.Open with Open

      if New_Leaf.Assigned then
         if New_Containers.Is_Empty then
            Self.Open.Last_Element.Children.Append (New_Leaf);
         end if;
      end if;

      if not New_Containers.Is_Empty then
         Self.Open.Last_Element.Children.Append
           (Abstract_Block_Access (New_Containers.First_Element));
      end if;

      --  Self.Open.Append_Vector (New_Containers);  fails on old compiler
      for Item of New_Containers loop
         Self.Open.Append (Item);
      end loop;
   end Parse_Line;

   --------------------
   -- Register_Block --
   --------------------

   procedure Register_Block
     (Self     : in out Markdown_Parser'Class;
      Detector : Block_Detector) is
   begin
      Self.Block_Detectors.Append (Detector);
   end Register_Block;

   --------------------
   -- Register_Block --
   --------------------

   procedure Register_Block
     (Self     : in out Markdown_Parser'Class;
      Detector : Block_Detector;
      Replace  : Block_Detector)
   is
      Found : constant Block_Detector_Vectors.Cursor :=
        Self.Block_Detectors.Find (Replace);
   begin
      if Block_Detector_Vectors.Has_Element (Found) then
         Self.Block_Detectors (Found) := Detector;
      else
         raise Constraint_Error;
      end if;
   end Register_Block;

   ---------------------------------
   -- Register_Common_Mark_Blocks --
   ---------------------------------

   procedure Register_Common_Mark_Blocks
     (Self : in out Markdown_Parser'Class)
   is
      package MI renames Markdown.Implementation;
   begin
      Self.Register_Block (MI.Thematic_Breaks.Detector'Access);
      Self.Register_Block (MI.ATX_Headings.Detector'Access);
      Self.Register_Block (MI.Indented_Code_Blocks.Detector'Access);
      Self.Register_Block (MI.Fenced_Code_Blocks.Detector'Access);
      Self.Register_Block (MI.HTML_Blocks.Detector'Access);
      Self.Register_Block (MI.List_Items.Detector'Access);
      Self.Register_Block (MI.Quotes.Detector'Access);
      Self.Register_Block (MI.Paragraphs.Detector'Access);

      Self.Inline_Parser.Register
        (Markdown.Implementation.Code_Spans.Parse_Code_Span'Access);
      Self.Inline_Parser.Register
        (Markdown.Implementation.Auto_Links.Parse_Auto_Link'Access);
   end Register_Common_Mark_Blocks;

   -------------------
   -- Start_Parsing --
   -------------------

   procedure Start_Parsing (Self : in out Markdown_Parser'Class) is
      Root_Block : constant Abstract_Container_Block_Access :=
        new Markdown.Implementation.Documents.Document;
   begin
      Self.State := Started;

      if Self.Block_Detectors.Is_Empty then
         Self.Register_Common_Mark_Blocks;
      end if;

      Self.Open.Append (Root_Block);
   end Start_Parsing;

end Markdown.Parsers;
