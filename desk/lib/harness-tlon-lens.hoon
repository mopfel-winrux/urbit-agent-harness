::  Steward's owner-only, redacted presentation of existing Harness evidence.
/-  t=harness-tlon, hh=harness-hand, sl=tlon-steward-lens
/+  rr=harness-run-report, p=harness-tlon-policy
|%
++  revoke
  |=  record=lens-export:t
  ^-  lens-export:t
  ?:  =(%accepted status.record)  record
  record(status %revoked)
++  acknowledge
  |=  [record=lens-export:t revision=@ud accepted=?]
  ^-  lens-export:t
  ?.  &(=(%sending status.record) =(revision revision.record))  record
  record(status ?:(accepted %accepted %failed))
++  id
  |=  input=@uv
  ^-  @t
  (cat 3 'harness-' (scot %uv input))
++  millis
  |=  time=@da
  ^-  @ud
  ?:  (lth time ~1970.1.1)  0
  (div (mul (sub time ~1970.1.1) 1.000) ~s1)
++  pointer
  |=  [ship=@p input=@uv]
  ^-  @t
  %-  en:json:html
  [%a ~[(pairs:enjs:format ~[['type' %s 'tlon-context-lens'] ['version' %n '1'] ['lensId' %s (id input)] ['botShip' %s (scot %p ship)]])]]
++  entry
  |=  [owner=@p input=@uv revision=@ud payload=json]
  ^-  card:agent:gall
  [%pass /lens/(scot %uv input)/(scot %ud revision) %agent [owner %steward] %poke %steward-lens-action-1 !>(`action:v1:sl`[%entry (id input) payload &])]
++  tool-json
  |=  [index=@ud c=call:rr]
  ^-  json
  =/  status  ?:  ?=(?(%unknown %uncertain) status.c)  %blocked
    status.c
  =/  phase=@t
    ?+  status.c  'Recorded tool result; payload and per-call timing are not exported'
      %unknown    'No terminal tool receipt; this is not proof of failure'
      %uncertain  'Acceptance is unknown; do not automatically repeat this action'
      %blocked    'Rejected by the execution boundary'
      %error      'Tool reported failure; details remain private'
    ==
  (pairs:enjs:format ~[['id' %s (cat 3 'call-' (scot %ud index))] ['callIndex' (numb:enjs:format index)] ['name' %s name.c] ['status' %s status] ['phase' %s phase] ['startedAt' %n '0'] ['completedAt' ~] ['durationMs' ~]])
++  payload
  |=  [our=@p input=@uv pub=publication:hh obs=observation:hh to=destination:t summary=(unit report:rr) at=@da attempt=@ud scheduled=? stamp=(unit @da)]
  ^-  json
  =/  report  (fall summary `report:rr`[~ 0 &])
  =/  rows=(list json)  ~
  =/  called=(set @t)  ~
  =/  calls  (flop calls.report)
  =/  index=@ud  0
  =^  rows  called
    |-  ^-  [(list json) (set @t)]
    ?~  calls  [(flop rows) called]
    $(calls t.calls, index +(index), rows [(tool-json +(index) i.calls) rows], called (~(put in called) name.i.calls))
  =/  sent=?  =(%delivered status.pub)
  =/  channel=?  ?=(%channel -.to)
  =/  conversation  ?:  ?=(%channel -.to)  (address:p to(parent ~))
    (scot %p who.to)
  =/  status=@t  ?:  =(%failure kind.pub)  'error'
    ?:  =(%cancelled kind.pub)  'aborted'
    'completed'
  =/  evidence=@t
    ?+  status.pub  'Reply has not been sent. Run completion is not delivery.'
      %claimed    'Reply dispatch is in progress; acceptance is not confirmed.'
      %delivered  ?:(channel 'Channel host confirmed the reply; this is not a read receipt.' 'Local Messenger accepted the DM; remote receipt is not confirmed.')
      %failed     'Messenger rejected the reply.'
      %uncertain  'Reply acceptance is uncertain. Lens never retries messages.'
      %abandoned  'The owner abandoned this publication.'
    ==
  =/  updated  ?~(receipts.pub at (max at at.i.receipts.pub))
  =/  context
    %-  pairs:enjs:format
    :~  ['currentMessage' %b &]
        ['threadMessages' %n '0']
        ['channelMessages' %n '0']
        ['citedPosts' %n '0']
        ['attachments' %n '0']
        ['pendingNudge' %b |]
        ['sources' %a ~[(pairs:enjs:format ~[['kind' %s 'other'] ['label' %s 'Conversation context'] ['included' %b &] ['reason' %s 'Context contents and source counts are not exported; zero counters mean unreported.']])]]
    ==
  =/  persistence
    %-  pairs:enjs:format
    :~  ['postsReply' %b sent]
        ['updatesSettings' %b |]
        ['writesMedia' %b |]
        ['emitsTelemetry' %b &]
        ['cachesHistory' %b |]
        ['events' %a ~[(pairs:enjs:format ~[['kind' %s 'other'] ['action' %s 'updated'] ['location' %s 'urbit'] ['status' %s ?:(sent 'ok' 'skipped')] ['reason' %s evidence] ['at' (numb:enjs:format (millis updated))]])]]
    ==
  =/  tools
    (pairs:enjs:format ~[['ownerOnlyAvailable' %a ~] ['called' %a (turn ~(tap in called) |=(name=@t `json`[%s name]))] ['callCount' (numb:enjs:format count.report)] ['lastStartedAt' ~] ['runs' %a rows]])
  =/  lifecycle
    (pairs:enjs:format ~[['queuedMs' %n '0'] ['durationMs' ~] ['timeoutMs' ~] ['timedOut' %b |] ['deliveredMessageCount' %n ?:(sent '1' '0')] ['queuedFinal' %b ?=(?(%pending %claimed) status.pub)] ['queuedFinalCount' %n ?:(?=(?(%pending %claimed) status.pub) '1' '0')] ['queuedBlockCount' %n '0']])
  =/  lens
    %-  pairs:enjs:format
    :~  ['lensId' %s (id input)]
        ['messageId' %s '']
        ['harnessInputId' %s (scot %uv input)]
        ['chatType' %s ?:(channel 'channel' 'dm')]
        ['runKind' %s ?:(scheduled 'cron' 'conversation')]
        ['visibility' %s 'owner']
        ['trigger' %s ?:(scheduled 'cron' 'message')]
        ['triggerDetails' (pairs:enjs:format ~[['type' %s ?:(scheduled 'cron' 'message')] ['messageId' %s ''] ['authorShip' %s actor.obs] ['conversationId' %s conversation] ['conversationKind' %s ?:(channel 'channel' 'dm')] ['receivedAt' (numb:enjs:format (millis at.obs))]])]
        ['model' ~]
        ['provider' ~]
        ['status' %s status]
        ['error' ?:(=(%reply kind.pub) ~ [%s 'The run did not complete successfully. Details remain in Harness; Lens Retry does not rerun work.'])]
        ['createdAt' (numb:enjs:format (millis at.obs))]
        ['updatedAt' (numb:enjs:format (millis updated))]
        ['context' context]
        ['persistence' persistence]
        ['tools' tools]
        ['lifecycle' lifecycle]
        :-  'outputs'
        :-  %a
        ?:  |(!sent ?=(~ stamp))  ~
        ~[(pairs:enjs:format ~[['messageId' %s (rap 3 (scot %p our) '/' (scot %ud u.stamp) ~)] ['conversationId' %s conversation] ['kind' %s ?:(channel 'channel' 'dm')] ['sentAt' (numb:enjs:format (millis u.stamp))]])]
        ['delivery' (pairs:enjs:format ~[['status' %s status.pub] ['attempt' (numb:enjs:format attempt)] ['evidence' %s evidence]])]
        ['reportTruncated' %b truncated.report]
        ['retrySupported' %b |]
    ==
  (pairs:enjs:format ~[['schemaVersion' %n '1'] ['lens' lens]])
++  status
  |=  [owner=(unit @p) exports=(map @uv lens-export:t)]
  ^-  json
  =/  rows  ~(val by exports)
  =/  count
    |=  wanted=@t
    ^-  @ud
    (lent (skim rows |=(r=lens-export:t =(wanted status.r))))
  (pairs:enjs:format ~[['owner' ?~(owner ~ [%s (scot %p u.owner)])] ['pending' (numb:enjs:format (add (count %sending) (count %queued)))] ['accepted' (numb:enjs:format (count %accepted))] ['failed' (numb:enjs:format (count %failed))] ['revoked' (numb:enjs:format (count %revoked))]])
--
