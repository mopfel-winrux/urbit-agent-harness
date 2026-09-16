/-  a=tlon-activity-ver, t=harness-tlon
/+  *test, p=harness-tlon-activity
|%
++  fixture
  ^-  stream:v10:a
  %+  roll  (gulf 1 40)
  |=  [n=@ud tree=stream:v10:a]
  (put:on-stream:v10:a tree (add ~2026.9.6 n) [[%dm-invite %ship ~bud] | |])
++  times
  |=  rows=(list row:p)
  (turn rows |=(r=row:p at.r))
++  test-forward-pages-are-chronological-and-exclusive
  =/  first  (newer:p fixture ~2026.9.6 17)
  =/  second  (newer:p fixture (add ~2026.9.6 16) 17)
  =/  expected  (turn (gulf 1 33) |=(n=@ud (add ~2026.9.6 n)))
  (expect !>(=(expected (times (weld (scag 16 first) second)))))
++  test-final-page-and-empty-feed
  =/  final  (newer:p fixture (add ~2026.9.6 33) 17)
  (expect !>(&(=(7 (lent final)) =(~ (newer:p ~ ~2026.9.6 17)) =(~ (newer:p fixture (add ~2026.9.6 40) 17)))))
++  test-deleted-cursor-position-does-not-prevent-continuation
  =/  result  (del:on-stream:v10:a fixture (add ~2026.9.6 16))
  =/  tree  +.result
  (expect !>(=((newer:p fixture (add ~2026.9.6 16) 17) (newer:p tree (add ~2026.9.6 16) 17))))
++  test-zero-budget-and-excessive-budget
  =/  excess  (mole |.((newer:p fixture ~2026.9.6 18)))
  (expect !>(&(=(~ (newer:p fixture ~2026.9.6 0)) =(~ excess))))
++  test-new-activity-variants-do-not-become-input
  =/  event=event:v10:a  [[%note-create 1 1 [~bud %test] ~ 'Title' ~bud] | |]
  (expect !>(&(=(~ (supported:p event)) =(`[%dm-invite %ship ~bud] (supported:p [[%dm-invite %ship ~bud] | |])))))
++  test-migration-preserves-work-without-replaying-pre-cursor-history
  =/  old=state-12:t  *state-12:t
  =.  jobs.old  (my ~[[0v1 `job:t`[[~bud 'e' [%dm ~bud ~] 'waiting'] 's' %error 'Head unavailable']]])
  =/  next  (upgrade:p old ~2026.9.6)
  (expect !>(&(=(~2026.9.6 activity-through.next) !catching-up.next =(jobs.old jobs.next) =(policy.old policy.next))))
--
