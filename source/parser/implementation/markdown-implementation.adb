--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Implementation is

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

end Markdown.Implementation;
