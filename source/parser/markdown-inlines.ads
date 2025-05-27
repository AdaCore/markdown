--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Annotated text contains a plain text with all markup removed and
--  a list of corresponding annotations. Each annotation has a segment of
--  the plain text and some additional information if required.

with Ada.Containers.Vectors;

with VSS.Strings;
with VSS.String_Vectors;

package Markdown.Inlines is
   pragma Preelaborate;

   type Annotation_Kind is
     (Soft_Line_Break,
      Emphasis,
      Strong,
      Link,
      Code_Span,
      Image,
      HTML_Open_Tag,
      HTML_Close_Tag,
      HTML_Comment,
      HTML_Processing_Instruction,
      HTML_Declaration,
      HTML_CDATA);
   --  Kind of annotation for parsed inline content

   type HTML_Attribute is record
      Name  : VSS.Strings.Virtual_String;
      Value : VSS.String_Vectors.Virtual_String_Vector;
      --  An empty vector means no value for the attribute
   end record;
   --  A HTML attribute representation

   package HTML_Attribute_Vectors is new Ada.Containers.Vectors
     (Positive, HTML_Attribute);
   --  A vector of HTML attributes

   type Annotation (Kind : Annotation_Kind := Annotation_Kind'First) is record
      From : VSS.Strings.Character_Index := 1;
      To   : VSS.Strings.Character_Count := 0;
      --  Corresponding segment in the plain text

      case Kind is
         when Soft_Line_Break |
              Emphasis |
              Strong |
              Code_Span =>
            null;

         when Link | Image =>
            Destination : VSS.Strings.Virtual_String;
            Title       : VSS.String_Vectors.Virtual_String_Vector;
            --  Link/image title could span several lines

         when HTML_Open_Tag =>
            HTML_Open_Tag   : VSS.Strings.Virtual_String;
            HTML_Attributes : HTML_Attribute_Vectors.Vector;

         when HTML_Close_Tag =>
            HTML_Close_Tag : VSS.Strings.Virtual_String;

         when HTML_Comment =>
            HTML_Comment   : VSS.String_Vectors.Virtual_String_Vector;

         when HTML_Processing_Instruction =>
            HTML_Instruction : VSS.String_Vectors.Virtual_String_Vector;

         when HTML_Declaration =>
            HTML_Declaration : VSS.String_Vectors.Virtual_String_Vector;

         when HTML_CDATA =>
            HTML_CDATA : VSS.String_Vectors.Virtual_String_Vector;
      end case;
   end record;
   --  An annotation for particular inline content segment

   package Annotation_Vectors is new
     Ada.Containers.Vectors (Positive, Annotation);

   type Annotated_Text is tagged limited record
      Plain_Text : VSS.Strings.Virtual_String;
      Annotation : Annotation_Vectors.Vector;
   end record;
   --  Annotated text contains plain text and a list of annotations

end Markdown.Inlines;
