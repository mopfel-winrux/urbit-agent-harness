/-  t=harness-tlon
/+  *test, p=harness-tlon-policy
/=  adapter  /app/harness-tlon
|%
++  test-removing-exports-preserves-local-work
  =/  old=state-13:t  *state-13:t
  =.  lenses.old  (my ~[[0v1 `lens-export:t`[~zod 3 0v2 %sending ~2026.9.6 ~]]])
  =.  jobs.old  (my ~[[0v2 `job:t`[[~nec 'event' [%dm ~nec ~] 'accepted'] 's' %error 'waiting']]])
  =.  deliveries.old  (my ~[[0v3 `delivery:t`[2 %send %uncertain 'receipt']]])
  =.  activity-through.old  ~2026.9.6
  =/  next  (local-only:p old)
  (expect !>(&(=(jobs.old jobs.next) =(deliveries.old deliveries.next) =(policy.old policy.next) =(activity-through.old activity-through.next) =(cron.old cron.next))))
++  test-reload-does-not-export-or-reconfigure-steward
  =/  old=state-13:t  *state-13:t
  =.  lenses.old  (my ~[[0v1 `lens-export:t`[~zod 3 0v2 %sending ~2026.9.6 ~]]])
  =/  bowl=bowl:gall  *bowl:gall
  =.  now.bowl  ~2026.9.6
  =/  out  (~(on-load adapter bowl) !>(old))
  (expect !>(!(lien -.out |=(c=card:agent:gall ?=([%pass * %agent [* %steward] *] c)))))
--
