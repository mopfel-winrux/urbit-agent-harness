::  A complete platform key snapshot replaces only platform-owned slots.
/-  h=harness
/+  ht=harness-tools, j=harness-workspace-json
|%
++  apply
  |=  [cfg=config:h keys=(map @t @t) servers=(map mcp-server-id:h mcp-server:h) args=json]
  ^-  [config=config:h keys=(map @t @t)]
  =/  supplied  (need (get:j args 'providerKeys'))
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
