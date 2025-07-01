--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Strings.Character_Iterators;
with VSS.Regular_Expressions;

with Markdown.Implementation.HTML;

package body Markdown.Attribute_Lists is

   package HTML renames Markdown.Implementation.HTML;

   Attribute_Value : constant Wide_Wide_String :=
     "(" & HTML.Unquoted_Attribute_Value & ")|" &  --  2 group
     "'([^']*)'" &  --  3 group is Single_Quoted_Attribute_Value
     """([^""]*)""";  --  4 group is Double_Quoted_Attribute_Value

   Attribute_Value_Spec : constant Wide_Wide_String :=
     "[ \t]*=[ \t]*(?:" & Attribute_Value & ")";

   Attribute_Pattern : constant Wide_Wide_String :=
     "\s*([.#]?" & HTML.Attribute_Name & ")(?:" & Attribute_Value_Spec & ")?";
   --  1 group is Attribute_Name

   Pattern : VSS.Regular_Expressions.Regular_Expression;

   -----------
   -- Parse --
   -----------

   procedure Parse
     (Self : in out Attribute_List'Class;
      Text : VSS.Strings.Virtual_String)
   is
      Cursor : VSS.Strings.Character_Iterators.Character_Iterator :=
        Text.Before_First_Character;
   begin
      if not Pattern.Is_Valid then
         Pattern :=
           VSS.Regular_Expressions.To_Regular_Expression
             (VSS.Strings.To_Virtual_String (Attribute_Pattern));
      end if;

      Self.Text := Text;

      while Cursor.Forward loop
         declare
            Match : constant
              VSS.Regular_Expressions.Regular_Expression_Match :=
                Pattern.Match (Text, Cursor);
         begin
            exit when not Match.Has_Match;

            declare
               Item : Attribute :=
                 (Name  => Match.Captured (1),
                  Value => <>);
            begin
               if Match.Has_Capture (4) then
                  Item.Value := Match.Captured (4);
               elsif Match.Has_Capture (3) then
                  Item.Value := Match.Captured (3);
               elsif Match.Has_Capture (2) then
                  Item.Value := Match.Captured (2);
               elsif Item.Name.Starts_With ("#") then
                  Item.Value := Item.Name;
                  Item.Name := "id";
               elsif Item.Name.Starts_With (".") then
                  Item.Value := Item.Name.Tail_After
                    (Item.Name.At_First_Character);

                  Item.Name := "class";
               end if;

               Self.List.Append (Item);
               Cursor.Set_At (Match.Last_Marker);
            end;
         end;
      end loop;
   end Parse;

end Markdown.Attribute_Lists;
