::  Pure social boundary: authentic source nouns -> allowed, addressed input.
::  Nicknames are presentation, never identity or authority. Sessions separate
::  sender, destination and grant epoch so privilege cannot bleed across chats.
/-  t=harness-tlon, h=harness, a=tlon-activity-ver, cr=harness-cron, hh=harness-hand
/+  ht=harness-tools, hj=harness-json, story=harness-tlon-story, input=harness-tlon-input
|%
++  local-only
  |=  old=state-13:t
  ^-  state-14:t
  ::  Remove the derived export queue only. Accepted work and delivery evidence
  ::  remain in the head ledger; no cleanup poke is sent to any other agent.
  :*  %14  activity-through.old  catching-up.old  identities.old  routes.old
      cuts.old  channel-after.old  uploads.old  last-sent.old
      tool-receipts.old  cron.old  computing.old
      policy.old  epoch.old  after.old  lanes.old  jobs.old
      deliveries.old  notices.old  next-notice.old  listeners.old
      watching.old  wake.old  error.old
  ==
++  upgrade-reminders
  |=  old=state-11:t
  ^-  state-12:t
  =/  cron
    %-  ~(run by cron.old)
    |=  job=job-0:cr
    ^-  job:cr
    =/  lane  (~(get by lanes.old) run-sid.job)
    [%prompt 'UTC' ?~(lane '' (address to.u.lane)) job]
  :*  %12  identities.old  routes.old  cuts.old  channel-after.old
      lens-after.old  lenses.old  uploads.old  last-sent.old
      tool-receipts.old  cron  computing.old
      policy.old  epoch.old  after.old  lanes.old  jobs.old
      deliveries.old  notices.old  next-notice.old  listeners.old
      watching.old  wake.old  error.old
  ==
++  cron-clearable
  |=  [job=job:cr db=state:hh admitting=?]
  ^-  ?
  ?:  admitting  |
  ?.  |(=(%cancelled state.job) &(=(%complete state.job) =(0 remaining.job)))  |
  ?:  (lien ~(val by observations.db) |=(o=observation:hh &(=(run-sid.job binding.o) ?=(?(%queued %running) phase.o))))  |
  ?:  (lien ~(val by outbox.db) |=(p=publication:hh &(=(run-sid.job sid.p) ?=(?(%pending %claimed %uncertain) status.p))))  |
  ::  A schedule cancelled before its first admission has no execution receipt.
  ::  Remaining runs are an unused budget, not work that must be performed.
  ?~  last.job  =(%cancelled state.job)
  =/  last  (~(get by observations.db) u.last.job)
  ?~  last  |
  =(run-sid.job binding.u.last)
++  grants
  |=  [policy=policy:t actor=@p owner-tools=(list tool-grant:h)]
  ^-  (unit (list tool-grant:h))
  ?.  enabled.policy  ~
  ?:  =(`actor owner.policy)  `owner-tools
  (~(get by trusted.policy) actor)
++  grants-owned
  |=  [policy=policy:t actor=@p owner-tools=(list tool-grant:h) owner=?]
  ^-  (unit (list tool-grant:h))
  ?.  enabled.policy  ~
  ?:  owner  `owner-tools
  (~(get by trusted.policy) actor)
++  peer-grants
  |=  policy=policy:t
  ^-  (map @p peer-grant:h)
  ::  Disabling Tlon replies does not remove trust. No token cap or shared
  ::  skills are inherited; resource grants remain sender-specific.
  =/  peers=(map @p peer-grant:h)
    %-  malt
    %+  turn  ~(tap by trusted.policy)
    |=  [ship=@p tools=(list tool-grant:h)]
    [ship tools ~ 0 ~]
  ?~  owner.policy  peers
  ::  The peer binding replaces this membership placeholder with the owner's
  ::  default resources; administrative authority is checked from live origin.
  (~(put by peers) u.owner.policy [~ ~ 0 ~])
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
  (normalize-owned our policy event |=(actor=@p =(`actor owner.policy)))
++  normalize-owned
  |=  [our=@p policy=policy:t event=incoming-event:v8:a owner-test=$-(@p ?)]
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
      `[p.id.key.event key.event [%channel channel.event ~] (text:input our content.event) mention.event]
        %reply
      `[p.id.key.event key.event [%channel channel.event `time.parent.event] (text:input our content.event) |(mention.event =(our p.id.parent.event))]
    ==
  ?~  item  ~
  ?:  =(actor.u.item our)  ~
  ?~  (grants-owned policy actor.u.item ~ (owner-test actor.u.item))  ~
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
      |=  [who=@p tools=(list tool-grant:h)]
      (pairs:enjs:format ~[['ship' %s (scot %p who)] ['tools' %a (turn tools grant-json:hj)]])
  ==
++  json-policy
  |=  jon=json
  ^-  policy:t
  =,  dejs:format
  =/  val=[enabled=? owner=(unit @p) mentions=? trusted=(list [p=@p q=(list tool-grant:h)])]
    ((ot ~[enabled+bo owner+(mu (se %p)) mentions+bo trusted+(ar (ot ~[ship+(se %p) tools+(ar json-grant:hj)]))]) jon)
  =/  policy=policy:t  [enabled.val owner.val (my trusted.val) mentions.val]
  ?>  (lte ~(wyt by trusted.policy) 64)
  ?>  =(~(wyt by trusted.policy) (lent trusted.val))
  ?>  (levy ~(val by trusted.policy) |=(ts=(list tool-grant:h) (levy ts |=(grant=tool-grant:h ?:(?=(^ grant) & (lien all-tools:ht |=(known=term =(grant known))))))))
  policy
++  scope-mcp
  |=  [old=state-1:t servers=(list @t)]
  ^-  state-2:t
  =.  trusted.policy.old
    %+  roll  ~(tap by trusted.policy.old)
    |=  [[who=@p tools=(list tool-grant:h)] acc=(map @p (list tool-grant:h))]
    (~(put by acc) who (scope-mcp:ht tools servers))
  =.  lanes.old
    %+  roll  ~(tap by lanes.old)
    |=  [[sid=@t lane=lane:t] acc=(map @t lane:t)]
    (~(put by acc) sid lane(tools (scope-mcp:ht tools.lane servers)))
  [%2 +.old]
++  scope-clay
  |=  old=state-2:t
  ^-  state-3:t
  =.  trusted.policy.old
    %+  roll  ~(tap by trusted.policy.old)
    |=  [[who=@p tools=(list tool-grant:h)] acc=(map @p (list tool-grant:h))]
    (~(put by acc) who (scope-clay:ht tools))
  =.  lanes.old
    %+  roll  ~(tap by lanes.old)
    |=  [[sid=@t lane=lane:t] acc=(map @t lane:t)]
    (~(put by acc) sid lane(tools (scope-clay:ht tools.lane)))
  [%3 +.old]
++  upgrade-tools
  |=  old=state-3:t
  ^-  state-4:t
  [%4 ~ ~ +.old]
++  upgrade-presence
  |=  old=state-4:t
  ^-  state-5:t
  ::  Keep contexts so idle leases can still be cleared after reload. A zero
  ::  timestamp forces active contexts to refresh their richer projection.
  =/  leases=(map path presence-lease:t)
    %+  roll  ~(tap by computing.old)
    |=  [[ctx=path lease=presence-lease-0:t] acc=(map path presence-lease:t)]
    (~(put by acc) ctx [`@da`0 ~])
  :*  %5  tool-receipts.old  cron.old  leases
      policy.old  epoch.old  after.old  lanes.old  jobs.old
      deliveries.old  notices.old  next-notice.old  listeners.old
      watching.old  wake.old  error.old
  ==
++  upgrade-delivery
  |=  old=state-5:t
  ^-  state-6:t
  [%6 `@da`0 +.old]
++  upgrade-media
  |=  old=state-6:t
  ^-  state-7:t
  [%7 ['' ''] ~ +.old]
++  upgrade-hosted-media
  |=  old=state-7:t
  ^-  state-8:t
  [%8 +.old]
++  upgrade-native-media
  |=  old=state-8:t
  ^-  state-9:t
  ::  Drop the worker URL/token; on-load retires old pending requests.
  [%9 +.+.old]
++  upgrade-lens
  |=  [old=state-9:t now=@da]
  ^-  state-10:t
  ::  New summaries only: enabling the integration is not a history export.
  [%10 now ~ +.old]
++  next-message-stamp
  |=  [now=@da previous=@da]
  ^-  @da
  ::  Native Gall cascades can share one +now. Distinct publications must
  ::  still have distinct Messenger identities; this schedules no wake.
  (max now +(previous))
--
