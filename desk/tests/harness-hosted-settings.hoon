/-  h=harness
/+  *test, settings=harness-hosted-settings, hosted=harness-hosted-auth, auth=harness-auth, j=harness-workspace-json
|%
++  config
  ^-  config:h
  [| ~ 'https://openrouter.ai/api/v1/chat/completions' 'fixture' '' ~ 'KEEP INSTRUCTIONS' 80.000 ~[%web]]
++  args
  |=  [revision=@t method=@t]
  (pairs:enjs:format ~[['revision' %s revision] ['provider' %s 'openai'] ['model' %s 'selected-model'] ['auth' %s method]])
++  test-settings-preserve-instructions-and-grants
  =/  cfg=config:h  config
  =/  result  (apply:settings cfg (my ~[['openai-device' 'PRIVATE']]) (args (revision:settings cfg) 'subscription'))
  ;:  weld
    (expect-eq !>(system.cfg) !>(system.config.result))
    (expect-eq !>(tools.cfg) !>(tools.config.result))
    (expect-eq !>(device-url:auth) !>(url.config.result))
    (expect-eq !>('selected-model') !>(model.config.result))
    (expect-eq !>('') !>(key.config.result))
  ==
++  test-settings-reject-conflicts-without-saving-key
  =/  cfg=config:h  config
  =/  input  (args 'stale-revision' 'api-key')
  ?>  ?=(%o -.input)
  =.  p.input  (~(put by p.input) 'apiKey' [%s 'MUST_NOT_SAVE'])
  =/  result  (apply:settings cfg ~ input)
  ;:  weld
    (expect-eq !>(cfg) !>(config.result))
    (expect-eq !>(~) !>(keys.result))
    (expect-eq !>(409) !>((number:j response.result 'status' 0)))
  ==
++  test-settings-key-is-never-in-response-or-config
  =/  cfg=config:h  config
  =/  input  (args (revision:settings cfg) 'api-key')
  ?>  ?=(%o -.input)
  =.  p.input  (~(put by p.input) 'apiKey' [%s 'PRIVATE_API_KEY'])
  =/  result  (apply:settings cfg ~ input)
  =/  body  (need (get:j response.result 'body'))
  ;:  weld
    (expect-eq !>('PRIVATE_API_KEY') !>((key:auth keys.result 'openai')))
    (expect-eq !>('') !>(key.config.result))
    (expect-eq !>(~) !>((get:j body 'apiKey')))
    (expect-eq !>(~) !>((get:j body 'key')))
  ==
++  test-settings-reject-unsupported-fields
  =/  cfg=config:h  config
  =/  input  (args (revision:settings cfg) 'subscription')
  ?>  ?=(%o -.input)
  =.  p.input  (~(put by p.input) 'unknown' [%a ~])
  =/  result  (apply:settings cfg ~ input)
  ;:  weld
    (expect-eq !>(cfg) !>(config.result))
    (expect-eq !>(400) !>((number:j response.result 'status' 0)))
  ==
++  test-key-management-does-not-switch-provider-or-model
  =/  cfg=config:h  config
  =/  input  (pairs:enjs:format ~[['revision' %s (revision:settings cfg)] ['provider' %s 'anthropic'] ['apiKey' %s 'PRIVATE']])
  =/  result  (apply:settings cfg ~ input)
  =/  body  (need (get:j response.result 'body'))
  ;:  weld
    (expect-eq !>(cfg) !>(config.result))
    (expect-eq !>('PRIVATE') !>((key:auth keys.result 'anthropic')))
    (expect-eq !>(`(unit json)`[~ [%o (my ~[['anthropic' [%b &]] ['openai' [%b |]] ['openrouter' [%b |]] ['xai' [%b |]]])]]) !>((get:j body 'apiKeys')))
  ==
++  test-clearing-api-key-keeps-subscription-credential
  =/  cfg=config:h  config
  =/  input  (args (revision:settings cfg) 'api-key')
  ?>  ?=(%o -.input)
  =.  p.input  (~(put by p.input) 'apiKey' [%s ''])
  =/  keys  (my ~[['openai' 'API_KEY'] ['openai-device' 'SUBSCRIPTION']])
  =/  result  (apply:settings cfg keys input)
  ;:  weld
    (expect-eq !>('') !>((key:auth keys.result 'openai')))
    (expect-eq !>('SUBSCRIPTION') !>((key:auth keys.result 'openai-device')))
  ==
++  test-settings-require-selected-credential
  =/  cfg=config:h  config
  =/  result  (apply:settings cfg (my ~[['openai' 'API_KEY']]) (args (revision:settings cfg) 'subscription'))
  ;:  weld
    (expect-eq !>(cfg) !>(config.result))
    (expect-eq !>(409) !>((number:j response.result 'status' 0)))
  ==
--
