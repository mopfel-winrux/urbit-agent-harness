::  Pure social boundary: authentic source nouns -> allowed, addressed input.
::  Nicknames are presentation, never identity or authority. Sessions separate
::  sender, destination and grant epoch so privilege cannot bleed across chats.
/-  t=harness-tlon, a=tlon-activity-ver
/+  ht=harness-tools, story=harness-tlon-story
|%
++  grants
  |=  [policy=policy:t actor=@p]
  ^-  (unit (list term))
  ?.  enabled.policy  ~
  ?:  =(`actor owner.policy)  `all-tools:ht
  (~(get by trusted.policy) actor)
++  address
  |=  to=destination:t
  ^-  @t
  ?-  -.to
      %dm
    (rap 3 'dm/' (scot %p who.to) ?~(parent.to '' (rap 3 '/' (scot %p p.u.parent.to) '/' (scot %da q.u.parent.to) ~)) ~)
      %channel
    (rap 3 kind.nest.to '/' (scot %p ship.nest.to) '/' name.nest.to ?~(parent.to '' (cat 3 '/' (scot %da u.parent.to))) ~)
  ==
++  session-id
  |=  [epoch=@ud actor=@p to=destination:t]
  ^-  @t
  =/  surface=@t
    ?-  -.to
      %dm       ?~(parent.to 'dm' 'dm-thread')
      %channel  (cat 3 (end 3^24 name.nest.to) ?~(parent.to '' '-thread'))
    ==
  ::  Human-readable identity with a 128-bit scope suffix. Stable for this
  ::  sender/destination/epoch, so later messages continue the same session.
  (rap 3 (rsh 3^1 (scot %p actor)) '-' surface '-' (scot %uv (end 7^1 (sham [epoch actor to]))) ~)
++  normalize
  |=  [our=@p policy=policy:t event=incoming-event:v8:a]
  ^-  (unit input:t)
  =/  item=(unit [actor=@p key=message-key:a to=destination:t text=@t addressed=?])
    ?+  -.event  ~
        %dm-post
      ?.  ?=(%ship -.whom.event)  ~
      `[p.id.key.event key.event [%dm p.whom.event ~] (story-to-text:story content.event) &]
        %dm-reply
      ?.  ?=(%ship -.whom.event)  ~
      `[p.id.key.event key.event [%dm p.whom.event `id.parent.event] (story-to-text:story content.event) &]
        %post
      `[p.id.key.event key.event [%channel channel.event ~] (story-to-text:story content.event) mention.event]
        %reply
      `[p.id.key.event key.event [%channel channel.event `time.parent.event] (story-to-text:story content.event) |(mention.event =(our p.id.parent.event))]
    ==
  ?~  item  ~
  ?:  =(actor.u.item our)  ~
  ?~  (grants policy actor.u.item)  ~
  ?:  &(?=(%channel -.to.u.item) mentions.policy !addressed.u.item)  ~
  ::  A DM's partner must be its source author, not an asserted third party.
  ?:  &(?=(%dm -.to.u.item) !=(who.to.u.item actor.u.item))  ~
  ?:  |(=('' text.u.item) (gth (met 3 text.u.item) 65.536))  ~
  =/  id=@t  (scot %uv (sham [to.u.item key.u.item]))
  `[actor.u.item id to.u.item text.u.item]
++  policy-json
  |=  policy=policy:t
  ^-  json
  %-  pairs:enjs:format
  :~  ['enabled' %b enabled.policy]
      ['owner' ?~(owner.policy ~ [%s (scot %p u.owner.policy)])]
      ['mentions' %b mentions.policy]
      :-  'trusted'
      :-  %a
      %+  turn  ~(tap by trusted.policy)
      |=  [who=@p tools=(list term)]
      (pairs:enjs:format ~[['ship' %s (scot %p who)] ['tools' %a (turn tools |=(name=term `json`[%s name]))]])
  ==
++  json-policy
  |=  jon=json
  ^-  policy:t
  =,  dejs:format
  =/  val=[enabled=? owner=(unit @p) mentions=? trusted=(list [p=@p q=(list term)])]
    ((ot ~[enabled+bo owner+(mu (se %p)) mentions+bo trusted+(ar (ot ~[ship+(se %p) tools+(ar (su sym))]))]) jon)
  =/  policy=policy:t  [enabled.val owner.val (my trusted.val) mentions.val]
  ?>  |(!enabled.policy ?=(^ owner.policy))
  ?>  (lte ~(wyt by trusted.policy) 64)
  ?>  =(~(wyt by trusted.policy) (lent trusted.val))
  ?>  (levy ~(val by trusted.policy) |=(ts=(list term) (levy ts |=(name=term (lien all-tools:ht |=(known=term =(name known)))))))
  policy
--
