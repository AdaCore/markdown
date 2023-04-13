--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Strings.Character_Iterators;

with Markdown.Implementation;

package body Markdown.Simple_Inline_Parsers is

   ---------------------
   -- Get_Next_Inline --
   ---------------------

   procedure Get_Next_Inline
     (Parsers : Simple_Parser_Vectors.Vector;
      Text    : VSS.Strings.Virtual_String;
      State   : in out Inline_Span_Vectors.Vector;
      Value   : out Inline_Span)
   is
      use Markdown.Implementation;
   begin
      Value := (Is_Set => False);

      --  Assign leftmost item in State to Value
      for Item of State loop
         if Item.Element.Is_Set then
            if not Value.Is_Set or else Item.Element.From < Value.From then
               Value := Item.Element;
            end if;
         end if;
      end loop;

      if Value.Is_Set then
         --  Update state
         declare
            Cursor : VSS.Strings.Character_Iterators.Character_Iterator;
         begin
            Cursor.Set_At (Value.To);
            Markdown.Implementation.Forward (Cursor, 1);

            for Index in Parsers.First_Index .. Parsers.Last_Index loop
               if State (Index).Element.Is_Set and then
                 VSS.Strings.Cursors.Abstract_Character_Cursor'Class
                   (State (Index).Element.From) < Cursor
               then
                  if Cursor.Has_Element then
                     Parsers (Index).all
                       (Text, Cursor, State (Index).Element);
                  else
                     State (Index).Element := (Is_Set => False);
                  end if;
               end if;
            end loop;
         end;
      end if;
   end Get_Next_Inline;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Parsers : Simple_Parser_Vectors.Vector;
      Text    : VSS.Strings.Virtual_String;
      From    : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      State   : out Inline_Span_Vectors.Vector)
   is
   begin
      State := Inline_Span_Vectors.To_Vector
        ((Element => <>), Parsers.Length);

      for Index in Parsers.First_Index .. Parsers.Last_Index loop
         Parsers (Index).all (Text, From, State (Index).Element);
      end loop;
   end Initialize;

end Markdown.Simple_Inline_Parsers;
