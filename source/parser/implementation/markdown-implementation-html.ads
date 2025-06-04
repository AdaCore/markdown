--
--  Copyright (C) 2021-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Common regexp patterns for HTML elements and attributes.

package Markdown.Implementation.HTML is
   pragma Preelaborate;

   Attribute_Name : constant Wide_Wide_String := "[a-zA-Z_:][a-zA-Z0-9_.:\-]*";

   Unquoted_Attribute_Value : constant Wide_Wide_String :=
     "[^ \t\v\f""'=<>`]+";

   Single_Quoted_Attribute_Value : constant Wide_Wide_String := "'[^']*'";
   Double_Quoted_Attribute_Value : constant Wide_Wide_String := """[^""]*""";

   Attribute_Value : constant Wide_Wide_String :=
     Unquoted_Attribute_Value & "|" &
     Single_Quoted_Attribute_Value & "|" &
     Double_Quoted_Attribute_Value;

   Attribute_Value_Spec : constant Wide_Wide_String :=
     "[ \t]*=[ \t]*(?:" & Attribute_Value & ")";

end Markdown.Implementation.HTML;
