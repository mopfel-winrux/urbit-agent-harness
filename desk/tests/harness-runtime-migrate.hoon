/+  *test, migration=harness-runtime-migrate, nexus, tarball
|%
++  test-http-registry-retains-handlers-and-connections
  =/  handler=rail:tarball  [/agents %web]
  =/  old=server-state-0:migration
    [%0 (malt ~[[[~ /app] handler]]) (malt ~[[%request [~ /app]]])]
  =/  current  (server-state:migration old)
  %-  expect
  !>  ?&  =(%1 -.current)
          =(`handler (~(get by bindings.current) /app))
          =(`/app (~(get by conns.current) %request))
      ==
++  test-current-http-registry-is-unchanged
  =/  current=server-state:nexus
    [%1 (malt ~[[/app [/agents %web]]]) (malt ~[[%request /app]])]
  (expect-eq !>(current) !>((server-state:migration current)))
++  test-domain-registry-is-not-silently-flattened
  =/  old=server-state-0:migration
    [%0 (malt ~[[[`'example.com' /app] [/agents %web]]]) ~]
  =/  result  (mule |.((server-state:migration old)))
  (expect !>(?=(%| -.result)))
--
