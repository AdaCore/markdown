--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Emphasis and links delimiters with a parsing routine

with Ada.Containers.Vectors;

with VSS.Strings.Character_Iterators;
with VSS.Strings.Cursors.Markers;
with VSS.Regular_Expressions;

private
package Markdown.Emphasis_Delimiters is
   pragma Preelaborate;

   type Delimiter_Kind is ('*', '_', '[', ']', '!');
   --  A kind of delimiters used in emphasis, links or images. '!' means `![`.

   subtype Emphasis_Kind is Delimiter_Kind range '*' .. '_';

   type Delimiter (Kind : Delimiter_Kind := '*') is record
      From       : VSS.Strings.Cursors.Markers.Character_Marker;
      --  Where the delimiter starts
      Is_Deleted : Boolean := False;  --  Marker for ignorance

      case Kind is
         when Emphasis_Kind =>
            Count     : VSS.Strings.Character_Index;  --  number of stars, etc
            Is_Active : Boolean;
            Can_Open  : Boolean;
            Can_Close : Boolean;
         when '[' | '!' =>
            null;
         when ']' =>
            To : VSS.Strings.Cursors.Markers.Character_Marker;
      end case;
   end record;
   --  A delimiter used in emphasis or links

   type Scanner is tagged limited private;
   --  A delimiter scanner

   procedure Read_Delimiter
     (Self   : in out Scanner;
      Text   : VSS.Strings.Virtual_String;
      Cursor : in out VSS.Strings.Character_Iterators.Character_Iterator;
      Item   : out Delimiter;
      Found  : out Boolean)
        with Inline;
   --  Scan input Text starting from a position pointed by the Cursor and
   --  check for a delimiter run.
   --
   --  For emphasis a delimiter run is either a sequence of one or more `*`
   --  characters that is not preceded or followed by a non-backslash-escaped
   --  `*` character, or a sequence of one or more `_` characters that is not
   --  preceded or followed by a non-backslash-escaped `_` character.
   --
   --  For a link, a delimiter run is just `[` or `]` characters.
   --  For an image, a delimiter run is just `![` string or `]` character.
   --
   --  Return `Found = True` and Item if the delimiter is found.
   --  Move Cursor after delimiter or forward one character if not found.

   procedure Reset (Self : in out Scanner);
   --  Reset the scanner to an initial state

   type Delimiter_Filter_Kind is
     (Any_Element,
      Kind_Of,
      Link_Or_Image,
      Emphasis_Close,
      Emphasis_Open);

   type Delimiter_Filter (Kind : Delimiter_Filter_Kind := Any_Element) is
      record
         case Kind is
            when Any_Element | Emphasis_Close | Link_Or_Image =>
               null;
            when Kind_Of =>
               Given_Kind : Delimiter_Kind;
            when Emphasis_Open =>
               Emphasis   : Emphasis_Kind;
         end case;
      end record;

   subtype Delimiter_Index is Positive;

   package Delimiter_Vectors is new Ada.Containers.Vectors
     (Delimiter_Index, Delimiter);

   subtype Extended_Delimiter_Index is Delimiter_Vectors.Extended_Index;

   function Each
     (Self   : aliased Delimiter_Vectors.Vector;
      Filter : Delimiter_Filter := (Kind => Any_Element);
      From   : Delimiter_Index := 1;
      To     : Extended_Delimiter_Index := Extended_Delimiter_Index'Last)
        return Delimiter_Vectors.Vector_Iterator_Interfaces
          .Reversible_Iterator'Class;
   --  Iterate in a given range From .. To filtering elements according to
   --  Filter.

private

   type Scanner_State is record
      Is_White_Space : Boolean := True;
      Is_Punctuation : Boolean := False;
      Is_Exclamation : Boolean := False;
   end record;

   type Scanner is tagged limited record
      State   : Scanner_State;
      Pattern : VSS.Regular_Expressions.Regular_Expression;
   end record;

end Markdown.Emphasis_Delimiters;
