::  Composition contracts: storage, wire shapes and grants remain independent
::  of the reducer. Use fixture credentials only; never inspect real secrets.
/-  h=harness, w=harness-workspace, hn=harness-notes, ws=harness-workspace-search, pc=harness-project-client, wc=harness-work-control, *harness-store
/-  hosted=harness-hosted, renew=harness-oauth
/+  *test, storage=harness-store, policy=harness-defaults, hj=harness-json, hp=harness-provider, ht=harness-tools, hl=harness
|%
++  legacy-config
  =/  cfg  builtin-config:policy
  +>.cfg
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
  =/  saved=state-30  *state-30
  =.  peer-budget-resets.saved  (my ~[[~nec 1.234]])
  =.  defaults.saved  builtin-config:policy
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  search-config.saved  [%searxng 'https://search.example']
  =.  search-requests.saved  (my ~[[['fixture' 'pending-call'] %searxng]])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-thirteen-migration-keeps-policy-and-starts-disposable-corpus
  =/  saved=state-13  *state-13
  =.  defaults.saved  legacy-config
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  =.  modified.saved  (my ~[['fixture' ~2024.1.1]])
  =/  loaded  (load-29:storage !>(saved))
  ;:  weld
    (expect-eq !>(sessions.saved) !>(sessions.loaded))
    (expect-eq !>(modified.saved) !>(modified.loaded))
    (expect-eq !>(defaults.saved) !>(defaults.loaded))
    (expect-eq !>(*summary-models-0) !>(summary-models.loaded))
    (expect-eq !>(0) !>(count.corpus.loaded))
  ==
++  test-seventeen-migration-keeps-welcome-marker-and-token-counts
  =/  saved=state-17  *state-17
  =.  welcome-seen.saved  1
  =.  peer-budget-resets.saved  (my ~[[~nec 120]])
  =/  loaded  (load-29:storage !>(saved))
  (expect !>(&(=(1 welcome-seen.loaded) =(peer-budget-resets.saved peer-budget-resets.loaded) =(~ remote-access.loaded) =(~ announced-access.loaded))))
++  test-twenty-migration-keeps-the-entire-prior-envelope
  =/  saved=state-20  *state-20
  =/  cfg  legacy-config
  =.  defaults.saved  cfg(tools ~[%web])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =/  loaded  (load-29:storage !>(saved))
  ;:  weld
    (expect-eq !>([%29 *state:renew *state:hosted %27 *state:w *state:wc *state:pc *state:ws *state:hn *state-0:w saved]) !>(loaded))
    (expect-eq !>(loaded) !>((load-29:storage !>(loaded))))
  ==
++  test-current-store-retains-workspace-evidence
  =/  saved=state-30  *state-30
  =.  writes.workspace.saved  7
  =.  projects.workspace.saved  (my ~[['fixture' ['Keep project' '' 2 ~ |]]])
  =.  project-clients.saved
    (my ~[['retained' ['fixture' 'Revoked fixture' 0x123 ~2026.9.12 ~2026.9.13 `~2026.9.12]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-legacy-documents-are-not-imported-or-published
  =/  saved=state-21  *state-21
  =.  writes.workspace.saved  7
  =.  projects.workspace.saved  (my ~[['fixture' ['Retired project' '' 2 ~ |]]])
  =/  loaded  (load-29:storage !>(saved))
  ;:  weld
    (expect-eq !>(workspace.saved) !>(legacy-workspace.loaded))
    (expect-eq !>(*state:w) !>(workspace.loaded))
    (expect-eq !>(*state:hn) !>(workspace-notes.loaded))
  ==
++  test-notes-store-upgrade-preserves-native-identities
  =/  saved=state-22  *state-22
  =.  book.workspace-notes.saved  `[~zod %harness]
  =.  links.workspace-notes.saved  (my ~[['fixture' [42 ~ ~]]])
  =.  writes.workspace.saved  7
  =/  [%22 * * %21 * runtime=state-20]  saved
  (expect-eq !>([%29 *state:renew *state:hosted %27 (restore-workspace:storage workspace.saved) *state:wc *state:pc *state:ws workspace-notes.saved legacy-workspace.saved runtime]) !>((load-29:storage !>(saved))))
++  test-project-client-upgrade-does-not-grant-access-or-change-work
  =/  saved=state-23  *state-23
  =.  writes.workspace.saved  7
  =.  provider-keys.saved  (my ~[['fixture' 'private-fixture-key']])
  =.  projects.workspace.saved  (my ~[['fixture' ['Keep project' '' 2 (my ~[[0v1 %contributor]]) |]]])
  =/  [%23 * %22 * * %21 * runtime=state-20]  saved
  (expect-eq !>([%29 *state:renew *state:hosted %27 (restore-workspace:storage workspace.saved) *state:wc *state:pc workspace-search.saved workspace-notes.saved legacy-workspace.saved runtime]) !>((load-29:storage !>(saved))))
++  test-work-control-migration-retains-pending-notes-and-the-entire-envelope
  =/  saved=state-24  *state-24
  =.  pending.workspace-notes.saved  `*pending:hn
  =.  provider-keys.saved  (my ~[['fixture' 'retained-private-key']])
  =/  [%24 * %23 * %22 * * %21 * runtime=state-20]  saved
  (expect-eq !>([%29 *state:renew *state:hosted %27 (restore-workspace:storage workspace.saved) *state:wc project-clients.saved workspace-search.saved workspace-notes.saved legacy-workspace.saved runtime]) !>((load-29:storage !>(saved))))
++  test-current-store-retains-work-confirmations-and-owner-grants
  =/  saved=state-30  *state-30
  =.  owners.work-controls.saved  (sy ~[['binding' 'alice']])
  =.  requests.work-controls.saved
    (my ~[[0v3 ['conversation' 0v1 [%acp 'fixture'] `~zod 'task-create' [%o ~] 0v2 ~2026.9.13 %running ~]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-fourteen-migration-preserves-peer-grants-and-starts-empty-limit-overrides
  =/  saved=state-14  *state-14
  =.  peers.saved  (my ~[[~nec [~[%web] ~ 12.345 ~]]])
  =.  defaults.saved  legacy-config
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  =/  loaded  (load-29:storage !>(saved))
  ;:  weld
    (expect-eq !>(peers.saved) !>(peers.loaded))
    (expect-eq !>(sessions.saved) !>(sessions.loaded))
    (expect-eq !>(defaults.saved) !>(defaults.loaded))
    (expect-eq !>(`(map @p @ud)`~) !>(peer-limits.loaded))
  ==
++  test-fifteen-migration-keeps-limits-and-history-with-no-reset
  =/  saved=state-15  *state-15
  =.  peers.saved  (my ~[[~nec [~[%web] ~ 12.345 ~]]])
  =.  peer-limits.saved  (my ~[[~bud 500]])
  =.  sessions.saved  (my ~[['peer--~nec' [~[[%config-replaced legacy-config]] 37]]])
  =/  loaded  (load-29:storage !>(saved))
  ;:  weld
    (expect-eq !>(peers.saved) !>(peers.loaded))
    (expect-eq !>(peer-limits.saved) !>(peer-limits.loaded))
    (expect-eq !>(sessions.saved) !>(sessions.loaded))
    (expect-eq !>(`(map @p @ud)`~) !>(peer-budget-resets.loaded))
  ==
++  test-saved-tool-policy-is-not-replaced-by-bootstrap-defaults
  =/  saved=state-30  *state-30
  =/  cfg  builtin-config:policy
  =.  defaults.saved  cfg(tools ~[%author %skill-write [%mcp 'calendar']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 0]]])
  =.  skills.saved  (my ~[['existing' ['Keep me' 'Explicit owner instructions']]])
  =.  staged.saved  skills.saved
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-store-conversion-preserves-head-and-credentials
  =/  saved=state-7  *state-7
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced legacy-config]] 37]]])
  =/  loaded  (load-29:storage !>(saved))
  (expect !>(&(=(sessions.saved sessions.loaded) =(provider-keys.saved provider-keys.loaded))))
++  test-store-eight-preserves-head-and-credentials
  =/  saved=state-8  *state-8
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  defaults.saved  legacy-config
  =/  loaded  (load-29:storage !>(saved))
  (expect !>(&(=(defaults.saved defaults.loaded) =(provider-keys.saved provider-keys.loaded) =(~ waiting.openai-auth.loaded))))
++  test-config-and-view-share-one-redacted-projection
  =/  cfg=config:h  builtin-config:policy
  =.  key.cfg  'test-secret'
  =/  config  (config-json:hj cfg)
  =/  view  (view-json:hj (play:hl ~[[%config-replaced cfg]]))
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
