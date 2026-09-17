::  Hosting manages model defaults, never conversation policy or tool grants.
/-  h=harness
/+  auth=harness-auth, provider=harness-provider, hosted=harness-hosted-auth, j=harness-workspace-json
|%
++  revision
  |=(cfg=config:h (scot %uv (sham [url.cfg model.cfg headers.cfg max-context.cfg])))
++  view
  |=  [cfg=config:h keys=(map @t @t)]
  =/  configured
    (turn `(list @t)`~['openai' 'anthropic' 'openrouter'] |=(name=@t [name [%b !=('' (key:auth keys name))]]))
  (envelope:hosted 200 (pairs:enjs:format ~[['revision' %s (revision cfg)] ['provider' %s (provider-for-url:provider url.cfg)] ['model' %s model.cfg] ['apiKeys' (pairs:enjs:format configured)] ['auth' %s ?:(=('openai-device' (credential-for-config:auth cfg)) 'subscription' ?:(=('anthropic-device' (credential-for-config:auth cfg)) 'subscription' 'api-key'))]]))
++  apply
  |=  [cfg=config:h keys=(map @t @t) args=json]
  ^-  [config=config:h keys=(map @t @t) response=json]
  =/  out  [cfg keys (error:hosted 400 'Invalid model settings.')]
  ?>  ?=(%o -.args)
  ?:  =(~ p.args)  [cfg keys (view cfg keys)]
  ::  Unknown fields fail closed: callers must not mistake ignored settings
  ::  (such as a fallback chain) for applied configuration.
  ?.  (levy ~(tap by p.args) |=([name=@t value=json] (~(has in (silt ~['revision' 'provider' 'model' 'auth' 'apiKey'])) name)))
    [cfg keys (error:hosted 400 'Unsupported model setting. Read hosted capabilities.')]
  ?.  =((revision cfg) (string:j args 'revision'))
    [cfg keys (error:hosted 409 'Model settings changed. Read settings and retry.')]
  =/  provider  (string:j args 'provider')
  ::  Key management does not select a model or change its authentication.
  ?:  ?=(~ (get:j args 'model'))
    ?.  (~(has in (silt ~['openai' 'anthropic' 'openrouter'])) provider)  out
    ?.  ?=(~ (get:j args 'auth'))  out
    =/  token  (string:j args 'apiKey')
    ?.  (lte (met 3 token) 8.192)  out
    =.  keys  (put-key:auth keys provider token)
    [cfg keys (view cfg keys)]
  =/  model  (string:j args 'model')
  =/  method  (string:j args 'auth')
  ?.  &(!=('' model) (lte (met 3 model) 256) |(=('api-key' method) =('subscription' method)))  out
  =/  url=@t
    ?:  =('openai' provider)  ?:(=('subscription' method) device-url:auth 'https://api.openai.com/v1/chat/completions')
    ?:  =('anthropic' provider)  'https://api.anthropic.com/v1/chat/completions'
    ?:  &(=('openrouter' provider) =('api-key' method))  'https://openrouter.ai/api/v1/chat/completions'
    ''
  ?:  =('' url)  [cfg keys (error:hosted 400 'Unsupported provider or authentication method.')]
  =/  headers=(list [name=@t value=@t])
    ?:  &(=('anthropic' provider) =('subscription' method))  ~[['anthropic-beta' 'oauth-2025-04-20']]
    ~
  =/  next  cfg(url url, model model, key '', headers headers)
  =/  supplied  (get:j args 'apiKey')
  ?^  supplied
    ?>  ?=(%s -.u.supplied)
    ?.  &(=('api-key' method) (lte (met 3 p.u.supplied) 8.192))  out
    =.  keys  (put-key:auth keys provider p.u.supplied)
    [next keys (view next keys)]
  ?:  =('' (key:auth keys (credential-for-config:auth next)))
    [cfg keys (error:hosted 409 'Connect this provider before selecting its model.')]
  [next keys (view next keys)]
--
