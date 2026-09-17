/-  h=harness, *harness-store
/+  *test, storage=harness-store
|%
++  test-direct-registration-migrates-without-changing-access
  =/  saved=state-29  *state-29
  =.  local-mcp-seen.saved  1
  =.  mcp-servers.saved
    (my ~[['~nec-mcp' ['Local tools' 'urbit://~nec/mcp-server' ~[['x-fixture' 'value']] |]]])
  =/  loaded  (restore-local-mcp:storage saved ~nec)
  =/  expected  saved(mcp-servers (my ~[['~nec-mcp' ['Local tools' 'urbit://~nec/mcp-proxy' ~[['x-fixture' 'value']] |]]]))
  ;:  weld
    (expect-eq !>(expected) !>(loaded))
    (expect-eq !>(loaded) !>((restore-local-mcp:storage loaded ~nec)))
  ==
++  test-custom-and-deleted-registrations-stay-untouched
  =/  saved=state-29  *state-29
  =.  local-mcp-seen.saved  1
  =/  custom  saved(mcp-servers (my ~[['~nec-mcp' ['Custom' 'https://example.com/mcp' ~ &]]]))
  =/  foreign  saved(mcp-servers (my ~[['~nec-mcp' ['Other ship' 'urbit://~zod/mcp-server' ~ &]]]))
  ;:  weld
    (expect-eq !>(saved) !>((restore-local-mcp:storage saved ~nec)))
    (expect-eq !>(custom) !>((restore-local-mcp:storage custom ~nec)))
    (expect-eq !>(foreign) !>((restore-local-mcp:storage foreign ~nec)))
  ==
--
