::  Session cleanup through the full head. Emitted effects stay in the sandbox.
/-  h=harness, *harness-store
/+  *test, policy=harness-defaults, hl=harness
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
  =/  config  builtin-config:policy
  =.  defaults.saved  config(tools ~[%web])
  =/  root=session:h  [~[[%config-replaced defaults.saved]] 1]
  =/  child=session:h
    :_  1
    :~  [%input-received [0v1 [%subagent 'source' 'delegate'] ~ ~ ~2026.10.1 [%user 'Child work']]]
        [%config-replaced defaults.saved]
    ==
  =.  sessions.saved
    (my ~[['source' root] ['child' child] ['independent' root]])
  =.  subs.saved  (my ~[['child' ['source' 'delegate']]])
  =.  timers.saved
    %-  my
    :~  [['source' %wake] [~2026.10.2 ~ 'Source timer']]
        [['child' %wake] [~2026.10.2 ~ 'Child timer']]
        [['independent' %wake] [~2026.10.2 ~ 'Other timer']]
    ==
  =.  jobs.saved
    (my ~[[%source-job ['source' 'script' ~2026.10.2]] [%other-job ['independent' 'script' ~2026.10.2]]])
  =.  asks.saved
    (my ~[[0v1 ['source' 'ask' ~nec]] [0v2 ['independent' 'ask' ~nec]]])
  =.  local-mcp.saved
    (my ~[[['source' 'native'] [1 'fixture' 0v1 0 '']] [['independent' 'native'] [1 'fixture' 0v1 0 '']]])
  saved
::
++  test-fence-retires-descendant-work-and-keeps-source-configuration
  %-  isolated  |=  ignored=*
  =/  initial  fixture
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  fenced  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%fence 'source']))
  =/  saved  !<(state-0 ~(on-save +.fenced bowl))
  =/  child  (play:hl log:(~(got by sessions.saved) 'child'))
  ;:  weld
    (expect-eq !>((~(got by sessions.initial) 'source')) !>((~(got by sessions.saved) 'source')))
    (expect-eq !>((~(got by sessions.initial) 'independent')) !>((~(got by sessions.saved) 'independent')))
    (expect-eq !>(~) !>(tools.config.child))
    (expect-eq !>(~[[%user 'Child work']]) !>(items.child))
    (expect-eq !>(~) !>(subs.saved))
    (expect-eq !>((my ~[[['independent' %wake] [~2026.10.2 ~ 'Other timer']]])) !>(timers.saved))
    (expect-eq !>((my ~[[%other-job ['independent' 'script' ~2026.10.2]]])) !>(jobs.saved))
    (expect-eq !>((my ~[[0v2 ['independent' 'ask' ~nec]]])) !>(asks.saved))
    (expect-eq !>((my ~[[['independent' 'native'] [1 'fixture' 0v1 0 '']]])) !>(local-mcp.saved))
  ==
::
++  test-delete-withdraws-each-waiter-once-and-keeps-unrelated-work
  %-  isolated  |=  ignored=*
  =/  initial  fixture
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  deleted  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%delete 'source']))
  =/  saved  !<(state-0 ~(on-save +.deleted bowl))
  =/  stopped
    (skim -.deleted |=(card=card:agent:gall ?=([%pass [%jsstop %source-job ~] *] card)))
  =/  watchdogs
    (skim -.deleted |=(card=card:agent:gall ?=([%pass [%jsdog %source-job ~] %arvo %b %rest *] card)))
  =/  timers
    (skim -.deleted |=(card=card:agent:gall ?=([%pass [%timer %source %wake ~] %arvo %b %rest *] card)))
  =/  native
    (skim -.deleted |=(card=card:agent:gall ?=([%pass [%local-mcp %source *] %agent * %leave ~] card)))
  ;:  weld
    (expect !>(!(~(has by sessions.saved) 'source')))
    (expect !>((~(has by sessions.saved) 'child')))
    (expect-eq !>((~(got by sessions.initial) 'independent')) !>((~(got by sessions.saved) 'independent')))
    (expect-eq !>(1) !>((lent stopped)))
    (expect-eq !>(1) !>((lent watchdogs)))
    (expect-eq !>(1) !>((lent timers)))
    (expect-eq !>(1) !>((lent native)))
    (expect-eq !>((my ~[[%other-job ['independent' 'script' ~2026.10.2]]])) !>(jobs.saved))
    (expect-eq !>((my ~[[0v2 ['independent' 'ask' ~nec]]])) !>(asks.saved))
    (expect-eq !>((my ~[[['independent' %wake] [~2026.10.2 ~ 'Other timer']]])) !>(timers.saved))
  ==
::
++  test-forks-retain-selected-history-after-source-deletion
  %-  isolated  |=  ignored=*
  =/  initial  fixture
  =/  source=session:h
    :_  7
    :~  [%llm-completed 0 %stop [3 2] [%assistant 'Retain this answer' ~]]
        [%config-replaced defaults.initial]
    ==
  =.  sessions.initial  (~(put by sessions.initial) 'source' source)
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  forked  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%fork 'source' 'copy']))
  =/  branched  (~(on-poke +.forked bowl) %harness-action !>(`action:h`[%fork-at 'source' 'branch' 2]))
  =/  deleted  (~(on-poke +.branched bowl) %harness-action !>(`action:h`[%delete 'source']))
  =/  saved  !<(state-0 ~(on-save +.deleted bowl))
  =/  expected=session:h  [[[%forked 'source' 2 ~ ~] log.source] 7]
  ;:  weld
    (expect-eq !>(expected) !>((~(got by sessions.saved) 'copy')))
    (expect-eq !>(expected) !>((~(got by sessions.saved) 'branch')))
    (expect !>(!(~(has by sessions.saved) 'source')))
  ==
--
