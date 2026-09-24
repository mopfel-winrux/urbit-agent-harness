::  Ordered, bounded model failover. Routing never carries credentials or
::  relaxes the request's privacy policy, instructions, or tool grants.
/-  h=harness
/+  auth=harness-auth, provider=harness-provider, j=harness-workspace-json
|%
++  endpoint
  |=  name=@t
  ?:  =('openrouter' name)  'https://openrouter.ai/api/v1/chat/completions'
  ?:  =('openai' name)  'https://api.openai.com/v1/responses'
  ?:  =('anthropic' name)  'https://api.anthropic.com/v1/chat/completions'
  ?:  =('xai' name)  'https://api.x.ai/v1/chat/completions'
  ''
++  parse
  |=  value=json
  ^-  (list model-choice:h)
  ?>  ?=(%a -.value)
  ?>  (lte (lent p.value) 4)
  =/  models
    %+  turn  p.value
    |=  entry=json
    =/  name  (string:j entry 'provider')
    =/  model  (string:j entry 'model')
    ?>  &(!=('' (endpoint name)) !=('' model) (lte (met 3 model) 256))
    [name model]
  ?>  =((lent models) (lent ~(tap in (silt models))))
  models
++  next
  |=  [cfg=config:h keys=(map @t @t)]
  ^-  (unit config:h)
  ?~  fallbacks.cfg  ~
  =/  choice  i.fallbacks.cfg
  =/  remaining=config:h  cfg(fallbacks t.fallbacks.cfg)
  =/  url  (endpoint provider.choice)
  ?:  |(=('' url) &(zdr.cfg !=('openrouter' provider.choice)) &(=(url url.cfg) =(model.choice model.cfg)))
    $(cfg remaining)
  =/  candidate  remaining(url url, model model.choice, headers ~, key '', max-context 80.000)
  ?:  =('' (key:auth keys provider.choice))  $(cfg remaining)
  ?^  (missing:auth keys candidate)  $(cfg remaining)
  `candidate
++  active
  |=  [v=view:h req=@ud]
  ^-  config:h
  ?:  &(?=(^ route.v) =(req req.u.route.v))  config.u.route.v
  config.v
--
