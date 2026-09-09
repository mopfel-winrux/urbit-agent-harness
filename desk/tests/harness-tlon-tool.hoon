/-  t=harness-tlon, a=tlon-activity-ver
/+  *test, spec=harness-tlon-tool, deny=harness-tlon-denial, ht=harness-tools, defaults=harness-defaults, clock=harness-tlon-clock
|%
++  test-catalog-and-independent-grant
  (expect !>(&(=(~[%tlon] (tool-families:ht ~[%tlon])) (tool-granted:ht 'tlon' default-tools:defaults) !(tool-granted:ht 'tlon' ~[%tlon-read %tlon-write]) =(`%harness-tlon (tool-hand:ht 'tlon')) =(~[%tlon] (without-tlon:ht ~[%tlon %tlon-read])))))
++  test-parallel-sending-guidance
  =/  jon  schema:spec
  =/  text  (en:json:html jon)
  (expect-eq !>([& & & &]) !>([=(%o -.jon) (find-sub:ht 'automatically delivered' text) (find-sub:ht 'parallel channels' text) (find-sub:ht 'Do not use send_dm or send_channel to answer that conversation' text)]))
++  test-identifiers
  (expect !>(&(=([~nec %test] (flag:spec '~nec/test')) =([%chat ~nec %test] (nest:spec 'chat/~nec/test')) =(~ (mole |.((flag:spec '~nec/test/extra')))) =(~ (mole |.((ship:spec 'nec')))) =(~ (mole |.((slug:spec '../escape')))))))
++  test-denial-authentic-addresses
  =/  post=incoming-event:v8:a  [%dm-post [[~nec ~2026.9.9] ~2026.9.9] [%ship ~nec] ~ |]
  ?>  ?=(%dm-post -.post)
  (expect !>(&(=(`~nec (sender:deny ~lux post)) =(~ (sender:deny ~lux post(whom [%ship ~zod]))) =(~ (sender:deny ~nec post)) =(`~nec (sender:deny ~lux [%dm-invite %ship ~nec])))))
++  test-denial-rate-and-deduplication
  =/  notices=(list notice:t)  ~[[0 ~2026.9.9 'permission-denied' ~nec '~nec' 'event']]
  (expect !>(&(!(allowed:deny (add ~2026.9.9 ~m1) ~nec 'next' notices) (allowed:deny (add ~2026.9.9 ~m5) ~nec 'next' notices) !(allowed:deny (add ~2026.9.9 ~m5) ~nec 'event' notices) (allowed:deny ~2026.9.9 ~bud 'new' notices))))
++  test-denial-global-budget
  =/  notices=(list notice:t)
    (turn (gulf 1 8) |=(n=@ud `notice:t`[n ~2026.9.9 'permission-denied' `@p`n '' '']))
  (expect !>(&(!(allowed:deny ~2026.9.9 ~zod 'fresh' notices) (allowed:deny (add ~2026.9.9 ~m1) ~zod 'fresh' notices))))
++  test-denial-channel-addressing
  =/  post=incoming-event:v8:a  [%post [[~nec ~2026.9.9] ~2026.9.9] [%chat ~bud %test] [~bud %test] ~ |]
  ?>  ?=(%post -.post)
  =/  reply=incoming-event:v8:a  [%reply [[~nec ~2026.9.9] ~2026.9.9] [[~lux ~2026.9.8] ~2026.9.8] [%chat ~bud %test] [~bud %test] ~ |]
  (expect !>(&(=(~ (sender:deny ~lux post)) =(`~nec (sender:deny ~lux post(mention &))) =(`~nec (sender:deny ~lux reply)))))
++  test-tool-deadline-with-tlon-replies-disabled
  =/  state=state:t  *state:t
  =.  enabled.policy.state  |
  =.  tool-receipts.state  (my ~[[0v1 `tool-receipt:t`[['s' 1 ['c' 'tlon' '{}']] %sending 'pending' ~2026.9.9]]])
  (expect !>(&(!enabled.policy.state =(`(add ~2026.9.9 ~m1) (deadline:clock ~2026.9.9 state)) =(~ (deadline:clock ~2026.9.9 state(tool-receipts ~))))))
--
