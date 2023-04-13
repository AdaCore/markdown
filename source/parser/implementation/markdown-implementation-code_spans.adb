--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Simple parser for code spans

with VSS.Characters.Latin;
with VSS.Regular_Expressions;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Cursors.Markers;

with Markdown.Annotations;

package body Markdown.Implementation.Code_Spans is

   Open_Pattern : constant Wide_Wide_String :=
     "(?:[^`\\]|\\[^\f])*(`+)";
   --                    1  <- group index

   Close_Pattern : constant Wide_Wide_String := "`+";

   Open : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Open_Pattern
   Close : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Close_Pattern

   procedure Find_Code_Span
     (Text   : VSS.Strings.Virtual_String;
      From   : VSS.Strings.Cursors.Markers.Character_Marker;
      Length : VSS.Strings.Character_Count;
      Span   : in out Markdown.Simple_Inline_Parsers.Inline_Span);

   --------------------
   -- Find_Code_Span --
   --------------------

   procedure Find_Code_Span
     (Text   : VSS.Strings.Virtual_String;
      From   : VSS.Strings.Cursors.Markers.Character_Marker;
      Length : VSS.Strings.Character_Count;
      Span   : in out Markdown.Simple_Inline_Parsers.Inline_Span)
   is
      Match : VSS.Regular_Expressions.Regular_Expression_Match;
      Pos   : VSS.Strings.Character_Iterators.Character_Iterator;
   begin
      Pos.Set_At (From);
      Forward (Pos, Length);  --  skip open backticks

      while Pos.Has_Element loop
         Match := Close.Match (Text, Pos);

         exit when not Match.Has_Match;

         if Match.Captured.Character_Length = Length then
            declare
               Plain  : VSS.Strings.Virtual_String;
               Start  : VSS.Strings.Character_Iterators.Character_Iterator;
               Stop   : VSS.Strings.Character_Iterators.Character_Iterator;
               Vector : Markdown.Annotations.Annotation_Vectors.Vector;
               Ignore : Boolean;
            begin
               Start.Set_At (From);
               Forward (Start, Length);  --  skip open backticks
               Stop.Set_At (Match.First_Marker);
               Ignore := Stop.Backward;

               if Start.Element in ' ' | VSS.Characters.Latin.Line_Feed
                 and Stop.Element in ' ' | VSS.Characters.Latin.Line_Feed
               then
                  Forward (Start);
                  Ignore := Stop.Backward;
               end if;

               Plain := Text.Slice (Start, Stop);

               Vector.Append
                 ((Kind => Markdown.Annotations.Code_Span,
                   From => 1,
                   To   => Plain.Character_Length));

               Span :=
                 (Is_Set     => True,
                  From       => From,
                  To         => Match.Last_Marker,
                  Plain_Text => Plain,
                  Annotation => Vector);

               return;
            end;
         end if;

         --  Continue search after match
         Pos.Set_At (Match.Last_Marker);
         Forward (Pos);
      end loop;
   end Find_Code_Span;

   ---------------------
   -- Parse_Code_Span --
   ---------------------

   procedure Parse_Code_Span
     (Text : VSS.Strings.Virtual_String;
      From : VSS.Strings.Cursors.Abstract_Character_Cursor'Class;
      Span : out Markdown.Simple_Inline_Parsers.Inline_Span)
   is
      Match : VSS.Regular_Expressions.Regular_Expression_Match;
      Pos   : VSS.Strings.Character_Iterators.Character_Iterator;
   begin
      if not Open.Is_Valid then  --  Construct Open/Close regexps
         Open := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Open_Pattern));
         Close := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Close_Pattern));
      end if;

      Span := (Is_Set => False);

      Pos.Set_At (From);

      while Pos.Has_Element and not Span.Is_Set loop
         Match := Open.Match (Text, Pos);

         exit when not Match.Has_Match;

         Find_Code_Span
           (Text,
            Match.First_Marker (1),
            Match.Captured (1).Character_Length,
            Span);

         --  Step after match
         Pos.Set_At (Match.Last_Marker);
         Forward (Pos);
      end loop;
   end Parse_Code_Span;

end Markdown.Implementation.Code_Spans;
