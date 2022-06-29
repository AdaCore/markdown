--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with Markdown.Implementation.Lists;
with Markdown.Implementation.List_Items;

package body Markdown.Implementation is

   -------------
   -- Forward --
   -------------

   procedure Forward
     (Cursor : in out VSS.Strings.Character_Iterators.Character_Iterator;
      Count  : VSS.Strings.Character_Index := 1)
   is
      use type VSS.Strings.Character_Index;
   begin
      for J in 1 .. Count loop
         declare
            Ok : constant Boolean := Cursor.Forward or J = Count;
         begin
            pragma Assert (Ok);
         end;
      end loop;
   end Forward;

   ---------------
   -- Reference --
   ---------------

   procedure Reference (Self : Abstract_Block_Access) is
   begin
      if Self.Assigned then
         System.Atomic_Counters.Increment (Self.Counter);
      end if;
   end Reference;

   ---------------
   -- Reference --
   ---------------

   procedure Reference (Self : Abstract_Container_Block_Access) is
   begin
      if Self.Assigned then
         System.Atomic_Counters.Increment (Self.Counter);
      end if;
   end Reference;

   ---------------------
   -- Unexpanded_Tail --
   ---------------------

   function Unexpanded_Tail
     (Self : Input_Line;
      From : VSS.Strings.Character_Iterators.Character_Iterator)
        return VSS.Strings.Virtual_String
   is
      use type VSS.Strings.Virtual_String;
   begin
      if Self.Text = Self.Expanded then
         return Self.Expanded.Slice (From, Self.Expanded.At_Last_Character);
      else
         raise Program_Error with "Unimplemented";
      end if;
   end Unexpanded_Tail;

   -----------------
   -- Unreference --
   -----------------

   procedure Unreference (Self : in out Abstract_Container_Block_Access) is
      procedure Free is new Ada.Unchecked_Deallocation
        (Markdown.Implementation.Abstract_Container_Block'Class,
         Abstract_Container_Block_Access);
   begin
      if not Self.Assigned then
         null;
      elsif System.Atomic_Counters.Decrement (Self.Counter) then

         for Item of Self.Children loop
            if System.Atomic_Counters.Decrement (Item.Counter) then
               Markdown.Implementation.Free (Item);
            end if;
         end loop;

         Free (Self);

      else
         Self := null;
      end if;
   end Unreference;

   ---------------------
   -- Wrap_List_Items --
   ---------------------

   procedure Wrap_List_Items (Self : in out Abstract_Container_Block'Class) is
      use type Markdown.Implementation.Lists.List_Access;

      Found  : Boolean := False;
      Result : Block_Vectors.Vector;
      List   : Markdown.Implementation.Lists.List_Access;
   begin
      for Item of Self.Children loop
         if Item.all in Abstract_Container_Block'Class then
            Abstract_Container_Block'Class (Item.all).Wrap_List_Items;
         end if;

         if Item.all in Markdown.Implementation.List_Items.List_Item then
            if List = null or else not List.Match (Item) then
               List := new Markdown.Implementation.Lists.List;
               Result.Append (Abstract_Block_Access (List));
               Found := True;
            end if;

            List.Children.Append (Item);
         else
            List := null;
            Result.Append (Item);
         end if;
      end loop;

      if Found then
         Self.Children.Move (Source => Result);
      end if;
   end Wrap_List_Items;

end Markdown.Implementation;
