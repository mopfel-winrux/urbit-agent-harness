::  Full adapter, synthetic scries only; no emitted cards are executed.
::  -test /=harness=/tests-integration/harness-tlon-authority
/-  t=harness-tlon, c=harness-cron, ad=harness-adapter
/+  *test, schedule=harness-schedule
/=  adapter  /app/harness-tlon
|%
++  fixture
  ^-  state:t
  =/  s=state:t  *state:t
  =.  owner-initialized.s  1
  =.  policy.s  [& `~nec ~ &]
  =.  lanes.s  (my ~[['source' [~nec [%dm ~nec ~] 1 ~[%web]]]])
  s(routes (my ~[['source' ['binding' %ready]]]))
++  job
  ^-  schedule:c
  =/  j=schedule:c  *schedule:c
  j(sid 'source', run-sid 'run', binding 'binding', kind %prompt)
++  read
  |=  [saved=state:t sid=@t job=(unit schedule:c) allowed=? admin=?]
  ^-  noun
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.10)
  =.  wex.bowl  (~(put by wex.bowl) [/head ~zod %harness] [& /hand-events])
  =/  attempt
    |.
    =/  loaded  (~(on-load adapter bowl) !>(saved))
    =/  path  ?:(admin /x/admin/[sid] /x/authority/[sid])
    =/  peek  (~(on-peek +.loaded bowl) path)
    ?>  ?=(^ peek)
    ?>  ?=(^ u.peek)
    q.u.u.peek
  =/  checked
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  (lien path |=(part=@ta =(%cron-session part)))  ``job
    ?:  (lien path |=(part=@ta =(%cron-authority part)))  ``allowed
    ?:  =(%$ (rear path))  ``&
    ~
  ?>  ?=(%0 -.checked)
  ::  The product is the cage's vase; don't recursively validate its type.
  +.product.checked
++  equal
  |=  [expected=vase actual=vase]
  (expect !>(=(q.expected q.actual)))
++  test-owner-is-unlimited-but-reminders-and-schedules-are-bounded
  =/  s  fixture
  =/  j  job
  ;:  weld
    (equal !>(`hand-authority:ad`[& ~]) !>((read s 'source' ~ & |)))
    (equal !>(`hand-authority:ad`[& `~[%web %tlon-read %tlon-write]]) !>((read s 'run' `j & |)))
    (equal !>(`hand-authority:ad`[& `~]) !>((read s 'run' `j(kind %reminder) & |)))
    (equal !>(&) !>((read s 'source' ~ & &)))
    (equal !>(|) !>((read s 'run' `j & &)))
  ==
++  test-revocation-and-source-binding-changes-are-fresh-on-each-check
  =/  s  fixture
  =/  j  job
  ;:  weld
    (equal !>(`hand-authority:ad`[| ~]) !>((read s 'run' `j | |)))
    (equal !>(`hand-authority:ad`[& `~[%web %tlon-read %tlon-write]]) !>((read s 'run' `j & |)))
    (equal !>(`hand-authority:ad`[| ~]) !>((read s 'run' `j(binding 'replaced') & |)))
    (equal !>(`hand-authority:ad`[| ~]) !>((read s(enabled.policy |) 'run' `j & |)))
    (equal !>(`hand-authority:ad`[| ~]) !>((read s(routes (my ~[['source' ['binding' %config]]])) 'run' `j & |)))
  ==
++  test-trusted-lanes-keep-tool-ceilings-and-legacy-runs-stay-denied
  =/  s  fixture
  =/  j  job
  =.  policy.s  [& ~ (my ~[[~nec ~[%web]]]) &]
  ;:  weld
    (equal !>(`hand-authority:ad`[& `~[%web %tlon-read %tlon-write]]) !>((read s 'source' ~ & |)))
    (equal !>(|) !>((read s 'source' ~ & &)))
    (equal !>(`hand-authority:ad`[| ~]) !>((read s(trusted.policy ~) 'source' ~ & |)))
    (equal !>(`hand-authority:ad`[| ~]) !>((read s(cron (my ~[[0v1 (job-value:schedule j(run-sid 'source'))]])) 'source' ~ & |)))
  ==
--
