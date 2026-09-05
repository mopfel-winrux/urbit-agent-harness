/-  h=harness, t=harness-tlon, *harness-store
/+  *test, ht=harness-tools, hj=harness-json, hl=harness, storage=harness-store, policy=harness-defaults, tp=harness-tlon-policy, effects=harness-effects
|%
++  test-grants-roundtrip-and-reject-ambient-authority
  =/  grant=tool-grant:h  [%mcp 'calendar']
  =/  legacy  (mule |.((json-grant:hj [%s 'mcp'])))
  (expect !>(&(=(grant (json-grant:hj (grant-json:hj grant))) ?=(%| -.legacy) !(tool-granted:ht 'list_mcp_servers' ~[%mcp]))))
++  test-server-is-the-boundary-not-the-tool-name
  =/  tools=(list tool-grant:h)  ~[[%mcp 'calendar']]
  =/  allowed=tool-call:h  ['a' 'call_mcp_tool' '{"server":"calendar","name":"any_tool"}']
  =/  denied  allowed(args '{"server":"notes","name":"any_tool"}')
  (expect !>(&((call-granted:ht allowed tools) !(call-granted:ht denied tools) !(call-granted:ht allowed ~[%mcp]) !(call-granted:ht allowed (rehearsal-tools:ht tools)))))
++  test-multiple-servers-advertise-one-schema-family
  (expect-eq !>((tool-defs:ht ~[[%mcp 'a']])) !>((tool-defs:ht ~[[%mcp 'a'] [%mcp 'b']])))
++  test-discovery-hides-enabled-but-ungranted-servers
  =/  servers=(map mcp-server-id:h mcp-server:h)
    (my ~[['a' ['Allowed' 'https://a.example' ~ &]] ['b' ['Not granted' 'https://b.example' ~ &]]])
  =/  run  ~(. effects [*bowl:gall servers])
  =/  out  (run-tool:run ['call' 'list_mcp_servers' '{}'] ~ ~[[%mcp 'a']])
  ?>  ?=(%tool-completed -.out)
  (expect-eq !>((de:json:html '[{"id":"a","name":"Allowed"}]')) !>((de:json:html body.out)))
++  test-migration-snapshots-registered-servers-and-keeps-history
  =/  old=state-9  *state-9
  =/  cfg  builtin-config:policy
  =.  defaults.old  cfg(tools ~[%web %mcp %author])
  =.  mcp-servers.old  (my ~[['a' ['A' 'https://a.example' ~ &]] ['disabled' ['D' 'https://d.example' ~ |]]])
  =.  sessions.old  (my ~[['s' [~[[%config-replaced defaults.old]] 37]]])
  =.  peers.old  (my ~[[~zod [~[%mcp] ~ 3 ~]]])
  =.  peer-base.old  `defaults.old
  =/  next  (load:storage !>(old))
  =/  before  (~(got by sessions.old) 's')
  =/  after  (~(got by sessions.next) 's')
  ?>  ?=(^ log.after)
  =/  scoped  tools.defaults.next
  =/  peer  (~(got by peers.next) ~zod)
  ?>  ?=(^ peer-base.next)
  (expect !>(&(=(log.before t.log.after) =(37 next-req.after) (mcp-granted:ht 'a' scoped) (mcp-granted:ht 'disabled' scoped) !(mcp-granted:ht 'future' scoped) (mcp-granted:ht 'a' tools.peer) =(scoped tools.u.peer-base.next) =(next (load:storage !>(next))))))
++  test-tlon-migration-preserves-lane-epoch-and-scopes-trust
  =/  old=state-1:t  *state-1:t
  =.  epoch.old  9
  =.  trusted.policy.old  (my ~[[~zod ~[%mcp %web]]])
  =.  lanes.old  (my ~[['s' [~zod [%dm ~zod ~] 9 ~[%mcp]]]])
  =/  next  (scope-mcp:tp old ~['a'])
  =/  grants  (~(got by trusted.policy.next) ~zod)
  =/  lane  (~(got by lanes.next) 's')
  (expect !>(&(=(9 epoch.next) =(9 epoch.lane) =(jobs.old jobs.next) (mcp-granted:ht 'a' grants) (mcp-granted:ht 'a' tools.lane) !(mcp-granted:ht 'future' grants))))
--
