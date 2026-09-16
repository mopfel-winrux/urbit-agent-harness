/-  c=harness-corpus, w=harness-workspace, s=harness-workspace-search
/+  *test, work=harness-workspace, wi=harness-workspace-search, search=harness-unified-search, codec=harness-workspace-json
|%
++  owner  `authority:w`[& [0v0 'Owner'] 0v0]
++  db
  ^-  state:w
  =/  a  (apply:work *state:w owner [%artifact-create 'doc' ~ ['Title' 'orchard first' ~]] ~2026.9.11)
  ?>  ?=(%& -.a)
  =/  b  (apply:work p.a owner [%artifact-save 'doc' 1 ~ ['Title' 'orchard second' ~]] ~2026.9.12)
  ?>  ?=(%& -.b)
  p.b
++  idx
  (work:wi (sync:wi *state:s *state:w db ~2026.9.12) db 32 1.000.000)
++  fence  (token:search *state:c idx db ~ 'orchard' &)
++  args
  (pairs:enjs:format ~[['id' %s 'doc'] ['kind' %s 'artifact'] ['query' %s 'orchard'] ['searchToken' %s fence] ['revision' %n '1']])
++  test-one-document-before-pagination
  =/  result  (search:search *state:c idx db ~ owner & 'orchard' ~ 1)
  ?>  ?=(%& -.result)
  =/  hits  (need (get:codec p.result 'hits'))
  ?>  ?=(%a -.hits)
  ?>  ?=(^ p.hits)
  ;:  weld
    (expect-eq !>(1) !>((lent p.hits)))
    (expect-eq !>(2) !>((number:codec i.p.hits 'matchCount' 0)))
    (expect-eq !>(`json`~) !>((need (get:codec p.result 'cursor'))))
  ==
++  test-expand-matching-revisions
  =/  result  (expand:search *state:c idx db ~ owner & args)
  ?>  ?=(%& -.result)
  =/  items  (need (get:codec p.result 'items'))
  ?>  ?=(%a -.items)
  ?>  ?=(^ p.items)
  ;:  weld
    (expect-eq !>(2) !>((lent p.items)))
    (expect-eq !>(2) !>((number:codec i.p.items 'revision' 0)))
  ==
++  test-matched-history-read-is-fenced
  =/  changed=state:w  db
  =.  writes.changed  +(writes.changed)
  =/  accepted  (read:search *state:c idx db ~ owner & args)
  =/  stale  (read:search *state:c idx changed ~ owner & args)
  =/  offline  (read:search *state:c idx db ~ owner | args)
  ;:  weld
    (expect !>(?=(%& -.accepted)))
    (expect !>(?=(%| -.stale)))
    (expect !>(?=(%| -.offline)))
  ==
++  test-private-matches-require-current-authority
  =/  denied=authority:w  [| [0v9 'outsider'] 0v9]
  =/  result  (search:search *state:c idx db ~ denied & 'orchard' ~ 20)
  ?>  ?=(%& -.result)
  (expect-eq !>(`json`[%a ~]) !>((need (get:codec p.result 'hits'))))
++  test-position-codec-and-equal-time-ordering
  =/  position=cursor:search  [~2026.9.11 %artifact 'doc' 0]
  =/  conversation=cursor:search  [~2026.9.11 %conversation '' 4]
  ;:  weld
    (expect-eq !>(`position) !>((decode:search fence (encode:search fence position))))
    (expect-eq !>(`(unit cursor:search)`~) !>((decode:search 'changed' (encode:search fence position))))
    (expect !>((before:search conversation position)))
    (expect !>(!(before:search position conversation)))
  ==
--
