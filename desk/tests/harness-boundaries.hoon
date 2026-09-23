::  Composition contracts: storage, wire shapes and grants remain independent
::  of the reducer. Use fixture credentials only; never inspect real secrets.
/-  h=harness, w=harness-workspace, hn=harness-notes, ws=harness-workspace-search, pc=harness-project-client, wc=harness-work-control, *harness-store
/-  hosted=harness-hosted, renew=harness-oauth
/+  *test, storage=harness-store, policy=harness-defaults, hj=harness-json, hp=harness-provider, ht=harness-tools, hl=harness
|%
++  test-bootstrap-enables-configurable-local-families
  =/  cfg  builtin-config:policy
  =/  expected=(list tool-grant:h)
    ~[[%clay ~] %web %curl %skills %skill-write %author %subagents %peers %corpus %workspace %tlon]
  (expect-eq !>(expected) !>(tools.cfg))
++  test-rehearsal-keeps-only-inherited-reads
  =/  out  (rehearsal-tools:ht ~[[%clay /harness/lib] %web %skills %skill-write %author %subagents %peers %mcp %code %future-tool])
  (expect-eq !>(`(list tool-grant:h)`~[[%clay /harness/lib] %skills]) !>(out))
++  test-rehearsal-does-not-add-read-authority
  (expect-eq !>(`(list term)`~) !>((rehearsal-tools:ht ~[%web %mcp])))
++  test-current-store-load-is-an-identity
  =/  saved=state-0  *state-0
  =.  peer-budget-resets.saved  (my ~[[~nec 1.234]])
  =.  defaults.saved  builtin-config:policy
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  search-config.saved  [%searxng 'https://search.example']
  =.  search-requests.saved  (my ~[[['fixture' 'pending-call'] %searxng]])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-current-store-retains-workspace-evidence
  =/  saved=state-0  *state-0
  =.  writes.workspace.saved  7
  =.  projects.workspace.saved  (my ~[['fixture' ['Keep project' '' 2 ~ |]]])
  =.  project-clients.saved
    (my ~[['retained' ['fixture' 'Revoked fixture' 0x123 ~2026.9.12 ~2026.9.13 `~2026.9.12]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-store-rejects-an-invalid-version
  =/  saved  *state-0
  (expect-fail |.((load:storage !>([%1 +.saved]))))
++  test-store-rejects-a-malformed-envelope
  (expect-fail |.((load:storage !>([%0 ~]))))
++  test-current-store-retains-work-confirmations-and-owner-grants
  =/  saved=state-0  *state-0
  =.  owners.work-controls.saved  (sy ~[['binding' 'alice']])
  =.  requests.work-controls.saved
    (my ~[[0v3 ['conversation' 0v1 [%acp 'fixture'] `~zod 'task-create' [%o ~] 0v2 ~2026.9.13 %running ~]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-saved-tool-policy-is-not-replaced-by-bootstrap-defaults
  =/  saved=state-0  *state-0
  =/  cfg  builtin-config:policy
  =.  defaults.saved  cfg(tools ~[%author %skill-write [%mcp 'calendar']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 0]]])
  =.  skills.saved  (my ~[['existing' ['Keep me' 'Explicit owner instructions']]])
  =.  staged.saved  skills.saved
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-config-and-view-share-one-redacted-projection
  =/  cfg=config:h  builtin-config:policy
  =.  key.cfg  'test-secret'
  =/  config  (config-json:hj cfg)
  =/  view  (view-json:hj (play:hl ~[[%config-replaced cfg]]) ~s30)
  ?>  ?=([%o *] config)
  ?>  ?=([%o *] view)
  =/  matches
    %+  lien  ~(tap by p.config)
    |=  [name=@t value=json]
    !=(`value (~(get by p.view) name))
  (expect !>(&(!matches !(~(has by p.config) 'key') !(~(has by p.view) 'key'))))
++  test-schema-discovery-is-not-an-execution-grant
  (expect !>(&((tool-granted:ht 'http_fetch' ~[%web]) !(tool-granted:ht 'http_fetch' ~[%clay]) !(tool-granted:ht 'invented_tool' all-tools:ht))))
++  test-work-and-peer-schemas-require-ordinary-json-objects
  =/  defs  (tool-defs:ht ~[%workspace %peers])
  ?>  ?=(%a -.defs)
  %-  zing
  %+  turn  `(list [@t @t (list @t)])`~[['workspace' 'args' ~['action' 'args']] ['call_peer_tool' 'arguments' ~['ship' 'name' 'arguments']]]
  |=  [name=@t key=@t required=(list @t)]
  =/  get
    |=  [j=json k=@t]
    ?>  ?=(%o -.j)
    (need (~(get by p.j) k))
  =/  found  (skim p.defs |=(j=json =([%s name] (get (get j 'function') 'name'))))
  ?>  ?=(^ found)
  =/  schema  i.found
  =/  params  (get (get schema 'function') 'parameters')
  ;:  weld
    (expect-eq !>(`json`[%s 'object']) !>((get (get (get params 'properties') key) 'type')))
    (expect-eq !>(`json`[%a (turn required |=(n=@t `json`[%s n]))]) !>((get params 'required')))
  ==
++  test-provider-catalog-retains-context-metadata
  =/  jon  (need (de:json:html '{"data":[{"id":"fixture","context_length":12345}]}'))
  (expect-eq !>(`(list model-info:hp)`~[['fixture' `12.345]]) !>((parse-model-list:hp jon)))
--
