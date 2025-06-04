--
--  Copyright (C) 2021-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package Markdown is
   pragma Pure;

   type Extension_Set is record
      Link_Attributes : Boolean := False;
      --  Attributes can be set on links and images:
      --  `![image](foo.jpg){#id .class width=30 height=20px}`
      --
      --  * #word is equal to `id=#word`
      --  * .word is equal to `class=word`

   end record;

end Markdown;
