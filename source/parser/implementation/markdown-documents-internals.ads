--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Implementation;

package Markdown.Documents.Internals is
   pragma Preelaborate;

   procedure Set
     (Self : in out Document;
      Data : in out Markdown.Implementation.Abstract_Container_Block'Class);

end Markdown.Documents.Internals;
