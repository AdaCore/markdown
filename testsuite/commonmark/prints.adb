--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with VSS.Characters;
with VSS.String_Vectors;
with VSS.Strings;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Cursors.Markers;
--  with VSS.Strings.Character_Iterators;

with Markdown.Blocks.ATX_Headings;
with Markdown.Blocks.Fenced_Code;
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Paragraphs;
pragma Warnings (Off, "is not referenced");
with Markdown.Blocks.Quotes;
pragma Warnings (On, "is not referenced");

package body Prints is
   pragma Assertion_Policy (Check);

   Tag : constant array
     (Markdown.Annotations.Emphasis .. Markdown.Annotations.Strong)
       of VSS.Strings.Virtual_String := ("em", "strong");

   procedure Print_Annotated_Text
     (Writer : in out HTML_Writers.Writer;
      Text   : Markdown.Annotations.Annotated_Text)
   is
      use type VSS.Strings.Character_Count;

      procedure Print
        (From  : in out Positive;
         Next  : in out VSS.Strings.Character_Iterators.Character_Iterator;
         Limit : VSS.Strings.Character_Count);
      --  From is an index in Text.Annotation to start from
      --  Next is a not printed yet character in Text.Plain_Text
      --  Dont go after Limit position in Text.Plain_Text

      -----------
      -- Print --
      -----------

      procedure Print
        (From  : in out Positive;
         Next  : in out VSS.Strings.Character_Iterators.Character_Iterator;
         Limit : VSS.Strings.Character_Count)
      is
         function Before
           (From : VSS.Strings.Character_Index)
              return VSS.Strings.Character_Iterators.Character_Iterator;

         ------------
         -- Before --
         ------------

         function Before
           (From : VSS.Strings.Character_Index)
            return VSS.Strings.Character_Iterators.Character_Iterator
         is
            Ignore : Boolean;
         begin
            return Iter : VSS.Strings.Character_Iterators.Character_Iterator do
               Iter.Set_At (Next);

               while Iter.Character_Index >= From and then Iter.Backward loop
                  null;
               end loop;

               while Iter.Character_Index + 1 < From and then Iter.Forward loop
                  null;
               end loop;
            end return;
         end Before;

         Ignore : Boolean;
      begin
         while From <= Text.Annotation.Last_Index and then
           Text.Annotation (From).To <= Limit
         loop
            declare
               Item : constant Markdown.Annotations.Annotation :=
                 Text.Annotation (From);
               Last : constant
                 VSS.Strings.Character_Iterators.Character_Iterator :=
                   Before (Item.From);
            begin
               From := From + 1;

               Writer.Characters
                 (Text.Plain_Text.Slice (Next, Last));

               Next.Set_At (Last);
               Ignore := Next.Forward;

               case Item.Kind is
                  when Markdown.Annotations.Emphasis
                     | Markdown.Annotations.Strong
                     =>

                     Writer.Start_Element (Tag (Item.Kind));
                     Print (From, Next, Item.To);
                     Writer.End_Element (Tag (Item.Kind));

                  when Markdown.Annotations.Code_Span =>
                     Writer.Start_Element ("code");
                     Print (From, Next, Item.To);
                     Writer.End_Element ("code");

                  when Markdown.Annotations.Link =>
                     declare
                        Attr : HTML_Writers.HTML_Attributes;
                     begin
                        Attr.Append (("href", Item.Destination));

                        if not Item.Title.Is_Empty then
                           Attr.Append
                             (("title",
                              Item.Title.Join_Lines (VSS.Strings.LF, False)));
                        end if;

                        Writer.Start_Element ("a", Attr);
                        Print (From, Next, Item.To);
                        Writer.End_Element ("a");
                     end;

                  when others =>
                     null;
               end case;
            end;
         end loop;

         if Next.Character_Index <= Limit then
            declare
               Last : constant
                 VSS.Strings.Character_Iterators.Character_Iterator :=
                   Before (Limit + 1);
            begin
               Writer.Characters (Text.Plain_Text.Slice (Next, Last));

               Next.Set_At (Last);
               Ignore := Next.Forward;
            end;
         end if;
      end Print;

      From  : Positive := Text.Annotation.First_Index;
      Next  : VSS.Strings.Character_Iterators.Character_Iterator :=
        Text.Plain_Text.At_First_Character;
   begin
      Print
        (From  => From,
         Next  => Next,
         Limit => Text.Plain_Text.Character_Length);
   end Print_Annotated_Text;

   -----------------
   -- Print_Block --
   -----------------

   procedure Print_Block
     (Writer : in out HTML_Writers.Writer;
      Block  : Markdown.Blocks.Block)
   is
      New_Line : VSS.Strings.Virtual_String;
   begin
      New_Line.Append (VSS.Characters.Virtual_Character'Val (10));

      if Block.Is_Paragraph then
         Writer.Start_Element ("p");
         Print_Annotated_Text (Writer, Block.To_Paragraph.Text);
         Writer.End_Element ("p");

      elsif Block.Is_Thematic_Break then
         Writer.Start_Element ("hr");
         Writer.End_Element ("hr");

      elsif Block.Is_ATX_Heading then
         declare
            Image : Wide_Wide_String :=
              Block.To_ATX_Heading.Level'Wide_Wide_Image;
         begin
            Image (1) := 'h';
            Writer.Start_Element (VSS.Strings.To_Virtual_String (Image));
            Print_Annotated_Text (Writer, Block.To_ATX_Heading.Text);
            Writer.End_Element (VSS.Strings.To_Virtual_String (Image));
         end;

      elsif Block.Is_Quote then
         Writer.Start_Element ("blockquote");
         Print_Blocks (Writer, Block.To_Quote);
         Writer.End_Element ("blockquote");

      elsif Block.Is_Fenced_Code_Block then
         declare
            Info : constant VSS.Strings.Virtual_String :=
              Block.To_Fenced_Code_Block.Info_String;

            List : constant VSS.String_Vectors.Virtual_String_Vector :=
              Info.Split (' ');

            Attr : HTML_Writers.HTML_Attributes;
         begin
            if not Info.Is_Empty then
               Attr.Append (("class", List (1)));
            end if;

            Writer.Start_Element ("pre");
            Writer.Start_Element ("code", Attr);

            for Line of Block.To_Fenced_Code_Block.Text loop
               Writer.Characters (Line);
               Writer.Characters (New_Line);
            end loop;

            Writer.End_Element ("code");
            Writer.End_Element ("pre");
         end;

      elsif Block.Is_Indented_Code_Block then
         Writer.Start_Element ("pre");
         Writer.Start_Element ("code");

         for Line of Block.To_Indented_Code_Block.Text loop
            Writer.Characters (Line);
            Writer.Characters (New_Line);
         end loop;

         Writer.End_Element ("code");
         Writer.End_Element ("pre");

      elsif Block.Is_List then
         Print_List (Writer, Block.To_List);
      else
         raise Program_Error;
      end if;
   end Print_Block;

   procedure Print_Blocks
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Block_Containers.Block_Container'Class) is
   begin
      for Block of List loop
         Print_Block (Writer, Block);
      end loop;
   end Print_Blocks;

   procedure Print_List
     (Writer : in out HTML_Writers.Writer;
      List   : Markdown.Blocks.Lists.List)
   is
      Tag : constant VSS.Strings.Virtual_String :=
        VSS.Strings.To_Virtual_String
          (if List.Is_Ordered then "ol" else "ul");

      Attr : HTML_Writers.HTML_Attributes;
   begin
      if List.Is_Ordered then
         declare
            Image : constant Wide_Wide_String := List.Start'Wide_Wide_Image;
         begin
            if Image /= " 1" then
               Attr.Append
                 (("start",
                   VSS.Strings.To_Virtual_String (Image (2 .. Image'Last))));
            end if;
         end;
      end if;

      Writer.Start_Element (Tag, Attr);

      for Item of List loop
         Writer.Start_Element ("li");
         Print_Blocks (Writer, Item);
         Writer.End_Element ("li");
      end loop;

      Writer.End_Element (Tag);
   end Print_List;

end Prints;
