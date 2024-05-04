--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Characters;

with Markdown.Implementation.List_Items;

package body Markdown.Implementation.Lists is

   --------------
   -- Is_Loose --
   --------------

   function Is_Loose (Self : List'Class) return Boolean is
      Ends_Blank : Boolean := False;
      Result     : Boolean := False;
   begin
      for Child of Self.Children loop
         declare
            Item : Markdown.Implementation.List_Items.List_Item renames
              Markdown.Implementation.List_Items.List_Item (Child.all);
         begin
            Result := Item.Has_Blank_Line or Ends_Blank;
            Ends_Blank := Item.Ends_With_Blank_Line;

            exit when Result;
         end;
      end loop;

      return Result;
   end Is_Loose;

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
