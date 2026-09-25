::  Small UTF-8-safe pages. Offsets address source bytes, never encoded JSON.
/+  w=harness-provider-wire
|%
++  number
  |=  [args=json key=@t]
  ^-  @ud
  =/  text  (str:w args key)
  ?:  =('' text)  0
  =/  n  (need (rush text dem))
  ?>  =(text (crip (a-co:co n)))
  n
++  boundary
  |=  [body=@t at=@ud]
  ^-  @ud
  =/  byte  (cut 3 [at 1] body)
  ?:  &((gte byte 128) (lth byte 192) (gth at 0))  $(at (dec at))
  at
++  text
  |=  [body=@t offset=@ud]
  ^-  json
  =/  bytes  (met 3 body)
  ?>  &((lte offset bytes) =(offset (boundary body offset)))
  =/  end  (boundary body (min bytes (add offset 6.000)))
  (pairs:enjs:format ~[['text' %s (cut 3 [offset (sub end offset)] body)] ['bytes' (numb:enjs:format bytes)] ['nextOffset' ?:(=(end bytes) ~ [%s (crip (a-co:co end))])]])
++  directory
  |=  [rows=(list @t) offset=@ud]
  ^-  json
  ?>  (lte offset (lent rows))
  =/  remaining  (slag offset rows)
  =/  selected=(list json)  ~
  =/  bytes=@ud  0
  |-  ^-  json
  =/  count  (lent selected)
  =/  full  |(=(100 count) ?=(~ remaining))
  =?  full  ?=(^ remaining)
    |(full (gth (add bytes (met 3 (en:json:html [%s i.remaining]))) 6.000))
  ?:  full
    ?>  |(?=(^ selected) ?=(~ remaining))
    (pairs:enjs:format ~[['items' %a (flop selected)] ['nextOffset' ?~(remaining ~ [%s (crip (a-co:co (add offset count)))])]])
  ?>  ?=(^ remaining)
  $(remaining t.remaining, selected [[%s i.remaining] selected], bytes (add bytes (met 3 (en:json:html [%s i.remaining]))))
--
