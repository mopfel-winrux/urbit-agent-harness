/-  h=harness, t=harness-tlon
/+  *test, ht=harness-tools, policy=harness-defaults, tlon=harness-tlon-policy
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
++  test-js-explicit-conversation-grant-is-preserved
  (expect !>((tool-granted:ht 'run_js' (conversation-tools:ht ~[%code]))))
++  test-js-conversation-filter-never-adds-a-grant
  (expect !>(!(tool-granted:ht 'run_js' (conversation-tools:ht ~[%web %skills]))))
++  test-js-tlon-owner-grant-does-not-become-another-senders-grant
  =/  cfg=policy:t  [& `~bud (my ~[[~nec ~[%web]]]) &]
  =/  owner  (need (grants:tlon cfg ~bud ~[%code]))
  =/  other  (need (grants:tlon cfg ~nec ~[%code]))
  ;:  weld
    (expect !>((tool-granted:ht 'run_js' (conversation-tools:ht owner))))
    (expect !>(!(tool-granted:ht 'run_js' (conversation-tools:ht other))))
    (expect-eq !>(`(unit (list tool-grant:h))`~) !>((grants:tlon cfg ~zod ~[%code])))
  ==
++  test-js-cannot-escape-scheduled-or-rehearsal-ceilings
  ;:  weld
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
