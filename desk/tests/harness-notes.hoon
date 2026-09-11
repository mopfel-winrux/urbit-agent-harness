/-  n=tlon-notes, w=harness-workspace, hn=harness-notes
/+  *test, notes=harness-notes, work=harness-workspace
|%
++  fixture
  ^-  state:w
  =/  out  (apply:work *state:w [& [0v0 'Owner'] 0v0] [%artifact-create 'doc' ~ ['Title' 'Body' ~]] ~2026.9.11)
  ?>  ?=(%& -.out)
  p.out
++  test-projection-preserves-unrelated-workspace-state
  =/  db=state:w  fixture
  =.  writes.db  37
  ;:  weld
    (expect-eq !>(db) !>((project-book:notes db *state:hn *notebook-state:n)))
    (expect-eq !>(db) !>((project-update:notes db *state:hn [%note 999 %deleted ~])))
  ==
++  test-native-deletion-only-removes-the-linked-artifact
  =/  db=state:w  fixture
  =.  writes.db  37
  =/  native=state:hn  *state:hn
  =.  links.native  (~(put by links.native) 'doc' [42 ~ ~])
  =/  expected  db(artifacts ~, writes 38)
  ;:  weld
    (expect-eq !>(expected) !>((project-book:notes db native *notebook-state:n)))
    (expect-eq !>(expected) !>((project-update:notes db native [%note 42 %deleted ~])))
  ==
++  test-native-public-path
  (expect-eq !>('/notes/pub/~zod/harness/42') !>((public-path:notes [~zod %harness] 42)))
++  test-decorating-empty-pages-preserves-json-null
  =/  page=json  (pairs:enjs:format ~[['items' %a ~] ['nextOffset' ~] ['referenceOnly' %b &]])
  =/  nested=json  [%a ~[~ page [%s 'unchanged']]]
  ;:  weld
    (expect-eq !>(`json`~) !>((decorate:notes *state:hn ~)))
    (expect-eq !>(page) !>((decorate:notes *state:hn page)))
    (expect-eq !>(nested) !>((decorate:notes *state:hn nested)))
  ==
++  test-create-is-native-and-has-no-accepted-projection
  =/  args=json  (pairs:enjs:format ~[['title' %s 'Draft'] ['body' %s 'Native body']])
  =/  out  (prepare:notes *state:w *state:hn [%native 'test'] 'artifact-create' args 'doc' ~2026.9.11 0v1)
  ?>  ?=(%& -.out)
  ;:  weld
    (expect-eq !>(%book) !>(stage.p.out))
    (expect-eq !>(`a-notes:n`[%create-notebook 'Harness artifacts']) !>(command.p.out))
    (expect !>(?=(~ revisions.candidate.p.out)))
  ==
--
