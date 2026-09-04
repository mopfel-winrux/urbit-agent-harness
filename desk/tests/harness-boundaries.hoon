::  Composition contracts: storage, wire shapes and grants remain independent
::  of the reducer. Use fixture credentials only; never inspect real secrets.
/-  h=harness, *harness-store
/+  *test, storage=harness-store, policy=harness-defaults, hj=harness-json, hp=harness-provider, ht=harness-tools, hl=harness
|%
++  test-current-store-load-is-an-identity
  =/  saved=state-8  *state-8
  =.  defaults.saved  builtin-config:policy
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced defaults.saved]] 37]]])
  (expect-eq !>(saved) !>((load:storage !>(saved))))
++  test-store-conversion-preserves-head-and-credentials
  =/  saved=state-7  *state-7
  =.  provider-keys.saved  (my ~[['fixture' 'test-secret']])
  =.  sessions.saved  (my ~[['fixture' [~[[%config-replaced builtin-config:policy]] 37]]])
  =/  loaded  (load:storage !>(saved))
  (expect !>(&(=(sessions.saved sessions.loaded) =(provider-keys.saved provider-keys.loaded))))
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
