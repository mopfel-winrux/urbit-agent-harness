/-  h=harness
|%
+$  input  [%0 session=session:h skills=(map @t skill:h) expected=@uvH]
+$  failure  [%failed source=* trace=tang]
+$  state
  $%  [%0 session=session:h skills=(map @t skill:h) expected=@uvH]
      [%failed source=* trace=tang]
  ==
--
