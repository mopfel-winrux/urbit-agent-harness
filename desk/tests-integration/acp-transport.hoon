::  Exercise the durable transport without delivering its cards.
/-  ac=acp
/+  *test
/=  transport  /app/acp
|%
++  bowl
  ^-  bowl:gall
  =/  value  *bowl:gall
  value(our ~zod, src ~zod, now ~2026.10.1)
++  start
  +:~(on-init transport bowl)
++  poke
  |=  [agent=agent:gall action=action:v1:ac]
  (~(on-poke agent bowl) %acp-action-1 !>(action))
++  saved
  |=  agent=agent:gall
  =/  state
    !<([%0 connections=(map connection-id:v1:ac connection:v1:ac)] ~(on-save agent bowl))
  connections.state
++  updates
  |=  cards=(list card:agent:gall)
  ^-  (list update:v1:ac)
  %+  murn  cards
  |=  card=card:agent:gall
  ^-  (unit update:v1:ac)
  ?.  ?=([%give %fact * %acp-update-1 *] card)  ~
  =/  [give=* fact=* paths=* mark=* data=vase]  card
  `!<(update:v1:ac data)
++  test-ordered-replay-and-cumulative-acknowledgements
  =/  opened  (poke start [%open 'fixture'])
  =/  one  (poke +.opened [%send 'fixture' %agent 'one'])
  =/  two  (poke +.one [%send 'fixture' %agent 'two'])
  =/  client  (poke +.two [%send 'fixture' %client 'reply'])
  =/  replay  (~(on-watch +.client bowl) /v1/fixture/agent)
  =/  shared  (~(on-watch +.client bowl) /v1/agent)
  =/  acked  (poke +.client [%ack 'fixture' %agent 1])
  =/  remaining  (~(on-watch +.acked bowl) /v1/fixture/agent)
  =/  connection  (~(got by (saved +.acked)) 'fixture')
  =/  messages=(list message:v1:ac)
    ~[[1 now:bowl 'one'] [2 now:bowl 'two']]
  ;:  weld
      (expect-eq !>(2) !>((lent -.one)))
      (expect-eq !>(1) !>((lent -.client)))
      %+  expect-eq
        !>  ^-  (list update:v1:ac)
            ~[[%connection 'fixture' & ~] [%messages 'fixture' %agent messages]]
      !>((updates -.replay))
      %+  expect-eq
        !>(`(list update:v1:ac)`~[[%messages 'fixture' %agent messages]])
      !>((updates -.shared))
      %+  expect-eq
        !>  ^-  (list update:v1:ac)
            ~[[%connection 'fixture' & ~] [%messages 'fixture' %agent (slag 1 messages)]]
      !>((updates -.remaining))
      (expect-eq !>([2 3]) !>([next-to-client.connection next-to-agent.connection]))
      (expect-eq !>([1 1]) !>([~(wyt by to-client.connection) ~(wyt by to-agent.connection)]))
      (expect-eq !>(~) !>(-.acked))
  ==
++  test-close-retains-queued-messages-until-acknowledged
  =/  opened  (poke start [%open 'fixture'])
  =/  sent  (poke +.opened [%send 'fixture' %client 'pending'])
  =/  closed  (poke +.sent [%close 'fixture' 'done'])
  =/  repeated  (poke +.closed [%close 'fixture' 'done'])
  =/  blocked  (mule |.((poke +.closed [%drop 'fixture'])))
  =/  rejected  (mule |.((poke +.closed [%send 'fixture' %client 'later'])))
  =/  acked  (poke +.closed [%ack 'fixture' %client 1])
  =/  dropped  (poke +.acked [%drop 'fixture'])
  ;:  weld
      %+  expect-eq
        !>  ^-  (list update:v1:ac)
            ~[[%connection 'fixture' | `'done'] [%connection 'fixture' | `'done']]
      !>((updates -.closed))
      (expect-eq !>(~) !>(-.repeated))
      (expect !>(?=(%| -.blocked)))
      (expect !>(?=(%| -.rejected)))
      (expect-eq !>(0) !>(~(wyt by (saved +.dropped))))
  ==
++  test-transport-rejects-remote-and-invalid-admission
  =/  foreign  bowl
  =.  src.foreign  ~nec
  =/  remote
    (mule |.((~(on-poke start foreign) %acp-action-1 !>(`action:v1:ac`[%open 'fixture']))))
  =/  invalid  (mule |.((poke start [%open 'Bad ID'])))
  =/  missing  (mule |.((poke start [%send 'missing' %agent 'payload'])))
  ;:  weld
      (expect !>(?=(%| -.remote)))
      (expect !>(?=(%| -.invalid)))
      (expect !>(?=(%| -.missing)))
  ==
--
