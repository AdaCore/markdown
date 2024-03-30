--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Internal representation of a markdown HTML blocks

with VSS.Regular_Expressions;

package body Markdown.Implementation.HTML_Blocks is

   Tag_List : constant Wide_Wide_String :=
     "address|" &
     "article|" &
     "aside|" &
     "basefont|" &
     "base|" &
     "blockquote|" &
     "body|" &
     "caption|" &
     "center|" &
     "colgroup|" &
     "col|" &
     "dd|" &
     "details|" &
     "dialog|" &
     "dir|" &
     "div|" &
     "dl|" &
     "dt|" &
     "fieldset|" &
     "figcaption|" &
     "figure|" &
     "footer|" &
     "form|" &
     "frameset|" &
     "frame|" &
     "h1|" &
     "h2|" &
     "h3|" &
     "h4|" &
     "h5|" &
     "h6|" &
     "header|" &
     "head|" &
     "hr|" &
     "html|" &
     "iframe|" &
     "legend|" &
     "link|" &
     "li|" &
     "main|" &
     "menuitem|" &
     "menu|" &
     "nav|" &
     "noframes|" &
     "ol|" &
     "optgroup|" &
     "option|" &
     "param|" &
     "p|" &
     "section|" &
     "source|" &
     "summary|" &
     "table|" &
     "tbody|" &
     "td|" &
     "tfoot|" &
     "thead|" &
     "th|" &
     "title|" &
     "track|" &
     "tr|" &
     "ul";

   Tag_Name  : constant Wide_Wide_String := "[a-zA-Z][a-zA-Z0-9\-]*";
   Attr_Name : constant Wide_Wide_String := "[a-zA-Z_:][a-zA-Z0-9_.:\-]*";

   Unquoted_Attr_Value : constant Wide_Wide_String := "[^ \t\v\f""'=<>`]+";
   Single_Quoted_Attr_Value : constant Wide_Wide_String := "'[^']*'";
   Double_Quoted_Attr_Value : constant Wide_Wide_String := """[^""]*""";

   Attr_Value : constant Wide_Wide_String :=
     Unquoted_Attr_Value & "|" &
     Single_Quoted_Attr_Value & "|" &
     Double_Quoted_Attr_Value;

   Attr_Value_Spec : constant Wide_Wide_String :=
     "[ \t]*=[ \t]*(?:" & Attr_Value & ")";

   Attribute : constant Wide_Wide_String :=
     "[ \t]+" & Attr_Name & "(?:" & Attr_Value_Spec & ")?";

   Open_Tag : constant Wide_Wide_String :=
     "<" & Tag_Name & "(?:" & Attribute & ")*[ \t]*/?>";

   Closing_Tag : constant Wide_Wide_String := "</" & Tag_Name & "[ \t]*>";

   Open_Prefix : constant Wide_Wide_String := "^(?:   |  | |)";
   --  up to three optional spaces of indentation

   Case_1 : constant Wide_Wide_String :=
     "<(?:script|pre|style)(?:[ \t\v\f>]|$)";

   Case_2 : constant Wide_Wide_String := "<!--";
   Case_3 : constant Wide_Wide_String := "<\?";
   Case_4 : constant Wide_Wide_String := "<![A-Z]";
   Case_5 : constant Wide_Wide_String := "<!\[CDATA\[";
   Case_6 : constant Wide_Wide_String :=
     "</?(?:" & Tag_List & ")(?:[ \t\v\f]|/?>|$)";

   Case_7      : constant Wide_Wide_String :=
     "(?:" & Open_Tag & "|" & Closing_Tag & ")[ \t]*$";

   --  Case_1 .. Case_7 doesn't have any capture group inside

   Open_Regexp : constant Wide_Wide_String := Open_Prefix &
     "(" & Case_1 & ")|" &
     "(" & Case_2 & ")|" &
     "(" & Case_3 & ")|" &
     "(" & Case_4 & ")|" &
     "(" & Case_5 & ")|" &
     "(" & Case_6 & ")|" &
     "(" & Case_7 & ")";

   Open_Pattern : VSS.Regular_Expressions.Regular_Expression;

   Close_Pattern : array (HTML_Block_Kind range 1 .. 5) of
     VSS.Regular_Expressions.Regular_Expression;

   Blank_Pattern : VSS.Regular_Expressions.Regular_Expression;
   --  Blank line pattern

   procedure Initialze_Patterns;

   -----------------
   -- Append_Line --
   -----------------

   overriding procedure Append_Line
     (Self  : in out HTML_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean) is
   begin
      if Self.Closed then
         Ok := False;

         return;

      elsif Self.Kind in Close_Pattern'Range then
         Self.Lines.Append (Input.Line.Unexpanded_Tail (Input.First));

         Self.Closed := Close_Pattern (Self.Kind).Match
           (Input.Line.Expanded, Input.First).Has_Match;

      elsif Blank_Pattern.Match
        (Input.Line.Expanded,
         Input.First,
         Options => [VSS.Regular_Expressions.Anchored_Match => True])
           .Has_Match
      then
         Self.Closed := True;

      else
         Self.Lines.Append (Input.Line.Unexpanded_Tail (Input.First));
      end if;

      Ok := True;
   end Append_Line;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return HTML_Block
   is
      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Open_Pattern.Match (Input.Line.Expanded, Input.First);
   begin
      return Result : HTML_Block do
         for J in HTML_Block_Kind loop
            if Match.Has_Capture (J) then
               Result.Kind := J;

               Result.Closed := J in Close_Pattern'Range
                 and then Close_Pattern (J).Match
                   (Input.Line.Expanded, Input.First).Has_Match;

               exit;
            end if;
         end loop;

         Result.Lines.Append
           (Input.Line.Unexpanded_Tail (Input.First));

         --  Shift Input.First to end-of-line
         Input.First.Set_After_Last (Input.Line.Expanded);
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
   begin
      if not Open_Pattern.Is_Valid then
         Initialze_Patterns;
      end if;

      declare
         Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
           Open_Pattern.Match (Input.Line.Expanded, Input.First);
      begin
         if Match.Has_Match then
            Tag := HTML_Block'Tag;
            --  All types of HTML blocks except type 7 may interrupt a
            --  paragraph.
            CIP := not Match.Has_Capture (7);
            return;
         end if;
      end;
   end Detector;

   ------------------------
   -- Initialze_Patterns --
   ------------------------

   procedure Initialze_Patterns is
      function "+"
        (Pattern : Wide_Wide_String)
          return VSS.Regular_Expressions.Regular_Expression is
            (VSS.Regular_Expressions.To_Regular_Expression
              (VSS.Strings.To_Virtual_String (Pattern),
                [VSS.Regular_Expressions.Case_Insensitive => True,
                 others                                   => False]));

   begin
      Open_Pattern := +Open_Regexp;

      Close_Pattern :=
        [1 => +"</script>|</pre>|</style>",
         2 => +"-->",
         3 => +"\?>",
         4 => +">",
         5 => +"\]\]>"];

      Blank_Pattern := +"[ \t]*";
   end Initialze_Patterns;

end Markdown.Implementation.HTML_Blocks;
