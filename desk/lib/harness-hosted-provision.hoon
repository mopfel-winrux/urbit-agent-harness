::  A complete platform key snapshot replaces only platform-owned slots.
/-  h=harness
/+  ht=harness-tools, j=harness-workspace-json, routing=harness-model-routing
|%
++  apply
  |=  [cfg=config:h keys=(map @t @t) servers=(map mcp-server-id:h mcp-server:h) args=json initialize=?]
  ^-  [config=config:h keys=(map @t @t)]
  =/  supplied  (need (get:j args 'providerKeys'))
  =/  primary  (get:j args 'primary')
  =?  cfg  &(initialize ?=(^ primary))
    =/  choice  (snag 0 (parse:routing [%a ~[u.primary]]))
    cfg(url (endpoint:routing provider.choice), model model.choice, key '', headers ~, max-context 80.000)
  =/  fallbacks  (get:j args 'fallbacks')
  =?  cfg  &(initialize ?=(^ fallbacks))
    cfg(fallbacks (parse:routing u.fallbacks))
  ?>  ?=(%o -.supplied)
  =/  names=(list @t)  ~['openai' 'anthropic' 'xai' 'openrouter' 'brave']
  ?>  (levy ~(tap by p.supplied) |=([name=@t value=json] ?&((lien names |=(n=@t =(n name))) ?=(%s -.value) (lte (met 3 p.value) 8.192))))
  =.  keys
    =/  remaining  names
    |-  ^+  keys
    ?~  remaining  keys
    =/  slot  (cat 3 'hosted-' i.remaining)
    =/  value  (~(get by p.supplied) i.remaining)
    ?~  value  $(remaining t.remaining, keys (~(del by keys) slot))
    ?>  ?=(%s -.u.value)
    $(remaining t.remaining, keys (~(put by keys) slot p.u.value))
  =/  grants  (turn (enabled-mcp:ht servers) |=(id=@t `tool-grant:h`[%mcp id]))
  =.  tools.cfg  ~(tap in (~(uni in (silt tools.cfg)) (silt grants)))
  [cfg keys]
--
