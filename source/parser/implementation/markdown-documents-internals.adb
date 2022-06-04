--
--  Copyright (C) 2021-2022, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body Markdown.Documents.Internals is

   ---------
   -- Set --
   ---------

   procedure Set
     (Self : in out Document;
      Data : in out Markdown.Implementation.Abstract_Container_Block'Class)
   is
   begin
      Self.Data := Data'Unchecked_Access;
   end Set;

end Markdown.Documents.Internals;
