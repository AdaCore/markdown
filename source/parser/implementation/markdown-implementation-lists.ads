--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

--  Internal representation of a markdown list

package Markdown.Implementation.Lists is

   pragma Preelaborate;

   type List is new Abstract_Container_Block with private;
   --  The List is a node for markdown list representation

   type List_Access is access all List;

   function Is_Ordered (Self : List'Class) return Boolean;
   --  Return True if list has an ordered list markers.

   function Start (Self : List'Class) return Natural
     with Pre => Self.Is_Ordered;
   --  An integer to start counting from for the list items.

   function Match
     (Self : List'Class;
      Item : Abstract_Block_Access) return Boolean;

private
   type List is new Abstract_Container_Block with record
      null;
   end record;

   overriding function Create (Input : not null access Input_Position)
     return List is (raise Program_Error with "Unexpected Create");
   --  List isn't expected to be created with the Create function

   overriding procedure Consume_Continuation_Markers
     (Self  : in out List;
      Input : in out Input_Position;
      Ok    : out Boolean) is null;
   --  List doesn't participate in the parsing. It's created in an extra pass
   --  over parsed structure at the latest stage.

end Markdown.Implementation.Lists;
