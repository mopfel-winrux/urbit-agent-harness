/-  h=harness
/+  *test, auth=harness-auth
|%
++  fixture
  ^-  (map @t @t)
  (my ~[['openai' 'sk-fixture-api'] ['openai-device' 'fixture-device-token'] ['openai-account' 'fixture-account']])
++  test-openai-credentials-are-isolated
  (expect !>(&(=('sk-fixture-api' (key:auth fixture 'openai')) =('fixture-device-token' (key:auth fixture 'openai-device')) =('openai-device' (credential-for-url:auth device-url:auth)) =('openai' (credential-for-url:auth 'https://api.openai.com/v1/chat/completions')))))
++  test-shared-device-token-never-becomes-api-key
  =/  keys=(map @t @t)  (my ~[['openai' 'eyJ.fixture.device']])
  (expect !>(&(=('' (key:auth keys 'openai')) =('eyJ.fixture.device' (key:auth keys 'openai-device')))))
++  test-saving-api-key-preserves-existing-device-login
  =/  keys=(map @t @t)  (my ~[['openai' 'eyJ.fixture.device']])
  =/  next  (put-key:auth keys 'openai' 'sk-fixture-api')
  (expect !>(&(=('sk-fixture-api' (key:auth next 'openai')) =('eyJ.fixture.device' (key:auth next 'openai-device')))))
++  test-api-key-is-never-device-fallback
  =/  keys=(map @t @t)  (my ~[['openai' 'sk-fixture-api']])
  (expect-eq !>('') !>((key:auth keys 'openai-device')))
++  test-explicit-empty-device-slot-does-not-resurrect-shared-token
  =/  keys=(map @t @t)  (my ~[['openai' 'eyJ.fixture.device'] ['openai-device' '']])
  (expect-eq !>('') !>((key:auth keys 'openai-device')))
++  test-only-device-route-gets-account-header
  =/  extras=(list [name=@t value=@t])
    ~[['Authorization' 'Bearer wrong'] ['ChatGPT-Account-ID' 'wrong-account'] ['x-extra' 'kept']]
  =/  api  (headers:auth fixture 'https://api.openai.com/v1/chat/completions' extras)
  =/  device  (headers:auth fixture device-url:auth extras)
  (expect !>(&(=(~[['x-extra' 'kept']] api) =(~[['chatgpt-account-id' 'fixture-account'] ['x-extra' 'kept']] device) =(extras (headers:auth fixture 'https://custom.example' extras)))))
++  test-missing-selected-credential-fails-before-dispatch
  =/  cfg=config:h  *config:h
  =.  url.cfg  'https://api.openai.com/v1/chat/completions'
  =/  keys=(map @t @t)  (my ~[['openai-device' 'fixture-device']])
  (expect !>(&(?=(^ (missing:auth keys cfg)) ?=(~ (missing:auth keys cfg(url device-url:auth))) ?=(~ (missing:auth ~ cfg(url 'https://custom.example'))))))
--
