/-  h=harness, t=harness-tlon, *harness-store
/+  *test, ht=harness-tools, hj=harness-json, hl=harness, storage=harness-store, policy=harness-defaults, tp=harness-tlon-policy, effects=harness-effects
|%
++  test-tool-path-parses-string-arguments
  =/  run  ~(. effects [*bowl:gall *(map mcp-server-id:h mcp-server:h)])
  (expect-eq !>(`(unit path)`[~ /harness/lib/harness/hoon]) !>((tool-path:run '{"path":"/harness/lib/harness/hoon"}')))
++  test-tool-path-rejects-malformed-arguments
  =/  run  ~(. effects [*bowl:gall *(map mcp-server-id:h mcp-server:h)])
  %-  expect
  !>  %+  levy  `(list @t)`~['not json' '[]' '{}' '{"path":7}' '{"path":null}' '{"path":"not a path"}']
      |=(args=@t =(~ (tool-path:run args)))
++  test-raw-source-does-not-require-desk-converters
  (expect-eq !>(':: fixture\0a|=  a=@ud\0a+(a)') !>((clay-text:ht %hoon ':: fixture\0a|=  a=@ud\0a+(a)')))
++  test-raw-json-is-rendered-locally
  (expect-eq !>('["fixture"]') !>((clay-text:ht %json [%a ~[[%s 'fixture']]])))
++  test-unknown-formats-do-not-execute-converters
  (expect-eq !>('error: unsupported Clay data format; desk-defined converters are not executed') !>((clay-text:ht %custom ~)))
++  test-malformed-source-data-fails-closed
  (expect-eq !>('error: invalid Hoon source data') !>((clay-text:ht %hoon [1 2])))
++  test-path-grants-compare-components-not-text-prefixes
  =/  grants=(list tool-grant:h)  ~[[%clay /harness/lib]]
  (expect !>(&((clay-granted:ht /harness/lib/harness/hoon grants) (clay-granted:ht /harness/lib grants) !(clay-granted:ht /harness/library grants) !(clay-granted:ht /harness grants) !(clay-granted:ht /base/lib grants))))
++  test-file-grants-do-not-grant-parent-listing
  =/  grants=(list tool-grant:h)  ~[[%clay /harness/lib/harness/hoon]]
  (expect !>(&((clay-granted:ht /harness/lib/harness/hoon grants) !(clay-granted:ht /harness/lib grants))))
++  test-path-and-legacy-root-grants-roundtrip
  =/  scoped=tool-grant:h  [%clay /harness/lib]
  =/  broad=tool-grant:h  [%clay ~]
  (expect !>(&(=(scoped (json-grant:hj (grant-json:hj scoped))) =(broad (json-grant:hj (grant-json:hj broad))))))
++  test-bare-clay-grants-are-inactive-and-rejected-on-write
  =/  legacy  (mule |.((json-grant:hj [%s 'clay'])))
  (expect !>(&(?=(%| -.legacy) !(tool-granted:ht 'read_desk_file' ~[%clay]) !(clay-granted:ht /base ~[%clay]))))
++  test-forged-path-is-denied-before-any-scry
  =/  run  ~(. effects [*bowl:gall *(map mcp-server-id:h mcp-server:h)])
  =/  out  (run-tool:run ['call' 'read_desk_file' '{"path":"/base/private/hoon"}'] ~ ~[[%clay /harness/lib]])
  ?>  ?=(%tool-completed -.out)
  (expect-eq !>('rejected: tool or path is not granted for this session') !>(body.out))
++  test-rehearsal-preserves-only-inherited-clay-prefixes
  =/  out  (rehearsal-tools:ht ~[%web [%clay /harness/lib] %skills [%mcp 'a']])
  (expect-eq !>(`(list tool-grant:h)`~[[%clay /harness/lib] %skills]) !>(out))
++  test-legacy-migration-is-explicit-and-keeps-history
  =/  old=state-11  *state-11
  =/  cfg  builtin-config:policy
  =.  defaults.old  cfg(tools ~[%clay %web])
  =.  sessions.old  (my ~[['s' [~[[%config-replaced defaults.old]] 12]]])
  =.  peer-base.old  `defaults.old
  =.  peers.old  (my ~[[~zod [~[%clay] ~ 10 ~]]])
  =/  next  (load:storage !>(old))
  =/  before  (~(got by sessions.old) 's')
  =/  after  (~(got by sessions.next) 's')
  ?>  ?=(^ log.after)
  ?>  ?=(^ peer-base.next)
  =/  peer  (~(got by peers.next) ~zod)
  (expect !>(&(=(log.before t.log.after) =(12 next-req.after) (clay-granted:ht /base tools.defaults.next) (clay-granted:ht /base tools.peer) =(tools.defaults.next tools.u.peer-base.next) =(next (load:storage !>(next))))))
++  test-tlon-migration-keeps-lanes-and-permission-epoch
  =/  old=state-2:t  *state-2:t
  =.  epoch.old  5
  =.  trusted.policy.old  (my ~[[~nec ~[%clay]]])
  =.  lanes.old  (my ~[['s' [~nec [%dm ~nec ~] 5 ~[%clay]]]])
  =/  next  (scope-clay:tp old)
  =/  lane  (~(got by lanes.next) 's')
  (expect !>(&(=(5 epoch.next) =(5 epoch.lane) =(jobs.old jobs.next) (clay-granted:ht /harness tools.lane) (clay-granted:ht /harness (~(got by trusted.policy.next) ~nec)))))
--
