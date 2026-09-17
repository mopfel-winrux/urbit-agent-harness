/-  *harness-store, c=harness-work-control, w=harness-workspace
/+  *test, storage=harness-store, control=harness-work-control, j=harness-workspace-json
|%
++  test-v26-draft-recency-uses-proposal-evidence-without-an-accepted-revision
  =/  saved=state-26  *state-26
  =.  artifacts.workspace.saved  (my ~[['draft' [0v1 ~ 'Draft' 0 ~ ~ 0 |]]])
  =.  proposals.workspace.saved
    (my ~[['draft' ['draft' 0 [0v1 'Agent'] 0v1 ~2026.9.12 ['Draft' 'Unaccepted body' ~] 'Review' %rejected `~2026.9.13 'Keep private' ~]]])
  =/  loaded  (load:storage !>(saved))
  ;:  weld
    (expect-eq !>(workspace.saved) !>(+>.workspace.loaded))
    (expect-eq !>(`~2026.9.13) !>((~(get by recency.workspace.loaded) [%artifact 'draft'])))
  ==
++  test-v26-recency-preserves-workspace-and-runtime
  =/  saved=state-26  *state-26
  =.  api-key.saved  'retained-test-key'
  =.  projects.workspace.saved  (my ~[['dated' ['Dated' '' 1 ~ |]] ['undated' ['Undated' '' 1 ~ |]]])
  =.  artifacts.workspace.saved
    (my ~[['doc' [0v0 ~ 'Title' 1 (my ~[[1 [~2026.9.11 [0v0 'Owner'] ['Title' 'Retained body' ~]]]]) ~ 0 |]]])
  =.  history.workspace.saved  ~[[~2026.9.12 [0v0 'Owner'] 'project-edit' 'dated']]
  =.  writes.workspace.saved  77
  =/  loaded  (load:storage !>(saved))
  =/  [%26 * %24 * %23 * %22 * * %21 * before=state-20]  saved
  =/  [%28 * %27 * * * * * * after=state-20]  loaded
  ;:  weld
    (expect-eq !>(workspace.saved) !>(+>.workspace.loaded))
    (expect-eq !>(before) !>(after))
    (expect-eq !>(legacy-workspace.saved) !>(legacy-workspace.loaded))
    (expect-eq !>(work-controls.saved) !>(work-controls.loaded))
    (expect-eq !>(`~2026.9.12) !>((~(get by recency.workspace.loaded) [%project 'dated'])))
    (expect-eq !>(`~2026.9.11) !>((~(get by recency.workspace.loaded) [%artifact 'doc'])))
    (expect-eq !>(`(unit @da)`~) !>((~(get by recency.workspace.loaded) [%project 'undated'])))
    (expect-eq !>(loaded) !>((load:storage !>(loaded))))
  ==
++  test-v25-valid-witnesses-migrate-without-refreshing-stale-approvals
  =/  saved=state-25  *state-25
  =.  projects.workspace.saved  (my ~[['project' ['Project' '' 1 ~ |]]])
  =/  args  (pairs:enjs:format ~[['id' %s 'project'] ['version' %n '1'] ['title' %s 'Edited']])
  =/  r=request:c  ['owner' 0v1 [%poke ~zod] `~zod 'project-edit' args (fence-25:storage saved 'project-edit' args) ~2026.9.14 %pending ~]
  =.  requests.work-controls.saved  (my ~[[0v1 r] [0v2 r(fence 0v0)] [0v3 r(status %done, result `[%& [%s 'Retained receipt']])]])
  =/  loaded  (load:storage !>(saved))
  =/  expected  (fence:control (restore-workspace:storage workspace.saved) hands.saved names.corpus.saved owners.work-controls.saved 'project-edit' args)
  ;:  weld
    (expect-eq !>(r(fence expected)) !>((~(got by requests.work-controls.loaded) 0v1)))
    (expect-eq !>(r(fence 0v0)) !>((~(got by requests.work-controls.loaded) 0v2)))
    (expect-eq !>(result:(~(got by requests.work-controls.saved) 0v3)) !>(result:(~(got by requests.work-controls.loaded) 0v3)))
    (expect-eq !>(workspace.saved) !>(+>.workspace.loaded))
    (expect-eq !>(hands.saved) !>(hands.loaded))
    (expect-eq !>(loaded) !>((load:storage !>(loaded))))
  ==
++  test-v25-queued-reply-keeps-exact-delivery-witness
  =/  saved=state-25  *state-25
  =.  bindings.hands.saved  (my ~[['binding' ['fixture' 'dm/alice' 'target' ~['alice'] &]]])
  =/  args  (pairs:enjs:format ~[['id' %s 'task'] ['artifact' %s 'doc'] ['revision' %n '1'] ['binding' %s 'binding'] ['actor' %s 'alice']])
  =/  r=request:c  ['owner' 0v1 [%poke ~zod] `~zod 'task-reply' args (fence-25:storage saved 'task-reply' args) ~2026.9.14 %done `[%& [%s 'Queued']]]
  =.  requests.work-controls.saved  (my ~[[0v1 r]])
  =/  loaded  (load:storage !>(saved))
  =/  expected  (fence:control (restore-workspace:storage workspace.saved) hands.saved names.corpus.saved owners.work-controls.saved 'task-reply' args)
  =/  changed  saved
  =.  bindings.hands.changed  (my ~[['binding' ['fixture' 'dm/bob' 'target' ~['alice'] &]]])
  =/  stale  (load:storage !>(changed))
  ;:  weld
    (expect-eq !>(r(fence expected)) !>((~(got by requests.work-controls.loaded) 0v1)))
    (expect-eq !>(r) !>((~(got by requests.work-controls.stale) 0v1)))
    (expect-eq !>(`0v1) !>((reply-request:control work-controls.loaded args)))
    (expect-eq !>(hands.saved) !>(hands.loaded))
  ==
++  test-v25-hand-access-needs-a-new-destination-bound-preview
  =/  saved=state-25  *state-25
  =/  args  (pairs:enjs:format ~[['binding' %s 'binding'] ['actor' %s 'alice'] ['owner' %b &]])
  =/  r=request:c  ['owner' 0v1 [%poke ~zod] `~zod 'hand-access' args (fence-25:storage saved 'hand-access' args) ~2026.9.14 %pending ~]
  =.  requests.work-controls.saved  (my ~[[0v1 r]])
  =/  loaded  (load:storage !>(saved))
  =/  current  (fence:control workspace.loaded hands.loaded names.corpus.loaded owners.work-controls.loaded 'hand-access' args)
  ;:  weld
    (expect-eq !>(r) !>((~(got by requests.work-controls.loaded) 0v1)))
    (expect !>(!=(fence.r current)))
  ==
--
