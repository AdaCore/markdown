--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Characters;
with VSS.String_Vectors;
with VSS.Strings;
with VSS.Strings.Cursors.Markers;
--  with VSS.Strings.Character_Iterators;

with Markdown.Blocks.ATX_Headings;
with Markdown.Blocks.Fenced_Code;
with Markdown.Blocks.HTML;
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Paragraphs;
with Markdown.Blocks.Tables;
pragma Warnings (Off, "is not referenced");
with Markdown.Blocks.Quotes;
pragma Warnings (On, "is not referenced");

package body Prints is
   pragma Assertion_Policy (Check);

   Tag : constant array
     (Markdown.Inlines.Start_Emphasis .. Markdown.Inlines.End_Strong)
       of VSS.Strings.Virtual_String := ["em", "em", "strong", "strong"];

   Left : constant HTML_Writers.HTML_Attribute_Lists.List :=
     [("align", "left")];

   Right : constant HTML_Writers.HTML_Attribute_Lists.List :=
     [("align", "right")];

   Center : constant HTML_Writers.HTML_Attribute_Lists.List :=
     [("align", "center")];

   Cell_Allign : constant array (Markdown.Blocks.Tables.Column_Alignment) of
     HTML_Writers.HTML_Attributes :=
       [HTML_Writers.No_Attributes,
        (Left with null record),
        (Right with null record),
        (Center with null record)];

   procedure Print_Table
     (Writer : in out HTML_Writers.Writer;
      Table  : Markdown.Blocks.Tables.Table);

   procedure Print_Annotated_Text
     (Writer : in out HTML_Writers.Writer;
      Text   : Markdown.Inlines.Annotated_Text)
   is
      type Print_State (In_Image : Boolean := False) is record
         case In_Image is
            when True =>
               Destination : VSS.Strings.Virtual_String;
               Title       : VSS.String_Vectors.Virtual_String_Vector;
               Description : VSS.Strings.Virtual_String;
            when False =>
               null;
         end case;
      end record;

      procedure Print
        (State : in out Print_State;
         Item  : Markdown.Inlines.Annotation);

      -----------
      -- Print --
      -----------

      procedure Print
        (State : in out Print_State;
         Item  : Markdown.Inlines.Annotation) is
      begin
         if State.In_Image then
            case Item.Kind is
               when Markdown.Inlines.Text | Markdown.Inlines.Code_Span =>
                  State.Description.Append (Item.Text);

               when Markdown.Inlines.End_Image =>
                  declare
                     Attr : HTML_Writers.HTML_Attributes;
                  begin
                     Attr.Append (("alt", State.Description));
                     Attr.Append (("src", State.Destination));

                     if not State.Title.Is_Empty then
                        Attr.Append
                          (("title",
                           State.Title.Join_Lines (VSS.Strings.LF, False)));
                     end if;

                     Writer.Start_Element ("img", Attr);
                     Writer.End_Element ("img");

                     State := (In_Image => False);
                  end;

               when others =>
                  null;
            end case;

            return;
         end if;

         case Item.Kind is
            when Markdown.Inlines.Text =>
               Writer.Characters (Item.Text);

            when Markdown.Inlines.Start_Emphasis
               | Markdown.Inlines.Start_Strong
               =>

               Writer.Start_Element (Tag (Item.Kind));

            when Markdown.Inlines.End_Emphasis
               | Markdown.Inlines.End_Strong
               =>
               Writer.End_Element (Tag (Item.Kind));

            when Markdown.Inlines.Code_Span =>
               Writer.Start_Element ("code");
               Writer.Characters (Item.Code_Span);
               Writer.End_Element ("code");

            when Markdown.Inlines.Start_Link =>
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
               end;

            when Markdown.Inlines.End_Link =>
               Writer.End_Element ("a");

            when Markdown.Inlines.Start_Image =>
               State :=
                 (In_Image    => True,
                  Destination => Item.Destination,
                  Title       => Item.Title,
                  Description => <>);

            when Markdown.Inlines.End_Image =>
               null;

            when others =>
               null;
         end case;

      end Print;

      State : Print_State;
   begin
      for Item of Text loop
         Print (State, Item);
      end loop;
   end Print_Annotated_Text;

   -----------------
   -- Print_Block --
   -----------------

   procedure Print_Block
     (Writer   : in out HTML_Writers.Writer;
      Block    : Markdown.Blocks.Block;
      Is_Tight : Boolean)
   is
      New_Line : VSS.Strings.Virtual_String;
   begin
      New_Line.Append (VSS.Characters.Virtual_Character'Val (10));

      if Block.Is_Paragraph then
         if Is_Tight then
            Print_Annotated_Text (Writer, Block.To_Paragraph.Text);
         else
            Writer.Start_Element ("p");
            Print_Annotated_Text (Writer, Block.To_Paragraph.Text);
            Writer.End_Element ("p");
         end if;

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
         Print_Blocks (Writer, Block.To_Quote, Is_Tight => False);
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

      elsif Block.Is_HTML_Block then
         Writer.Raw_HTML (Block.To_HTML_Block.Text);

      elsif Block.Is_Table then
         Print_Table (Writer, Block.To_Table);

      else
         raise Program_Error;
      end if;
   end Print_Block;

   procedure Print_Blocks
     (Writer   : in out HTML_Writers.Writer;
      List     : Markdown.Block_Containers.Block_Container'Class;
      Is_Tight : Boolean) is
   begin
      for Block of List loop
         Print_Block (Writer, Block, Is_Tight);
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
         Print_Blocks (Writer, Item, Is_Tight => not List.Is_Loose);
         Writer.End_Element ("li");
      end loop;

      Writer.End_Element (Tag);
   end Print_List;

   -----------------
   -- Print_Table --
   -----------------

   procedure Print_Table
     (Writer : in out HTML_Writers.Writer;
      Table  : Markdown.Blocks.Tables.Table) is
   begin
      Writer.Start_Element ("table");
      Writer.Start_Element ("thead");
      Writer.Start_Element ("tr");

      for J in 1 .. Table.Columns loop
         Writer.Start_Element ("th", Cell_Allign (Table.Alignment (J)));
         Print_Annotated_Text (Writer, Table.Header (J));
         Writer.End_Element ("th");
      end loop;

      Writer.End_Element ("tr");
      Writer.End_Element ("thead");

      if Table.Rows > 0 then
         Writer.Start_Element ("tbody");

         for Row in 1 .. Table.Rows loop
            Writer.Start_Element ("tr");

            for J in 1 .. Table.Columns loop
               Writer.Start_Element ("td", Cell_Allign (Table.Alignment (J)));
               Print_Annotated_Text (Writer, Table.Cell (Row, J));
               Writer.End_Element ("td");
            end loop;

            Writer.End_Element ("tr");
         end loop;

         Writer.End_Element ("tbody");
      end if;

      Writer.End_Element ("table");
   end Print_Table;

end Prints;
