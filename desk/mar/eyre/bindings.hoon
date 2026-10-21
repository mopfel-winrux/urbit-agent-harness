::  HTTP path bindings within a desk's origin.
|_  bindings=(list binding:eyre)
++  grad  %noun
++  grow
  |%
  ++  noun  bindings
  ++  mime  [/application/json (as-octs:mimes:html (en:json:html json))]
  ++  json
    :-  %a
    %+  turn  bindings
    |=  =binding:eyre
    (pairs:enjs:format ~[['path' %s (spat path.binding)]])
  --
++  grab
  |%
  ++  noun  (list binding:eyre)
  ++  mime
    |=  [=mite len=@ud dat=@]
    ^-  (list binding:eyre)
    =/  jon=^json  (need (de:json:html (cut 3 [0 len] dat)))
    (json jon)
  ++  json
    |=  jon=^json
    ^-  (list binding:eyre)
    =-  ((ar:dejs:format -) jon)
    |=  item=^json
    ?>  ?=(%o -.item)
    (stab (so:dejs:format (~(got by p.item) 'path')))
  --
--
