--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Characters;

with Markdown.Implementation.List_Items;

package body Markdown.Implementation.Lists is

   ----------------
   -- Is_Ordered --
   ----------------

   function Is_Ordered (Self : List'Class) return Boolean is
      First : Markdown.Implementation.List_Items.List_Item renames
        Markdown.Implementation.List_Items.List_Item
          (Self.Children.First_Element.all);

   begin
      return First.Is_Ordered;
   end Is_Ordered;

   -----------
   -- Match --
   -----------

   function Match
     (Self : List'Class;
      Item : Abstract_Block_Access) return Boolean
   is
      use type VSS.Characters.Virtual_Character;

      First : Markdown.Implementation.List_Items.List_Item renames
        Markdown.Implementation.List_Items.List_Item
          (Self.Children.First_Element.all);

      Next : Markdown.Implementation.List_Items.List_Item renames
        Markdown.Implementation.List_Items.List_Item (Item.all);

      First_Marker  : constant VSS.Strings.Virtual_String := First.Marker;
      Next_Marker : constant VSS.Strings.Virtual_String := Next.Marker;
   begin
      return First_Marker.At_Last_Character.Element =
        Next_Marker.At_Last_Character.Element;
   end Match;

   -----------
   -- Start --
   -----------

   function Start (Self : List'Class) return Natural is
      First : Markdown.Implementation.List_Items.List_Item renames
        Markdown.Implementation.List_Items.List_Item
          (Self.Children.First_Element.all);

   begin
      return First.Marker;
   end Start;

end Markdown.Implementation.Lists;
