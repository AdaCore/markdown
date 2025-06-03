--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Simple inline elements (like code spans, auto links, raw html, etc) contain
--  no nested elements and all have the same priority (are processed in
--  left-to-right order).

with Ada.Containers.Vectors;

with VSS.Strings.Cursors;
with VSS.Strings.Cursors.Markers;

with Markdown.Inlines;

package Markdown.Simple_Inline_Parsers is
   pragma Preelaborate;

   type Inline_Span (Is_Set : Boolean := False) is record
      case Is_Set is
         when True =>
            From, To   : VSS.Strings.Cursors.Markers.Character_Marker;
            --  Markers in the original Text

            Annotation : Markdown.Inlines.Annotated_Text;

         when False =>
            null;
      end case;
   end record;

   type Inline_Span_Wrapper is record
      Item : Inline_Span;
   end record;
   --  To be able to update an element of a vector through implicit reference.

   type Simple_Inline_Parser_Access is access procedure
     (Text : VSS.Strings.Virtual_String;
      From : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Span : out Inline_Span);
   --  Find next inline element in Text staring From given position. Return
   --  `Is_Set => False` if not found.

   package Simple_Parser_Vectors is new Ada.Containers.Vectors
     (Positive, Simple_Inline_Parser_Access);

   package Inline_Span_Vectors is new Ada.Containers.Vectors
     (Positive, Inline_Span_Wrapper);

   procedure Initialize
     (Parsers : Simple_Parser_Vectors.Vector;
      Text    : VSS.Strings.Virtual_String;
      From    : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      State   : out Inline_Span_Vectors.Vector)
        with Post => Parsers.Last_Index = State.Last_Index;
   --  For each parser find the very first occurrence in the Text and put it
   --  into State (with corresponding index).

   procedure Get_Next_Inline
     (Parsers : Simple_Parser_Vectors.Vector;
      Text    : VSS.Strings.Virtual_String;
      State   : in out Inline_Span_Vectors.Vector;
      Value   : out Inline_Span)
        with
           Pre  => Parsers.Last_Index = State.Last_Index,
           Post => Parsers.Last_Index = State.Last_Index;
   --  Find next simple inline in the Text and return it in Value. Return
   --  `Value => (Is_Set => False)` if no more simple inline elements in the
   --  Text. Update State vector as needed.

end Markdown.Simple_Inline_Parsers;
