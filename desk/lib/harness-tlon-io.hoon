::  Messenger effects and contact projection. Only this module knows which
::  public Gall marks a DM, channel post, or invitation needs.
/-  t=harness-tlon, dv=tlon-channels-ver, cv=tlon-chat-ver, ct=tlon-contacts, a=tlon-activity-ver
/+  story=harness-tlon-story, profile=harness-tlon-profile
|_  bowl=bowl:gall
+$  card  card:agent:gall
++  publish
  |=  [wire=wire to=destination:t text=@t sent=@da]
  ^-  card
  =/  memo=memo:v9:dv  [(text-to-story:story text) our.bowl sent]
  ?-  -.to
      %dm
    =/  diff=diff:dm:v7:cv
      ?~  parent.to  [[our.bowl sent] %add [memo chat+/ ~ ~] `sent]
      ::  Parent is the author's durable writ id, not activity's local time.
      [u.parent.to %reply [our.bowl sent] ~ %add [memo ~] `sent]
    [%pass wire %agent [our.bowl %chat] %poke %chat-dm-action-2 !>(`action:dm:v7:cv`[who.to diff])]
      %channel
    =/  act=a-channels:v9:dv
      ?~  parent.to  [%channel nest.to %post %add [memo [kind.nest.to ~] ~ ~]]
      [%channel nest.to %post %reply u.parent.to %add memo]
    [%pass wire %agent [our.bowl %channels] %poke %channel-action-1 !>(act)]
  ==
++  invitation-posts
  |=  [who=@p since=@da]
  ^-  (list incoming-event:v8:a)
  ::  The first DM arrives as an invitation, not a post notification. After
  ::  accepting, project a bounded page through the usual admission gate.
  ::  Original writ ids make overlap with live activity idempotent.
  =/  page=paged-writs:v7:cv
    .^(paged-writs:v7:cv %gx /(scot %p our.bowl)/chat/(scot %da now.bowl)/v4/dm/(scot %p who)/writs/newest/64/light/chat-paged-writs-4)
  %+  murn  (tap:on:writs:v7:cv writs.page)
  |=  [time=@da item=(may:v7:cv writ:v7:cv)]
  ^-  (unit incoming-event:v8:a)
  ?.  ?=(%& -.item)  ~
  =/  post  +.item
  ?.  &(=(who p.id:-.post) (gth time since) =(chat+/ kind:+.post))  ~
  `[%dm-post [id:-.post time] [%ship who] content:+.post |]
++  self-profile
  ^-  json
  %-  encode:profile
  .^(contact:ct %gx /(scot %p our.bowl)/contacts/(scot %da now.bowl)/v1/self/contact-1)
++  edit-profile
  |=  [wire=wire fields=contact:ct]
  ^-  card
  [%pass wire %agent [our.bowl %contacts] %poke %contact-action-1 !>(`action:ct`[%self fields])]
++  contacts
  ^-  json
  =/  directory=directory:ct
    .^(directory:ct %gx /(scot %p our.bowl)/contacts/(scot %da now.bowl)/v1/directory/contact-directory-0)
  :-  %a
  %+  turn  ~(tap by directory)
  |=  [who=@p leaf=leaf:ct]
  ::  Local overlays take priority over the remote self-description.
  =/  merged  (~(uni by mod.leaf) con.leaf)
  =/  nick  (~(get by merged) %nickname)
  %-  pairs:enjs:format
  :~  ['ship' %s (scot %p who)]
      ['nickname' %s ?:(?=([~ %text *] nick) p.u.nick '')]
      ['contact' %b contact.leaf]
  ==
--
