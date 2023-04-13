--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Characters;
with VSS.Regular_Expressions;

package body Markdown.Implementation.Fenced_Code_Blocks is

   Fence_Pattern : constant Wide_Wide_String :=
     "^(   |  | |)(?:(``(?:`+)) *([^`]*)|(~~(?:~+)) *([^\f]*))$";
   --  1             2           3        4           5  <- group index

   Fence : VSS.Regular_Expressions.Regular_Expression;
   --  Regexp of Fence_Pattern

   -----------------
   -- Append_Line --
   -----------------

   overriding procedure Append_Line
     (Self  : in out Fenced_Code_Block;
      Input : Input_Position;
      CIP   : Can_Interrupt_Paragraph;
      Ok    : in out Boolean)
   is
      pragma Unreferenced (CIP);

      use type VSS.Characters.Virtual_Character;

      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Fence.Match (Input.Line.Expanded, Input.First);

      Cursor : VSS.Strings.Character_Iterators.Character_Iterator;
   begin
      if Self.Closed then
         Ok := False;

         return;

      elsif Match.Has_Match
         --  Closing fences cannot have info string
        and then Match.Captured (3).Is_Empty
        and then Match.Captured (5).Is_Empty
      then

         Self.Closed := Match.Marker (if Self.Is_Tick_Fence then 2 else 4).
           Character_Length >= Self.Fence_Length;
      end if;

      if Self.Closed then

         for J in 1 .. Self.Blank loop
            Self.Lines.Append (VSS.Strings.Empty_Virtual_String);
         end loop;
      else

         Cursor.Set_At (Input.First);

         if Cursor.Has_Element then
            --  Try to skip indent spaces
            for J in 1 .. Self.Indent loop
               exit when Cursor.Element /= ' ' or else not Cursor.Forward;
            end loop;
         end if;

         if Cursor.Has_Element then
            for J in 1 .. Self.Blank loop
               Self.Lines.Append (VSS.Strings.Empty_Virtual_String);
            end loop;

            Self.Lines.Append (Input.Line.Unexpanded_Tail (Cursor));
            Self.Blank := 0;
         else
            Self.Blank := Self.Blank + 1;
         end if;
      end if;

      Ok := True;
   end Append_Line;

   ------------
   -- Create --
   ------------

   overriding function Create
     (Input : not null access Input_Position) return Fenced_Code_Block
   is
      Match : constant VSS.Regular_Expressions.Regular_Expression_Match :=
        Fence.Match (Input.Line.Expanded, Input.First);
   begin
      pragma Assert (Match.Has_Match);

      return Result : Fenced_Code_Block do
         Result.Indent := Match.Marker (1).Character_Length;
         Result.Is_Tick_Fence := Match.Has_Capture (2);

         if Result.Is_Tick_Fence then
            Result.Fence_Length := Match.Marker (2).Character_Length;
            Result.Info_String := Match.Captured (3);
         else
            Result.Fence_Length := Match.Marker (4).Character_Length;
            Result.Info_String := Match.Captured (5);
         end if;

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
      Match : VSS.Regular_Expressions.Regular_Expression_Match;
   begin
      if not Fence.Is_Valid then  --  Construct Fence regexp
         Fence := VSS.Regular_Expressions.To_Regular_Expression
           (VSS.Strings.To_Virtual_String (Fence_Pattern));
      end if;

      Match := Fence.Match (Input.Line.Expanded, Input.First);

      if Match.Has_Match then
         Tag := Fenced_Code_Block'Tag;
         CIP := False;
      end if;
   end Detector;

   ----------
   -- Text --
   ----------

   function Text
     (Self : Fenced_Code_Block)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      First : Positive := 1;
      Last  : Natural := 0;
   begin
      for J in 1 .. Self.Lines.Length loop
         First := J;

         exit when not Self.Lines (J).Is_Empty;
      end loop;

      for J in reverse 1 .. Self.Lines.Length loop
         Last := J;

         exit when not Self.Lines (J).Is_Empty;
      end loop;

      if First = 1 and Last = Self.Lines.Length then
         return Self.Lines;
      else
         --  Drop leading and trailing empty lines
         return Result : VSS.String_Vectors.Virtual_String_Vector do
            for J in First .. Last loop
               Result.Append (Self.Lines (J));
            end loop;
         end return;
      end if;
   end Text;

end Markdown.Implementation.Fenced_Code_Blocks;
