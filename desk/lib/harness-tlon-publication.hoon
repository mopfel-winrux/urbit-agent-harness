::  Only host-confirmed channel responses prove publication. Pending client
::  echoes, reactions, tombstones and other authors are never receipts.
/-  t=harness-tlon, dv=tlon-channels-ver
|%
++  proof
  |=  [our=@p to=destination:t author=author:v9:dv sent=@da id=@da]
  ^-  (unit publication-proof:t)
  ?.  =(our ?@(author author ship.author))  ~
  `[to sent id]
++  channel
  |=  [our=@p response=r-channels:v9:dv]
  ^-  (list publication-proof:t)
  =/  nest  nest.response
  =/  r  r-channel.response
  ?:  ?=(%posts -.r)
    %+  murn  (tap:on-posts:v9:dv posts.r)
    |=  [id=@da value=(may:v9:dv post:v9:dv)]
    ?:  ?=(%| -.value)  ~
    (proof our [%channel nest ~] author:+.+.+.value sent:+.+.+.value id)
  ?.  ?=(%post -.r)  ~
  =/  p  r-post.r
  =/  found=(unit publication-proof:t)
    ?:  ?=(%set -.p)
      ?:  ?=(%| -.post.p)  ~
      =/  value  +.post.p
      (proof our [%channel nest ~] author:+.+.value sent:+.+.value id.r)
    ?.  ?=([%reply * * %set *] p)  ~
    ?:  ?=(%| -.reply.r-reply.p)  ~
    =/  value  +.reply.r-reply.p
    (proof our [%channel nest `id.r] author:+.+.value sent:+.+.value id.p)
  ?~  found  ~
  ~[u.found]
--
