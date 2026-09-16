/-  h=harness, sh=harness-shadow
/+  *test, hs=harness-session, shadow=harness-shadow, nexus, session-nexus=harness-session-nexus, root, tarball
|%
++  sample
  ^-  session:h
  [~[[%input-admitted [%user 'hello']] [%config-replaced *config:h]] 0]
++  test-independent-head-check-matches
  =/  ses  sample
  =/  hash  (digest:shadow ses ~)
  =/  result  (check:shadow [%0 ses ~ hash])
  ?>  ?=(%o -.result)
  (expect-eq !>(`json`[%b %.y]) !>((need (~(get by p.result) 'matched'))))
++  test-mismatch-is-observable
  =/  result  (check:shadow [%0 sample ~ 0v0])
  ?>  ?=(%o -.result)
  (expect-eq !>(`json`[%b %.n]) !>((need (~(get by p.result) 'matched'))))
++  test-source-change-invalidates-check
  =/  ses  sample
  =/  hash  (digest:shadow ses ~)
  =.  log.ses  [[%cancelled ~ ~ 'test'] log.ses]
  (expect !>(!=(hash (digest:shadow ses ~))))
++  test-check-does-not-execute-a-decision
  =/  ses  sample
  =/  before  (inspect:hs ses ~)
  =/  result  (check:shadow [%0 ses ~ (digest:shadow ses ~)])
  =/  after  (inspect:hs ses ~)
  (expect-eq !>(before) !>(after))
++  step
  |=  [proc=process:fiber:nexus raw=* budget=@ud]
  =/  m  (fiber:fiber:nexus ,~)
  ^-  output:m
  =/  out  (proc [!>(raw) ~])
  ?.  &(?=(%cont -.next.out) =(~ darts.out) (gth budget 0))  out
  $(proc self.next.out, raw state.out, budget (dec budget))
++  test-root-starts-the-verifier
  =/  input=input:sh  [%0 sample ~ (digest:shadow sample ~)]
  =/  proc  ((on-file:root [/agents/main/shadow-inputs %test] [/ %noun]) ~)
  =/  out  (step proc input 32)
  (expect !>(?=(^ darts.out)))
++  test-crash-checkpoints-without-any-effect
  =/  input=input:sh  [%0 sample ~ (digest:shadow sample ~)]
  =/  proc  ((on-file:session-nexus [/agents/main/shadow-inputs %test] [/ %noun]) `~[leaf+"test failure"])
  =/  out  (step proc input 32)
  (expect !>(&(=(~ darts.out) ?=(%wait -.next.out) ?=([%failed * *] state.out))))
++  test-checkpoint-waits-after-process-restart
  =/  proc  ((on-file:session-nexus [/agents/main/shadow-inputs %test] [/ %noun]) ~)
  =/  failed=failure:sh  [%failed 42 ~[leaf+"test failure"]]
  =/  out  (step proc failed 32)
  (expect !>(&(=(~ darts.out) ?=(%wait -.next.out) =(failed state.out))))
++  test-root-reload-preserves-checkpoint
  =/  failed=failure:sh  [%failed 42 ~[leaf+"test failure"]]
  =/  old  (~(put ba:tarball *ball:tarball) [/agents/main/shadow-inputs %test] [[/ %noun] %& !>(failed)])
  =/  loaded  (on-load:root old)
  =/  retained  (~(get bo:tarball loaded) [/agents/main/shadow-inputs %test])
  ?>  ?=(^ retained)
  (expect-eq !>(`*`failed) !>(q.u.retained))
--
