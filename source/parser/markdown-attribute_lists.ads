--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Types for HTML attributes and attribute lists

with Ada.Containers.Vectors;
with Ada.Iterator_Interfaces;

with VSS.Strings;

package Markdown.Attribute_Lists is
   pragma Preelaborate;

   type Attribute is record
      Name  : VSS.Strings.Virtual_String;
      Value : VSS.Strings.Virtual_String;
   end record;

   type Attribute_List is tagged private
     with
       Constant_Indexing => Element,
       Default_Iterator  => Iterate,
       Iterator_Element  => Attribute,
       Preelaborable_Initialization;

   procedure Parse
     (Self : in out Attribute_List'Class;
      Text : VSS.Strings.Virtual_String);

   function Length (Self : Attribute_List'Class) return Natural;
   --  Number of attributes in the attribute list

   function Name
     (Self  : Attribute_List'Class;
      Index : Positive) return VSS.Strings.Virtual_String;
   --  Name of the attribute

   function Value
     (Self  : Attribute_List'Class;
      Index : Positive) return VSS.Strings.Virtual_String;
   --  Value of the attribute. No line separator is supported for now

   function Origin_Text
     (Self : Attribute_List'Class) return VSS.Strings.Virtual_String;
   --  Return original text provided to Parse

   function Empty return Attribute_List;

   --  Syntax sugar for Ada 2012 user-defined iterator

   type Cursor is private;

   function Element
     (Self  : Attribute_List'Class;
      Index : Cursor) return Attribute;

   function Has_Element (Self : Cursor) return Boolean
     with Inline;

   package Iterator_Interfaces is new Ada.Iterator_Interfaces
     (Cursor, Has_Element);

   type Reversible_Iterator is
     limited new Iterator_Interfaces.Reversible_Iterator with private;

   overriding function First (Self : Reversible_Iterator) return Cursor;

   overriding function Next
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor
        with Inline;

   overriding function Last (Self : Reversible_Iterator) return Cursor;

   overriding function Previous
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor
        with Inline;

   function Iterate
     (Self : Attribute_List'Class) return Reversible_Iterator;
   --  Return an iterator over each element in the vector

private

   package Attribute_Vectors is new Ada.Containers.Vectors
     (Positive, Attribute);

   type Attribute_List is tagged record
      Text : VSS.Strings.Virtual_String;
      List : Attribute_Vectors.Vector;
   end record;

   function Length (Self : Attribute_List'Class) return Natural is
     (Self.List.Last_Index);

   function Origin_Text
     (Self : Attribute_List'Class) return VSS.Strings.Virtual_String is
       (Self.Text);

   function Name
     (Self : Attribute_List'Class; Index : Positive)
      return VSS.Strings.Virtual_String is
        (Self.List (Index).Name);

   function Value
     (Self : Attribute_List'Class; Index : Positive)
      return VSS.Strings.Virtual_String is
        (Self.List (Index).Value);

   function Empty return Attribute_List is
     (Text => VSS.Strings.Empty_Virtual_String,
      List => Attribute_Vectors.Empty_Vector);

   type Cursor is record
      Index : Natural;
   end record;

   function Has_Element (Self : Cursor) return Boolean is (Self.Index > 0);

   function Element
     (Self  : Attribute_List'Class;
      Index : Cursor) return Attribute is
        (Self.List (Index.Index));

   type Reversible_Iterator is
     limited new Iterator_Interfaces.Reversible_Iterator with
   record
      Last : Natural;
   end record;

   overriding function First (Self : Reversible_Iterator) return Cursor is
     (Index => (if Self.Last > 0 then 1 else 0));

   overriding function Last (Self : Reversible_Iterator) return Cursor is
     (Index => Self.Last);

   overriding function Next
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor is
       (Index =>
          (if Position.Index < Self.Last then Position.Index + 1 else 0));

   overriding function Previous
     (Self     : Reversible_Iterator;
      Position : Cursor) return Cursor is
        (Index => (if Position.Index > 0 then Position.Index - 1 else 0));

   function Iterate
     (Self : Attribute_List'Class) return Reversible_Iterator is
       (Last => Self.Length);

end Markdown.Attribute_Lists;
