::  Composition contracts: storage, wire shapes and grants remain independent
::  of the reducer. Use fixture credentials only; never inspect real secrets.
/-  h=harness, *harness-store
/+  *test, storage=harness-store, policy=harness-defaults, hj=harness-json, hp=harness-provider, ht=harness-tools, hl=harness
|%
++  test-bootstrap-grants-are-not-the-catalog
  =/  cfg  builtin-config:policy
  (expect-eq !>(`(list term)`~[%web %skills]) !>(tools.cfg))
++  test-rehearsal-keeps-only-inherited-reads
  =/  out  (rehearsal-tools:ht ~[[%clay /harness/lib] %web %skills %skill-write %author %subagents %peers %mcp %code %future-tool])
  (expect-eq !>(`(list tool-grant:h)`~[[%clay /harness/lib] %skills]) !>(out))
++  test-rehearsal-does-not-add-read-authority
  (expect-eq !>(`(list term)`~) !>((rehearsal-tools:ht ~[%web %mcp])))
++  test-current-store-load-is-an-identity
  =/  saved=state-14  *state-14
  =.  defaults.saved  builtin-config:policy
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  search-config.saved  [%searxng 'https://search.example']
  =.  search-requests.saved  (my ~[[['fixture' 'pending-call'] %searxng]])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-thirteen-migration-keeps-policy-and-starts-disposable-corpus
  =/  saved=state-13  *state-13
  =.  defaults.saved  builtin-config:policy
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  =.  modified.saved  (my ~[['fixture' ~2024.1.1]])
  =/  loaded  (load:storage !>(saved))
  ;:  weld
    (expect-eq !>(sessions.saved) !>(sessions.loaded))
    (expect-eq !>(modified.saved) !>(modified.loaded))
    (expect-eq !>(defaults.saved) !>(defaults.loaded))
    (expect-eq !>(`summary-models:h`*summary-models:h) !>(summary-models.loaded))
    (expect-eq !>(0) !>(count.corpus.loaded))
  ==
++  test-saved-tool-policy-is-not-replaced-by-bootstrap-defaults
  =/  saved=state-14  *state-14
  =/  cfg  builtin-config:policy
  =.  defaults.saved  cfg(tools ~[%author %skill-write [%mcp 'calendar']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 0]]])
  =.  skills.saved  (my ~[['existing' ['Keep me' 'Explicit owner instructions']]])
  =.  staged.saved  skills.saved
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-store-conversion-preserves-head-and-credentials
  =/  saved=state-7  *state-7
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced builtin-config:policy]] 37]]])
  =/  loaded  (load:storage !>(saved))
  (expect !>(&(=(sessions.saved sessions.loaded) =(provider-keys.saved provider-keys.loaded))))
++  test-store-eight-preserves-head-and-credentials
  =/  saved=state-8  *state-8
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  defaults.saved  builtin-config:policy
  =/  loaded  (load:storage !>(saved))
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
++  test-provider-catalog-retains-context-metadata
  =/  jon  (need (de:json:html '{"data":[{"id":"fixture","context_length":12345}]}'))
  (expect-eq !>(`(list model-info:hp)`~[['fixture' `12.345]]) !>((parse-model-list:hp jon)))
--
