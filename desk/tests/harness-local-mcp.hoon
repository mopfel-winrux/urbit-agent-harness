/-  h=harness, *harness-store
/+  *test, local=harness-local-mcp, storage=harness-store
|%
++  test-registration-waits-for-the-running-local-agent
  (expect-eq !>([0 *(map mcp-server-id:h mcp-server:h)]) !>((ensure:local ~ 0 ~nec |)))
++  test-local-registration-has-ship-name-and-no-http-credentials
  =/  out  (ensure:local ~ 0 ~nec &)
  ;:  weld
    (expect-eq !>(1) !>(seen.out))
    (expect-eq !>(['~nec-mcp' 'urbit://~nec/mcp-server' ~ &]) !>((~(got by registry.out) '~nec-mcp')))
  ==
++  test-existing-disabled-or-custom-server-is-preserved
  =/  registry=(map mcp-server-id:h mcp-server:h)
    (my ~[['~nec-mcp' ['Custom' 'https://example.com/mcp' ~ |]]])
  (expect-eq !>([1 registry]) !>((ensure:local registry 0 ~nec &)))
++  test-deleted-registration-stays-deleted-after-reload
  =/  saved=state-19  *state-19
  =.  local-mcp-seen.saved  1
  =/  loaded  (load:storage !>(saved))
  (expect-eq !>([1 *(map mcp-server-id:h mcp-server:h)]) !>((ensure:local mcp-servers.loaded local-mcp-seen.loaded ~nec &)))
--
