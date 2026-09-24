/-  h=harness, *harness-store
/+  *test, routing=harness-model-routing, hp=harness-provider, j=harness-workspace-json, hj=harness-json, storage=harness-store, policy=harness-defaults, hl=harness
|%
++  test-zdr-is-on-turns-and-checkpoints-and-is-absent-when-disabled
  =/  v  *view:h
  =/  cfg  builtin-config:policy
  =.  config.v  cfg(zdr &)
  =/  expected  (need (de:json:html '{"zdr":true,"data_collection":"deny"}'))
  ;:  weld
    (expect-eq !>(`expected) !>((get:j (payload:hp v %turn ~) 'provider')))
    (expect-eq !>(`expected) !>((get:j (payload:hp v %compaction ~) 'provider')))
    (expect-eq !>(~) !>((get:j (payload:hp v(zdr.config |) %turn ~) 'provider')))
    (expect-eq !>(~) !>((get:j (payload:hp v(zdr.config |, url.config 'https://api.openai.com/v1/responses') %turn ~) 'provider')))
  ==
++  test-fallback-consumes-order-and-preserves-privacy-and-authority
  =/  cfg  builtin-config:policy
  =.  zdr.cfg  &
  =.  fallbacks.cfg  ~[['openai' 'direct'] ['openrouter' 'first'] ['openrouter' 'last']]
  =/  keys  (my ~[['openrouter' 'fixture-key'] ['openai' 'fixture-key']])
  =/  first  (need (next:routing cfg keys))
  =/  last  (need (next:routing first keys))
  ;:  weld
    (expect-eq !>('first') !>(model.first))
    (expect-eq !>('last') !>(model.last))
    (expect-eq !>(~) !>((next:routing last keys)))
    (expect !>(zdr.first))
    (expect-eq !>(tools.cfg) !>(tools.first))
    (expect-eq !>(system.cfg) !>(system.first))
    (expect-eq !>('') !>(key.first))
    (expect-eq !>(~) !>(headers.first))
    (expect-eq !>(~) !>((next:routing cfg ~)))
  ==
++  test-routing-json-roundtrip-and-rejects-invalid-chains
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(zdr &, fallbacks ~[['openrouter' 'backup']])
  =/  invalid  (mule |.((parse:routing [%s 'invalid'])))
  =/  unsupported  (mule |.((parse:routing (need (de:json:html '[{"provider":"custom","model":"x"}]')))))
  =/  json  (config-json:hj cfg)
  ?>  ?=(%o -.json)
  =.  p.json  (~(put by p.json) 'key' [%s ''])
  ;:  weld
    (expect-eq !>(cfg) !>((json-config:hj json)))
    (expect !>(?=(%| -.invalid)))
    (expect !>(?=(%| -.unsupported)))
  ==
--
