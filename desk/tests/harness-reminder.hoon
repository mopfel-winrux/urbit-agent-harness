/-  t=harness-tlon, cr=harness-cron
/+  *test, r=harness-reminder, p=harness-tlon-policy
|%
++  test-explicit-negative-offset
  (expect-eq !>([~2026.9.7..14.00.00 'UTC-05:00']) !>((parse:r '2026-09-07T09:00:00-05:00' ~2026.9.6)))
++  test-explicit-positive-offset
  (expect-eq !>([~2026.9.7..03.30.00 'UTC+05:30']) !>((parse:r '2026-09-07T09:00:00+05:30' ~2026.9.6)))
++  test-utc-is-explicit
  (expect-eq !>([~2026.9.7..09.00.00 'UTC']) !>((parse:r '2026-09-07T09:00:00Z' ~2026.9.6)))
++  test-missing-unknown-and-invalid-offsets-are-rejected
  =/  cases=(list @t)  ~['2026-09-07T09:00:00' '2026-09-07T09:00:00-00:00' '2026-09-07T09:00:00+14:01' '2026-09-07T09:00:00+03:60' '2026-09-07T09:00:00America/Chicago']
  %-  expect  !>
  %+  levy  cases
  |=  text=@t
  =(~ (mole |.((parse:r text ~2026.9.6))))
++  test-invalid-calendar-dates-are-rejected
  =/  cases=(list @t)  ~['2027-02-29T09:00:00Z' '2026-09-31T09:00:00Z' '2026-13-07T09:00:00Z' '2026-09-07T24:00:00Z' '2026-09-07T09:00:60Z']
  %-  expect  !>
  %+  levy  cases
  |=  text=@t
  =(~ (mole |.((parse:r text ~2026.9.6))))
++  test-horizon-and-past-time-are-rejected
  =/  cases=(list @t)  ~['2026-09-06T00:00:00Z' '2026-09-05T23:59:59Z' '2027-09-07T00:00:00Z']
  %-  expect  !>
  %+  levy  cases
  |=  text=@t
  =(~ (mole |.((parse:r text ~2026.9.6))))
++  test-migration-retains-old-cron-and-conversation-evidence
  =/  old=state-11:t  *state-11:t
  =/  job=job-0:cr  *job-0:cr
  =.  job  job(sid 'source', run-sid 'scheduled', state %paused, next ~2026.9.7, remaining 3, last `0v1)
  =.  cron.old  (my ~[[0v2 job]])
  =.  lanes.old  (my ~[['scheduled' `lane:t`[~bud [%dm ~bud ~] 3 ~]]])
  =/  next  (upgrade-reminders:p old)
  =/  migrated  (~(got by cron.next) 0v2)
  (expect !>(?&(=(%prompt kind.migrated) =('UTC' timezone.migrated) =('dm/~bud' destination.migrated) =(job +.+.+.migrated) =(lanes.old lanes.next) =(deliveries.old deliveries.next) =(identities.old identities.next))))
--
