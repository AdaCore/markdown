--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal representation of a markdown list item

package Markdown.Implementation.List_Items is

   pragma Preelaborate;

   type List_Item is new Abstract_Container_Block with private;
   --  The List_Item is a node for markdown list item representation

   type List_Item_Access is access all List_Item;

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a list item

   function Is_Ordered (Self : List_Item'Class) return Boolean;
   --  Return True if list item has an ordered list marker.

   function Marker (Self : List_Item'Class) return VSS.Strings.Virtual_String;
   --  List item marker as a string

   function Marker (Self : List_Item'Class) return Natural
     with Pre => Self.Is_Ordered;
   --  List item marker as an integer

   function Has_Blank_Line (Self : List_Item'Class) return Boolean;
   function Ends_With_Blank_Line (Self : List_Item'Class) return Boolean;

   procedure Initialize;
   --  Prepare regexp patterns

private
   type List_Item is new Abstract_Container_Block with record
      Is_Ordered             : Boolean;
      Marker                 : VSS.Strings.Virtual_String;
      --  Marker it-self, like `-`, `11.`, etc.
      Marker_Value           : Natural;  --  Marker value if ordered, like 11
      Marker_Width           : VSS.Strings.Character_Count;
      --  Number of spaces to skip in subsequent lines
      Starts_With_Blank_Line : Boolean := False;
      --  The item starts with an empty line
      Ends_With_Blank_Line   : Boolean := False;
      --  The last known line of the item was empty
      Has_Blank_Line         : Boolean := False;
      --  The item has at least one empty line (excluding line with the marker)
      First_Line             : Boolean := False;
      --  This is true only for the line with the marker
   end record;

   overriding function Create (Input : not null access Input_Position)
     return List_Item;

   overriding procedure Consume_Continuation_Markers
     (Self  : in out List_Item;
      Input : in out Input_Position;
      Ok    : out Boolean);

   function Has_Blank_Line (Self : List_Item'Class) return Boolean is
     (Self.Has_Blank_Line);

   function Ends_With_Blank_Line (Self : List_Item'Class) return Boolean is
     (Self.Ends_With_Blank_Line);
end Markdown.Implementation.List_Items;
