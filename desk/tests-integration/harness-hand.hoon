::  Hand admission through the full head. Effects stay inside the sandbox.
/-  h=harness, hh=harness-hand, *harness-store
/+  *test, policy=harness-defaults, hd=harness-hand, hl=harness
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  result  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.result)
  ;;(tang product.result)
::
++  bowl
  ^-  bowl:gall
  =/  value  *bowl:gall
  value(our ~zod, src ~zod, now ~2026.10.1)
::
++  fixture
  ^-  state-0
  =/  saved  *state-0
  =.  saved
    %=  saved
      defaults  builtin-config:policy
      local-mcp-seen  1
      provider-keys  (my ~[['openrouter' 'fixture-key']])
    ==
  =.  url.defaults.saved  'https://openrouter.ai/api/v1/chat/completions'
  =/  events=(list event:h)
    :~  [%llm-requested 0 %turn]
        [%input-admitted [%user 'Running']]
        [%config-replaced defaults.saved]
    ==
  =.  sessions.saved  (my ~[['source' [events 1]] ['other' [events 1]]])
  =.  bindings.hands.saved
    %-  my
    :~  ['source' ['fixture' 'source-room' 'source' ~['alice'] &]]
        ['other' ['fixture' 'other-room' 'other' ~['alice'] &]]
    ==
  =/  running  (apply:hd hands.saved [%observe 'source' 'running' 'alice' 'Running'] ~2026.10.1)
  ?>  ?=(%& -.running)
  =/  queued  (apply:hd db.p.running [%observe 'source' 'waiting' 'alice' 'Waiting'] ~2026.10.1)
  ?>  ?=(%& -.queued)
  =/  unrelated
    %^  apply:hd
      db.p.queued
      [%observe 'other' 'unrelated' 'alice' 'Other work']
    ~2026.10.1
  ?>  ?=(%& -.unrelated)
  saved(hands (start:hd db.p.unrelated 'source' (input-id:hd 'source' 'running')))
::
++  test-stop-preserves-receipts-and-replay-cannot-cancel-new-work
  %-  isolated
  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  stop=request:hh  ['stop' [%observe 'source' 'stop-event' 'alice' '/stop']]
  =/  stopped  (~(on-poke +.loaded bowl) %harness-hand !>(stop))
  =/  saved  !<(state-0 ~(on-save +.stopped bowl))
  =/  running  (input-id:hd 'source' 'running')
  =/  waiting  (input-id:hd 'source' 'waiting')
  =/  stop-id  (input-id:hd 'source' 'stop-event')
  =/  unrelated  (input-id:hd 'other' 'unrelated')
  =/  restarted
    %+  ~(on-poke +.stopped bowl)
      %harness-action
    !>(`action:h`[%send 'source' 'New work'])
  =/  before  !<(state-0 ~(on-save +.restarted bowl))
  =/  current  (play:hl log:(~(got by sessions.before) 'source'))
  ?>  ?=(^ pending.current)
  =/  replayed  (~(on-poke +.restarted bowl) %harness-hand !>(stop))
  =/  after  !<(state-0 ~(on-save +.replayed bowl))
  ;:  weld
      %+  expect-eq
        !>(%cancelled)
      !>(phase:(~(got by observations.hands.saved) running))
      (expect-eq !>(%cancelled) !>(kind:(~(got by outbox.hands.saved) running)))
      %+  expect-eq
        !>(%cancelled)
      !>(phase:(~(got by observations.hands.saved) waiting))
      %+  expect-eq
        !>(%completed)
      !>(phase:(~(got by observations.hands.saved) stop-id))
      (expect-eq !>(%reply) !>(kind:(~(got by outbox.hands.saved) stop-id)))
      (expect-eq !>(`(list input-id:h)`~[unrelated]) !>(queue.hands.saved))
      (expect-eq !>(hands.before) !>(hands.after))
      (expect-eq !>(sessions.before) !>(sessions.after))
      %-  expect
      !>(!(lien -.replayed |=(card=card:agent:gall ?=([%pass * %arvo %i %cancel-request *] card))))
  ==
--
