::  Native Notes observation and recovery through the full head. No cards
::  are delivered; a saved send fence represents an already dispatched write.
/-  hn=harness-notes, work=harness-workspace, *harness-store
/+  *test, policy=harness-defaults, notes=harness-notes
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
  =.  saved  saved(defaults builtin-config:policy, local-mcp-seen 1)
  =/  args=json  (pairs:enjs:format ~[['title' %s 'Draft'] ['body' %s 'Body']])
  =/  prepared
    (prepare:notes workspace.saved workspace-notes.saved [%native 'original'] 'artifact-create' args 'doc' ~2026.10.1 0v1)
  ?>  ?=(%& -.prepared)
  saved(workspace-notes workspace-notes.saved(pending `p.prepared(sent &)))
::
++  sends
  |=  cards=(list card:agent:gall)
  ^-  (list card:agent:gall)
  %+  skim  cards
  |=(card=card:agent:gall ?=([%pass * %agent * %poke %notes-action-1 *] card))
::
++  test-reload-and-resume-observe-without-resending-a-native-write
  %-  isolated  |=  ignored=*
  =/  saved  fixture
  =/  request-id  (request-id:notes (need pending.workspace-notes.saved))
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  acknowledged
    (~(on-agent +.loaded bowl) /artifact-notes/request/(scot %uv request-id) [%watch-ack ~])
  =/  failed
    (~(on-agent +.acknowledged bowl) /artifact-notes/send/(scot %uv request-id) [%poke-ack `~[leaf+"transport failed"]])
  =/  uncertain  !<(state-0 ~(on-save +.failed bowl))
  =/  stale
    (~(on-agent +.failed bowl) /artifact-notes/request/(scot %uv +(request-id)) [%kick ~])
  =/  after-stale  !<(state-0 ~(on-save +.stale bowl))
  =/  args=json  (pairs:enjs:format ~[['id' %s '0v1']])
  =/  resumed
    (~(on-poke +.stale bowl) %harness-workspace !>(`request:work`['resume' 'notes-resume' args]))
  =/  after  !<(state-0 ~(on-save +.resumed bowl))
  =/  pending  (need pending.workspace-notes.after)
  ;:  weld
    (expect !>(sent.pending))
    (expect !>(uncertain.pending))
    (expect-eq !>(workspace-notes.uncertain) !>(workspace-notes.after-stale))
    (expect-eq !>(workspace-notes.uncertain) !>(workspace-notes.after))
    (expect-eq !>(~) !>((sends :(weld -.loaded -.acknowledged -.failed -.stale -.resumed))))
    (expect !>((lien -.resumed |=(card=card:agent:gall ?=([%pass [%artifact-notes %request *] %agent * %watch *] card)))))
  ==
::
++  test-release-requires-the-current-operation-and-explicit-confirmation
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  args=json  (pairs:enjs:format ~[['id' %s '0v1'] ['confirm' %s 'release another-operation']])
  =/  denied
    (~(on-poke +.loaded bowl) %harness-workspace !>(`request:work`['deny' 'notes-release' args]))
  =/  before  !<(state-0 ~(on-save +.denied bowl))
  =/  confirmed=json  (pairs:enjs:format ~[['id' %s '0v1'] ['confirm' %s 'release 0v1']])
  =/  released
    (~(on-poke +.denied bowl) %harness-workspace !>(`request:work`['release' 'notes-release' confirmed]))
  =/  after  !<(state-0 ~(on-save +.released bowl))
  ;:  weld
    (expect !>(?=(^ pending.workspace-notes.before)))
    (expect-eq !>(~) !>(pending.workspace-notes.after))
    (expect-eq !>(artifacts.workspace.before) !>(artifacts.workspace.after))
    (expect-eq !>('notes-release') !>(action:(snag 0 history.workspace.after)))
    (expect-eq !>(~) !>((sends -.released)))
    (expect !>((lien -.released |=(card=card:agent:gall ?=([%pass [%artifact-notes %request *] %agent * %leave ~] card)))))
  ==
--
