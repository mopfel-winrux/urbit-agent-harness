/-  h=harness
/+  *test, ht=harness-tools, policy=harness-defaults
|%
++  test-js-is-discoverable-but-never-a-bootstrap-grant
  ;:  weld
    (expect !>((lien configurable-tools:ht |=(t=term =(%code t)))))
    (expect !>(!(tool-granted:ht 'run_js' default-tools:policy)))
    (expect !>((tool-granted:ht 'run_js' ~[%code])))
    (expect !>(!(tool-granted:ht 'run_js' ~[%web %curl %author])))
  ==
++  test-js-family-appears-once
  (expect-eq !>(`(list term)`~[%code]) !>((tool-families:ht ~[%code %code])))
++  test-js-cannot-escape-social-scheduled-or-rehearsal-ceilings
  ;:  weld
    (expect !>(!(tool-granted:ht 'run_js' (conversation-tools:ht ~[%code]))))
    (expect !>(!(tool-granted:ht 'run_js' (scheduled-tools:ht ~[%code]))))
    (expect !>(!(tool-granted:ht 'run_js' (rehearsal-tools:ht ~[%code]))))
  ==
++  test-js-guard-rejects-known-unbounded-spellings
  =/  snippets=(list @t)
    ~['while(true) {}' 'while ( 1 ) {}' 'while(!0){}' 'for ( ; ; ) {}' 'do {} while(x)']
  (expect !>((levy snippets |=(s=@t ?=(^ (js-loop-guard:ht s))))))
++  test-js-guard-allows-short-bounded-work
  (expect-eq !>(`(unit @t)`~) !>((js-loop-guard:ht 'module.exports = () => { let s = 0; for(let i = 0; i < 10; i++) s += i; return s; };')))
--
