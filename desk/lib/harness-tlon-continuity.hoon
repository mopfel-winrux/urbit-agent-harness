::  Conversation identity is independent of authorization. Only this hand's
::  routing generations change; the head retains configuration and evidence.
/-  t=harness-tlon, h=harness, a=tlon-activity-ver, cr=harness-cron
/+  p=harness-tlon-policy
|%
+$  authority  $%([%denied ~] [%owner ~] [%trusted tools=(set tool-grant:h)])
++  actor
  |=  event=incoming-event:v8:a
  ^-  (unit @p)
  ?+  -.event  ~
    %dm-post       `p.id.key.event
    %dm-reply      `p.id.key.event
    %post          `p.id.key.event
    %reply         `p.id.key.event
    %group-join    `ship.event
    %group-kick    `ship.event
    %group-role    `ship.event
    %group-ask     `ship.event
    %group-invite  `ship.event
    %contact       `who.event
    %dm-invite     ?:(?=(%ship -.whom.event) `p.whom.event ~)
  ==
++  authority-for
  |=  [policy=policy:t actor=@p]
  ^-  authority
  ?:  =(`actor owner.policy)  [%owner ~]
  =/  tools  (~(get by trusted.policy) actor)
  ?~  tools  [%denied ~]
  [%trusted (silt u.tools)]
++  actor-changed
  |=  [before=policy:t after=policy:t actor=@p]
  ^-  ?
  |(!=(enabled.before enabled.after) !=((authority-for before actor) (authority-for after actor)))
++  cutoffs
  |=  $:  before=policy:t
          new=policy:t
          known=(map [@p destination:t] @t)
          prior=(map @p @da)
          now=@da
      ==
  ^-  (map @p @da)
  ::  Keep unchanged cutoffs. Removed actors without conversations need no
  ::  tombstone: granting them again establishes a fresh cutoff. This bounds
  ::  the map by the identity directory and the two policy snapshots.
  =/  actors=(set @p)
    %-  silt
    :(weld (turn ~(tap by known) |=([[actor=@p to=destination:t] sid=@t] actor)) ~(tap in ~(key by trusted.before)) ~(tap in ~(key by trusted.new)) ?~(owner.before ~ ~[u.owner.before]) ?~(owner.new ~ ~[u.owner.new]))
  %+  roll  ~(tap in actors)
  |=  [actor=@p out=(map @p @da)]
  =/  cutoff=(unit @da)  ?:((actor-changed before new actor) `now (~(get by prior) actor))
  ?~  cutoff  out
  (~(put by out) actor u.cutoff)
++  affected
  |=  [before=policy:t after=policy:t lane=lane:t]
  ^-  ?
  |((actor-changed before after actor.lane) &(?=(%channel -.to.lane) !=(mentions.before mentions.after)))
++  identity
  |=  [actor=@p to=destination:t]
  ^-  @t
  (cat 3 (session-id:p 0 actor to) '-stable')
++  binding
  |=  [sid=@t generation=@ud]
  ^-  @t
  (cat 3 'tlon-binding-' (scot %uv (sham [sid generation])))
++  posted-at
  |=  event=incoming-event:v8:a
  ^-  @da
  ?+  -.event  `@da`0
    %dm-post   time.key.event
    %dm-reply  time.key.event
    %post      time.key.event
    %reply     time.key.event
  ==
++  upgrade
  |=  old=state-10:t
  ^-  state-11:t
  =/  dirs
    %+  roll  ~(tap by lanes.old)
    |=  [[sid=@t lane=lane:t] acc=[identities=(map [@p destination:t] @t) routes=(map @t route:t)]]
    =/  creating  (lien ~(val by jobs.old) |=(job=job:t &(=(sid sid.job) =(%create stage.job))))
    =.  routes.acc  (~(put by routes.acc) sid [sid ?:(creating %create %ready)])
    ?:  (lien ~(val by cron.old) |=(job=job-0:cr =(sid run-sid.job)))  acc
    acc(identities (~(put by identities.acc) [actor.lane to.lane] sid))
  [%11 identities.dirs routes.dirs ~ `@da`0 +.old]
--
