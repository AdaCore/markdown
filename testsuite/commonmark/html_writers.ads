--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with Ada.Containers.Doubly_Linked_Lists;

with VSS.Strings;

package HTML_Writers is

   type HTML_Attribute is record
      Name  : VSS.Strings.Virtual_String;
      Value : VSS.Strings.Virtual_String;
   end record;

   package HTML_Attribute_Lists is new Ada.Containers.Doubly_Linked_Lists
     (HTML_Attribute);

   type HTML_Attributes is new HTML_Attribute_Lists.List with null record;

   No_Attributes : constant HTML_Attributes :=
     (HTML_Attribute_Lists.Empty_List with null record);

   type Writer is tagged limited private;

   procedure Characters
     (Self : in out Writer;
      Text : VSS.Strings.Virtual_String);

   procedure End_Element
     (Self       : in out Writer;
      Local_Name : VSS.Strings.Virtual_String);

   procedure Start_Element
     (Self       : in out Writer;
      Local_Name : VSS.Strings.Virtual_String;
      Attributes : HTML_Attributes'Class := No_Attributes);

private

   type Writer is tagged limited record
      Tag   : VSS.Strings.Virtual_String;
      CDATA : Boolean := False;
   end record;

end HTML_Writers;
