/-  t=harness-tlon, hh=harness-hand, sl=tlon-steward-lens
/+  *test, l=harness-tlon-lens, r=harness-run-report, p=harness-tlon-policy, io=harness-tlon-io
/=  adapter  /app/harness-tlon
|%
++  test-native-trust-covers-owner-and-trusted-ships-once
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~lux
  =/  policy=policy:t  [| `~bud (my ~[[~bud ~] [~nec ~]]) &]
  =/  cards  (trust-policy:~(. io bowl) policy)
  (expect !>(&(=(2 (lent cards)) (levy cards |=(c=card:agent:gall ?=([%pass * %agent [@ %steward] %poke %steward-action-1 *] c))))))
++  test-empty-policy-does-not-remove-native-trust
  =/  bowl=bowl:gall  *bowl:gall
  (expect-eq !>(`(list card:agent:gall)`~) !>((trust-policy:~(. io bowl) [| ~ ~ &])))
++  test-reload-keeps-pending-export-without-reissuing-the-poke
  =/  state=state:t  *state:t
  =/  record=lens-export:t  [~lux 2 0v1 %sending ~2026.9.6 ~]
  =.  lenses.state  (my ~[[0v1 record]])
  =/  bowl=bowl:gall  *bowl:gall
  =.  now.bowl  ~2026.9.6
  =/  out  (~(on-load adapter bowl) !>(state))
  =/  next  !<(state:t ~(on-save +.out bowl))
  (expect !>(&(=(lenses.state lenses.next) !(lien -.out |=(c=card:agent:gall ?=([%pass * %agent [@ %steward] %poke *] c))))))
++  test-acknowledgement-only-settles-the-dispatched-revision
  =/  record=lens-export:t  [~lux 2 0v1 %sending ~2026.9.6 ~]
  =/  accepted  (acknowledge:l record 2 &)
  (expect !>(&(=(%accepted status.accepted) =(record (acknowledge:l record 1 &)) =(accepted (acknowledge:l accepted 2 |)) =(%failed status:(acknowledge:l record 2 |)))))
++  test-revocation-fences-failed-and-in-flight-exports
  =/  record=lens-export:t  [~lux 2 0v1 %sending ~2026.9.6 ~]
  =/  revoked  (revoke:l record)
  (expect !>(&(=(%revoked status.revoked) =(revoked (acknowledge:l revoked 2 &)) =(%revoked status:(revoke:l record(status %failed))) =(record(status %accepted) (revoke:l record(status %accepted))))))
++  fixture
  |=  delivery=delivery-state:hh
  ^-  json
  =/  pub=publication:hh  [0v1 'binding' 'tlon' 'dm/~lux' 'sid' %reply 'PRIVATE_REPLY' delivery 'harness-tlon' '' ~]
  =/  obs=observation:hh  ['binding' 'PRIVATE_EVENT_ID' '~lux' 'PRIVATE_PROMPT' ~2026.9.6 %completed]
  =/  report=report:r  [~[['PRIVATE_CALL_ID' 'current_time' %completed] ['SECRET_ID' 'other_tool' %uncertain]] 2 |]
  (payload:l ~nec 0v1 pub obs [%dm ~lux ~] `report ~2026.9.6..00.00.01 1 | `~2026.9.6..00.00.02)
++  test-payload-excludes-prompts-results-and-model-call-ids
  =/  text  (trip (en:json:html (fixture %delivered)))
  (expect !>(&(=(~ (find "PRIVATE" text)) =(~ (find "SECRET" text)) ?=(^ (find "current_time" text)) ?=(^ (find "Acceptance is unknown" text)))))
++  test-payload-separates-run-completion-from-delivery
  =/  a  (trip (en:json:html (fixture %uncertain)))
  (expect !>(&(?=(^ (find "Reply acceptance is uncertain" a)) ?=(^ (find "completed" a)) ?=(^ (find "deliveredMessageCount\":0" a)))))
++  test-pointer-is-a-native-blob-without-the-summary
  =/  want  (need (de:json:html '[{"type":"tlon-context-lens","version":1,"lensId":"harness-0v1","botShip":"~nec"}]'))
  (expect-eq !>(want) !>((need (de:json:html (pointer:l ~nec 0v1)))))
++  test-export-uses-native-steward-and-stable-id
  =/  payload  (fixture %delivered)
  =/  want=card:agent:gall  [%pass /lens/0v1/1 %agent [~lux %steward] %poke %steward-lens-action-1 !>(`action:v1:sl`[%entry 'harness-0v1' payload &])]
  (expect-eq !>(want) !>((entry:l ~lux 0v1 1 payload)))
++  test-lens-migration-preserves-history-and-old-upload-evidence
  =/  old=state-9:t  *state-9:t
  =.  epoch.old  29
  =.  uploads.old  (my ~[[0v1 `upload:t`[%put 0v2 'key' 'image/png' 'url' [2 1]]]])
  =/  next  (upgrade-lens:p old ~2026.9.6)
  (expect !>(&(=(+.old +.+.+.next) =(~2026.9.6 lens-after.next) =(~ lenses.next))))
--
