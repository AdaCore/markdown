--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Implementation is

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

end Markdown.Implementation;
