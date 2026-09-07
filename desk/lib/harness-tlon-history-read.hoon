::  Versioned, bounded native reads for one already-authorized destination.
/-  t=harness-tlon, cv=tlon-chat-ver, dv=tlon-channels-ver
/+  hp=harness-tlon-history-page, hist=harness-tlon-history
|_  bowl=bowl:gall
++  load
  |=  [to=destination:t before=(unit @da) count=@ud]
  ^-  [parent=(unit message:hp) rows=(list row:hp)]
  ?>  &((gth count 0) (lte count 65))
  =/  window=path  ?~(before /newest/(scot %ud count) /older/(scot %ud u.before)/(scot %ud count))
  ?-  -.to
      %dm
    ?^  parent.to
      =/  post=(may:v7:cv writ:v7:cv)
        .^((may:v7:cv writ:v7:cv) %gx /(scot %p our.bowl)/chat/(scot %da now.bowl)/v4/dm/(scot %p who.to)/writs/writ/id/(scot %p p.u.parent.to)/(scot %ud q.u.parent.to)/chat-writ-4)
      ?>  ?=(%& -.post)
      =/  rows
        ?~  before  (top:dm-replies:hist replies:+.post count)
        (bat:dm-replies:hist replies:+.post before count)
      :-  `(dm-post:hp +.post)
      %+  turn  rows
      |=  [at=@da value=(may:v7:cv reply:v7:cv)]
      ^-  row:hp
      [at ?:(?=(%| -.value) ~ `(dm-reply:hp +.value))]
    =/  target=path
      (weld /(scot %p our.bowl)/chat/(scot %da now.bowl)/v4/dm/(scot %p who.to)/writs (weld window /light/chat-paged-writs-4))
    =/  page=paged-writs:v7:cv  .^(paged-writs:v7:cv %gx target)
    :-  ~
    %+  turn  (tap:on:writs:v7:cv writs.page)
    |=  [at=@da value=(may:v7:cv writ:v7:cv)]
    ^-  row:hp
    [at ?:(?=(%| -.value) ~ `(dm-post:hp +.value))]
      %channel
    ?^  parent.to
      =/  page=paged-posts:v9:dv
        .^(paged-posts:v9:dv %gx /(scot %p our.bowl)/channels/(scot %da now.bowl)/v4/[kind.nest.to]/(scot %p ship.nest.to)/[name.nest.to]/posts/older/(scot %ud +(u.parent.to))/1/outline/channel-posts-4)
      =/  parent  (get:on-posts:v9:dv posts.page u.parent.to)
      ?>  ?=([~ %& *] parent)
      =/  target=path
        (weld /(scot %p our.bowl)/channels/(scot %da now.bowl)/v4/[kind.nest.to]/(scot %p ship.nest.to)/[name.nest.to]/posts/post/id/(scot %ud u.parent.to)/replies (weld window /channel-replies-4))
      =/  replies=replies:v9:dv  .^(replies:v9:dv %gx target)
      :-  `(channel-post:hp +.u.parent)
      %+  turn  (tap:on-replies:v9:dv replies)
      |=  [at=@da value=(may:v9:dv reply:v9:dv)]
      ^-  row:hp
      [at ?:(?=(%| -.value) ~ `(channel-reply:hp +.value))]
    =/  target=path
      (weld /(scot %p our.bowl)/channels/(scot %da now.bowl)/v4/[kind.nest.to]/(scot %p ship.nest.to)/[name.nest.to]/posts (weld window /outline/channel-posts-4))
    =/  page=paged-posts:v9:dv  .^(paged-posts:v9:dv %gx target)
    :-  ~
    %+  turn  (tap:on-posts:v9:dv posts.page)
    |=  [at=@da value=(may:v9:dv post:v9:dv)]
    ^-  row:hp
    [at ?:(?=(%| -.value) ~ `(channel-post:hp +.value))]
  ==
--
