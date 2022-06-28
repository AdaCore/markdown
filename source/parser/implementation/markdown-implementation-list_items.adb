--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Regular_Expressions;
with VSS.Strings.Conversions;
with VSS.Strings.Cursors;

package body Markdown.Implementation.List_Items is

   Bullet_List_Marker : constant Wide_Wide_String := "[-+*]";

   Ordered_List_Marker : constant Wide_Wide_String := "([0-9][0-9]*)[.)]";

   Marker_Pattern : constant Wide_Wide_String :=
     "^(?:   |  | |)(" &          --  1 group (after spaces)
     Bullet_List_Marker & "|" &
     Ordered_List_Marker & ")" &  --  2 group (inside Ordered_List_Marker)
     "( *)";                      --  3 group (after the marker)

   Prefix : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Marker_Pattern

   Indent_1 : VSS.Regular_Expressions.Regular_Expression;
   --  One or more spaces at the beginning of a string: "^ +"

   ----------------------------------
   -- Consume_Continuation_Markers --
   ----------------------------------

   overriding procedure Consume_Continuation_Markers
     (Self  : in out List_Item;
      Input : in out Input_Position;
      Ok    : out Boolean)
   is
      use type VSS.Strings.Character_Count;

      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Indent_1.Match (Input.Line.Expanded, Input.First);
   begin
      Ok := Match.Has_Match and then
        Match.Marker.Character_Length >= Self.Marker_Width;

      if Ok then
         --  We have enough spaces at the beginning, consume them
         Self.Has_Blank_Line := Self.Has_Blank_Line
           or Self.Ends_With_Blank_Line;

         Self.Ends_With_Blank_Line := False;

         Forward (Input.First, Self.Marker_Width);
      elsif not Input.First.Has_Element then
         --  We have characters, treat it as an empty line
         Ok := not
           (Self.Ends_With_Blank_Line
             and Self.Starts_With_Blank_Line
             and not Self.First_Line);

         if Ok then
            Self.Ends_With_Blank_Line := True;
         end if;
      end if;

      Self.First_Line := False;
   end Consume_Continuation_Markers;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return List_Item
   is
      use type VSS.Strings.Character_Count;

      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Prefix.Match (Input.Line.Expanded, Input.First);

      Suffix : constant VSS.Strings.Virtual_String := Match.Captured (3);
   begin
      return Result : List_Item do
         Result.Marker := Match.Captured (1);

         if Suffix.Character_Length <= 4 and then
           Match.Last_Marker.Character_Index
             = Input.Line.Expanded.Character_Length
         then
            --  Empty line marker: ^\ {0,3}(Marker)(\ {0,4}$).
            Result.Marker_Width := Result.Marker.Character_Length + 1;
            Result.First_Line := True;
            Result.Starts_With_Blank_Line := True;
            --  Shift Input.First to end-of-line
            Input.First.Set_After_Last (Input.Line.Expanded);

         elsif Suffix.Character_Length > 4 then
            --  Indented code in the list item

            Result.Marker_Width := Result.Marker.Character_Length + 1;

            Input.First.Set_At (Match.Last_Marker (1));
            --  Skip 1 space after marker
            Forward (Input.First, 2);

         else

            Result.Marker_Width := Result.Marker.Character_Length +
              Suffix.Character_Length;
            --  Skip marker and all spaces if any
            Input.First.Set_At (Match.Last_Marker);
            Forward (Input.First);
         end if;
      end return;
   end Create;

   --------------
   -- Detector --
   --------------

   procedure Detector
     (Input : Input_Position;
      Tag   : in out Ada.Tags.Tag;
      CIP   : out Can_Interrupt_Paragraph)
   is
      use type VSS.Strings.Character_Count;

      Suffix : VSS.Strings.Virtual_String;
      Number : Natural;
      Match  : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      if not Prefix.Is_Valid then  --  Construct Prefix regexp
         Prefix := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Marker_Pattern));
      end if;

      if not Indent_1.Is_Valid then  --  Construct Indent_1 regexp
         Indent_1 := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String ("^  *"));  --  XXX: Fix with "^ +"
      end if;

      CIP := True;  --  Suppress a warning about uninitialized parameter
      Match := Prefix.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match then
         Suffix := Match.Captured (3);

         if Suffix.Character_Length > 10 then
            --  no more than 9 digits in the marker are allowed
            return;
         end if;

         Tag := List_Item'Tag;

         Number :=
           (if Match.Marker (2).Is_Valid then
            Natural'Wide_Wide_Value
              (VSS.Strings.Conversions.To_Wide_Wide_String
                (Match.Captured (2)))
            else 0);

         --  Calculate Can_Interrupt_Paragraph
         CIP :=
           (if Suffix.Character_Length <= 4 and then
              Match.Last_Marker.Character_Index
                = Input.Line.Expanded.Character_Length
            then
               --  Empty line marker: ^\ {0,3}(Marker)(\ {0,4}$).
               --  An empty list item cannot interrupt a paragraph.
               False
            elsif Match.Marker (2).Is_Valid then
               --  Check if numbered item is `1`

               Number = 1
            else

              True);
      end if;
   end Detector;

end Markdown.Implementation.List_Items;
