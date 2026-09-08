::  Same-ship MCP registration. A native URL names a local Gall endpoint;
::  no guessed Earth hostname, login cookie, or transport credential is stored.
/-  h=harness
|%
++  id
  |=  our=@p
  ^-  @t
  (cat 3 (scot %p our) '-mcp')
++  url
  |=  our=@p
  ^-  @t
  (rap 3 'urbit://' (scot %p our) '/mcp-server' ~)
++  ensure
  |=  [registry=(map mcp-server-id:h mcp-server:h) seen=@ud our=@p present=?]
  ^-  [seen=@ud registry=(map mcp-server-id:h mcp-server:h)]
  ?.  &(present =(0 seen))  [seen registry]
  ::  Existing custom/disabled entries win. The durable marker also respects
  ::  later removal; polling must not silently recreate a deleted server.
  ?:  (~(has by registry) (id our))  [1 registry]
  [1 (~(put by registry) (id our) [(id our) (url our) ~ &])]
--
