::  Shared notes are head-local bookkeeping, not an execution lifecycle.
/-  h=harness, *harness-store
/+  *test, policy=harness-defaults
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  test-notes-record-and-complete-without-claims-agents-or-approvals
  %-  isolated  |=  ignored=*
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.14)
  =/  saved=state-0  *state-0
  =.  saved  saved(welcome-seen 1, defaults builtin-config:policy)
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  created  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%new 'owner' defaults.saved ~s30]))
  =/  before  !<(state-0 ~(on-save +.created bowl))
  =/  noted  (~(on-poke +.created bowl) %harness-action !>(`action:h`[%send 'owner' '/work task-create {"id":"note","title":"Check the forecast"}']))
  =/  recorded  !<(state-0 ~(on-save +.noted bowl))
  =/  updated  (~(on-poke +.noted bowl) %harness-action !>(`action:h`[%send 'owner' '/work task-update {"id":"note","version":1,"status":"done","outcome":"Answered in the conversation."}']))
  =/  after  !<(state-0 ~(on-save +.updated bowl))
  =/  stale  (~(on-poke +.updated bowl) %harness-action !>(`action:h`[%send 'owner' '/work task-update {"id":"note","version":1,"status":"open"}']))
  =/  final  !<(state-0 ~(on-save +.stale bowl))
  =/  edited  (~(on-poke +.stale bowl) %harness-action !>(`action:h`[%send 'owner' '/work task-update {"id":"note","version":2,"title":"Forecast answered","description":"A completed request"}']))
  =/  changed  !<(state-0 ~(on-save +.edited bowl))
  =/  deleted  (~(on-poke +.edited bowl) %harness-action !>(`action:h`[%send 'owner' '/work task-delete {"id":"note","version":3}']))
  =/  removed  !<(state-0 ~(on-save +.deleted bowl))
  =/  replies  (murn log:(~(got by sessions.after) 'owner') |=(e=event:h ?:(?=(%command-completed -.e) `body.e ~)))
  ?>  ?=(^ replies)
  ;:  weld
    (expect-eq !>('Check the forecast') !>(title:(~(got by tasks.workspace.recorded) 'note')))
    (expect-eq !>(%done) !>(status:(~(got by tasks.workspace.after) 'note')))
    (expect-eq !>(~) !>(artifact:(~(got by tasks.workspace.after) 'note')))
    (expect-eq !>('') !>(project:(~(got by tasks.workspace.after) 'note')))
    (expect-eq !>(~) !>(requests.work-controls.after))
    (expect-eq !>(projects.workspace.before) !>(projects.workspace.after))
    (expect-eq !>(~(key by sessions.before)) !>(~(key by sessions.after)))
    (expect-eq !>(workspace.after) !>(workspace.final))
    (expect-eq !>('Forecast answered') !>(title:(~(got by tasks.workspace.changed) 'note')))
    (expect-eq !>(%done) !>(status:(~(got by tasks.workspace.changed) 'note')))
    (expect-eq !>('Answered in the conversation.') !>(outcome:(~(got by tasks.workspace.changed) 'note')))
    (expect-eq !>(~) !>(tasks.workspace.removed))
    (expect-eq !>(~) !>(requests.work-controls.removed))
    (expect-eq !>(projects.workspace.before) !>(projects.workspace.removed))
    (expect-eq !>(artifacts.workspace.before) !>(artifacts.workspace.removed))
    (expect-eq !>(~(key by sessions.before)) !>(~(key by sessions.removed)))
    (expect !>(?=(^ (find (trip 'Answered in the conversation.') (trip i.replies)))))
    (expect !>(!(lien (weld -.noted -.updated) |=(c=card:agent:gall ?=([%pass * %arvo %i *] c)))))
  ==
--
