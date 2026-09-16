::  Credential routing, separate from codecs and session policy. Endpoints
::  select a credential slot, never a fallback to another authentication kind.
::  Secrets stay in the head's credential map, not configuration/event logs.
/-  h=harness
/+  hp=harness-provider
|%
++  device-url  'https://chatgpt.com/backend-api/codex/responses'
++  device-models  'https://chatgpt.com/backend-api/codex/models?client_version=0.153.0'
++  device-route
  |=(url=@t |(=(url device-url) =(url device-models)))
++  credential-for-url
  |=  url=@t
  ?:  (device-route url)  'openai-device'
  (provider-for-url:hp url)
::  Compatibility for device tokens already saved in the shared OpenAI slot.
::  This recognizes token shape only, not validity or authorization. New device
::  credentials have a dedicated slot and do not need shape inference.
++  jwt-shaped
  |=  token=@t
  =('eyJ' (end 3^3 token))
++  key
  |=  [keys=(map @t @t) provider=@t]
  ^-  @t
  =/  stored  (fall (~(get by keys) provider) '')
  ?:  =('openai' provider)  ?:((jwt-shaped stored) '' stored)
  ?.  =('openai-device' provider)  stored
  ?:  (~(has by keys) provider)  stored
  =/  shared  (fall (~(get by keys) 'openai') '')
  ?:((jwt-shaped shared) shared '')
++  put-key
  |=  [keys=(map @t @t) provider=@t token=@t]
  ::  Saving an API key must not discard a previously saved device login.
  =/  shared  (fall (~(get by keys) 'openai') '')
  =?  keys  &(=('openai' provider) (jwt-shaped shared) !(~(has by keys) 'openai-device'))
    (~(put by keys) 'openai-device' shared)
  (~(put by keys) provider token)
++  missing
  |=  [keys=(map @t @t) cfg=config:h]
  ^-  (unit @t)
  ?.  =('openai' (provider-for-url:hp url.cfg))  ~
  ?:  |(!=('' key.cfg) !=('' (key keys (credential-for-url url.cfg))))  ~
  ?:  (device-route url.cfg)
    `'authentication_error: Device login is selected but no OpenAI device credential is saved. Sign in in OpenAI settings.'
  `'authentication_error: API key is selected but no OpenAI API key is saved. Enter a key or select Device login in model settings.'
++  headers
  |=  [keys=(map @t @t) url=@t extra=(list [name=@t value=@t])]
  ^-  (list [name=@t value=@t])
  ?.  |((device-route url) =('openai' (provider-for-url:hp url)))  extra
  ::  Built-in auth headers cannot override the route's selected credential or
  ::  leak a ChatGPT account onto the API route. Custom endpoints retain theirs.
  =.  extra
    %+  skim  extra
    |=  [name=@t value=@t]
    !(~(has in (silt ~['authorization' 'x-api-key' 'chatgpt-account-id'])) (crip (cass (trip name))))
  =/  account  (key keys 'openai-account')
  ?.  &((device-route url) !=('' account))  extra
  [['chatgpt-account-id' account] extra]
--
