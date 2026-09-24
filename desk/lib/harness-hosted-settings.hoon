::  Hosting manages model defaults, never conversation policy or tool grants.
/-  h=harness
/+  auth=harness-auth, provider=harness-provider, hosted=harness-hosted-auth, j=harness-workspace-json
/+  routing=harness-model-routing
|%
++  revision
  |=(cfg=config:h (scot %uv (sham [url.cfg model.cfg headers.cfg max-context.cfg zdr.cfg fallbacks.cfg])))
++  view
  |=  [cfg=config:h keys=(map @t @t)]
  =/  configured
    (turn `(list @t)`~['openai' 'anthropic' 'xai' 'openrouter'] |=(name=@t [name [%b !=('' (key:auth keys name))]]))
  =/  subscription  (~(has in (silt ~['openai-device' 'anthropic-device' 'xai-device'])) (credential-for-config:auth cfg))
  (envelope:hosted 200 (pairs:enjs:format ~[['revision' %s (revision cfg)] ['provider' %s (provider-for-url:provider url.cfg)] ['model' %s model.cfg] ['zdr' %b zdr.cfg] ['fallbacks' %a (turn fallbacks.cfg |=(m=model-choice:h (pairs:enjs:format ~[['provider' %s provider.m] ['model' %s model.m]])))] ['apiKeys' (pairs:enjs:format configured)] ['auth' %s ?:(subscription 'subscription' 'api-key')]]))
++  apply
  |=  [cfg=config:h keys=(map @t @t) args=json]
  ^-  [config=config:h keys=(map @t @t) response=json]
  =/  out  [cfg keys (error:hosted 400 'Invalid model settings.')]
  ?>  ?=(%o -.args)
  ?:  =(~ p.args)  [cfg keys (view cfg keys)]
  ::  Unknown fields fail closed: callers must not mistake ignored settings
  ::  for applied configuration.
  ?.  (levy ~(tap by p.args) |=([name=@t value=json] (~(has in (silt ~['revision' 'provider' 'model' 'auth' 'apiKey' 'zdr' 'fallbacks'])) name)))
    [cfg keys (error:hosted 400 'Unsupported model setting. Read hosted capabilities.')]
  ?.  =((revision cfg) (string:j args 'revision'))
    [cfg keys (error:hosted 409 'Model settings changed. Read settings and retry.')]
  =/  provider  (string:j args 'provider')
  ::  Key management does not select a model or change its authentication.
  ?:  ?=(~ (get:j args 'model'))
    ?.  (~(has in (silt ~['openai' 'anthropic' 'xai' 'openrouter'])) provider)  out
    ?.  ?=(~ (get:j args 'auth'))  out
    ?.  ?=(~ (get:j args 'zdr'))  out
    ?.  ?=(~ (get:j args 'fallbacks'))  out
    =/  token  (string:j args 'apiKey')
    ?.  (lte (met 3 token) 8.192)  out
    =.  keys  (put-key:auth keys provider token)
    [cfg keys (view cfg keys)]
  =/  model  (string:j args 'model')
  =/  method  (string:j args 'auth')
  =/  privacy  (get:j args 'zdr')
  ?.  |(?=(~ privacy) ?=([~ %b *] privacy))  out
  =/  zdr=?  ?:(?=(~ privacy) | (boolean:j args 'zdr' |))
  ?:  &(zdr !=('openrouter' provider))
    [cfg keys (error:hosted 400 'Zero data retention routing requires OpenRouter.')]
  ?.  &(!=('' model) (lte (met 3 model) 256) |(=('api-key' method) =('subscription' method)))  out
  =/  url=@t
    ?:  =('openai' provider)  ?:(=('subscription' method) device-url:auth 'https://api.openai.com/v1/responses')
    ?:  =('anthropic' provider)  'https://api.anthropic.com/v1/chat/completions'
    ?:  =('xai' provider)  ?:(=('subscription' method) xai-url:auth 'https://api.x.ai/v1/chat/completions')
    ?:  &(=('openrouter' provider) =('api-key' method))  'https://openrouter.ai/api/v1/chat/completions'
    ''
  ?:  =('' url)  [cfg keys (error:hosted 400 'Unsupported provider or authentication method.')]
  =/  headers=(list [name=@t value=@t])
    ?:  &(=('anthropic' provider) =('subscription' method))  ~[['anthropic-beta' 'oauth-2025-04-20']]
    ~
  =/  next  cfg(url url, model model, key '', headers headers, zdr zdr)
  =/  chain  (get:j args 'fallbacks')
  =?  fallbacks.next  ?=(^ chain)  (parse:routing u.chain)
  ?:  &(zdr (lien fallbacks.next |=(m=model-choice:h !=('openrouter' provider.m))))
    [cfg keys (error:hosted 400 'Zero data retention requires OpenRouter fallbacks.')]
  =/  supplied  (get:j args 'apiKey')
  ?^  supplied
    ?>  ?=(%s -.u.supplied)
    ?.  &(=('api-key' method) (lte (met 3 p.u.supplied) 8.192))  out
    =.  keys  (put-key:auth keys provider p.u.supplied)
    [next keys (view next keys)]
  ?:  =('' (key:auth keys (credential-for-config:auth next)))
    [cfg keys (error:hosted 409 'Connect this provider before selecting its model.')]
  [next keys (view next keys)]
++  models
  |=  [cfg=config:h keys=(map @t @t) args=json]
  ^-  json
  =/  entries  (need (get:j args 'models'))
  ?>  ?=(%a -.entries)
  ?>  ?=(^ p.entries)
  ?>  &((gte (lent p.entries) 1) (lte (lent p.entries) 5))
  =/  choices
    %+  turn  p.entries
    |=  entry=json
    =/  name  (string:j entry 'provider')
    (pairs:enjs:format ~[['provider' %s name] ['model' %s (string:j entry 'model')]])
  ?>  ?=(^ choices)
  =/  name  (string:j i.choices 'provider')
  =/  current  (provider-for-url:provider url.cfg)
  =/  method
    ?:  =(name current)
      ?:(=(name (credential-for-config:auth cfg)) 'api-key' 'subscription')
    ?:  !=('' (key:auth keys name))  'api-key'
    'subscription'
  (pairs:enjs:format ~[['revision' %s (revision cfg)] ['provider' %s name] ['model' %s (string:j i.choices 'model')] ['auth' %s method] ['zdr' %b (boolean:j i.p.entries 'zdr' |)] ['fallbacks' %a t.choices]])
--
