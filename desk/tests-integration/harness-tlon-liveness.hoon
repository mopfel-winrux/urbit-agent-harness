::  Native readiness updates the public badge; all effects stay in the fixture.
/-  t=harness-tlon, ct=tlon-contacts, hh=harness-hand, ad=harness-adapter
/+  *test, policy=harness-tlon-policy
/=  adapter  /app/harness-tlon
|%
++  run
  |=  $:  enabled=?  head=?  contact=(unit contact:ct)
          event=?(%load %disable %enable %kick %recover %nack)
      ==
  ^-  (list contact:ct)
  =/  saved=state-2:t  *state-2:t
  =.  saved
    %=  saved  owner-initialized  1  policy  [enabled `~zod ~ %mentions ~ ~]  watching  &
      activity-through  ~2026.10.1
    ==
  =/  =bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.10.1..00.00.10)
  =.  wex.bowl
    %-  my
    ~[[[/head ~zod %harness] [head /hand-events]] [[/activity ~zod %activity] [& /v4]]]
  =/  attempt
    |.
    =/  loaded  (~(on-load adapter bowl) !>(saved))
    =/  out
      ?-  event
        %load  loaded
          %kick
        =/  gone  bowl(wex (~(del by wex.bowl) [/activity ~zod %activity]))
        (~(on-agent +.loaded gone) /activity [%kick ~])
        %recover  (~(on-agent +.loaded bowl) /activity [%watch-ack ~])
        %nack  (~(on-agent +.loaded bowl) /liveness [%poke-ack `~])
          ?(%enable %disable)
        =/  params  (policy-json:policy policy.saved(enabled =(%enable event)))
        %+  ~(on-poke +.loaded bowl)
          %noun
        !>(`request:ad`['fixture' [%n '1'] 'harness/tlon/configure' `params])
      ==
    %+  murn  -.out
    |=  card=card:agent:gall
    ^-  (unit contact:ct)
    ?.  ?=([%pass [%liveness ~] %agent * %poke %contact-action-1 *] card)  ~
    =/  [pass=* wire=* agent=* who=* poke=* mark=* data=vase]  card
    =/  action  !<(action:ct data)
    ?>  ?=(%self -.action)
    `+.action
  =/  checked
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  ?=([%gu @ %contacts @ %$ ~] path)  ``?=(^ contact)
    ?:  =(%$ (rear path))  ``&
    ?:  ?=([%gx @ %contacts @ %v1 %self %contact-1 ~] path)
      ?~(contact `~ ``u.contact)
    ?:  ?=([%gx @ %chat @ %dm %invited %ships ~] path)  ``~
    ?:  (lien path |=(part=@ta =(%hand-state part)))  ``*state:hh
    ?:  (lien path |=(part=@ta =(%activity part)))  ``~
    ~
  ?>  ?=(%0 -.checked)
  ;;((list contact:ct) product.checked)
++  online
  (my ~[[%bot-liveness [%text '{"v":1,"state":"online"}']]])
++  offline
  (my ~[[%bot-liveness [%text '{"v":1,"state":"offline"}']]])
++  test-reload-repairs-offline-badge-and-current-badge-is-quiet
  ;:  weld
      (expect-eq !>(~[online]) !>((run & & `offline %load)))
      (expect-eq !>(`(list contact:ct)`~) !>((run & & `online %load)))
  ==
++  test-disabled-or-disconnected-hand-is-offline
  ;:  weld
      (expect-eq !>(~[offline]) !>((run | & `online %load)))
      (expect-eq !>(~[offline]) !>((run & | `online %load)))
      (expect-eq !>(~[offline]) !>((run & & `online %kick)))
      (expect-eq !>(~[online]) !>((run & & `offline %recover)))
  ==
++  test-enable-and-disable-update-liveness
  ;:  weld
      (expect-eq !>(~[online]) !>((run | & `offline %enable)))
      (expect-eq !>(~[offline]) !>((run & & `online %disable)))
  ==
++  test-unavailable-contacts-and-nacks-do-not-loop-or-block-the-hand
  ;:  weld
      (expect-eq !>(`(list contact:ct)`~) !>((run & & ~ %load)))
      (expect-eq !>(`(list contact:ct)`~) !>((run & & `offline %nack)))
  ==
--
