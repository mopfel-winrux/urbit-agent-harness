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
    (expect-eq !>(~) !>((get:j (payload:hp v(zdr.config |, url.config 'https://api.openai.com/v1/chat/completions') %turn ~) 'provider')))
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
++  test-state-migration-retains-every-config-and-log-position
  =/  old  *state-29
  =/  cfg=config-0  ['https://openrouter.ai/api/v1/chat/completions' 'retained' '' ~ 'instructions' 80.000 ~[%web]]
  =.  defaults.old  cfg
  =.  peer-base.old  `cfg
  =.  summary-models.old  [`cfg `cfg]
  =.  provider-keys.old  (my ~[['openrouter' 'fixture-secret']])
  =/  session=session-0  [~[[%input-admitted %user 'retained input'] [%config-replaced cfg]] 42]
  =.  sessions.old  (my ~[['fixture' session]])
  =/  loaded  (load:storage !>(old))
  =/  current  (~(got by sessions.loaded) 'fixture')
  ;:  weld
    (expect-eq !>([| ~ cfg]) !>(defaults.loaded))
    (expect-eq !>(`[| ~ cfg]) !>(peer-base.loaded))
    (expect-eq !>([`[| ~ cfg] `[| ~ cfg]]) !>(summary-models.loaded))
    (expect-eq !>(provider-keys.old) !>(provider-keys.loaded))
    (expect-eq !>(42) !>(next-req.current))
    (expect-eq !>(2) !>((lent log.current)))
    (expect-eq !>(`(list item:h)`~[[%user 'retained input']]) !>(items:(play:hl log.current)))
    (expect-eq !>(loaded) !>((load:storage !>(loaded))))
  ==
--
