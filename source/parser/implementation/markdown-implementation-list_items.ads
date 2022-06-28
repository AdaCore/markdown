--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a markdown list item

package Markdown.Implementation.List_Items is

   pragma Preelaborate;

   type List_Item is new Abstract_Container_Block with private;
   --  The List_Item is a node for markdown list item representation

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph);
   --  The detector procedure to find start of a list item

private
   type List_Item is new Abstract_Container_Block with record
      Marker                 : VSS.Strings.Virtual_String;
      Marker_Width           : VSS.Strings.Character_Count;
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

end Markdown.Implementation.List_Items;
