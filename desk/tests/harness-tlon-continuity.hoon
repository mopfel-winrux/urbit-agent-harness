/-  t=harness-tlon, h=harness, cr=harness-cron
/+  *test, c=harness-tlon-continuity
|%
++  policy
  ^-  policy:t
  [& `~lux (my ~[[~bud ~[%web]]]) &]
++  dm
  ^-  lane:t
  [~bud [%dm ~bud ~] 7 ~[%web]]
++  test-unrelated-grant-change-preserves-conversation
  =/  policy  policy
  =/  next  policy(trusted (~(put by trusted.policy) ~zod ~[%skills]))
  (expect !>(!(affected:c policy next dm)))
++  test-grant-order-is-not-a-revocation
  =/  policy  policy
  =/  before  policy(trusted (my ~[[~bud ~[%web %skills]]]))
  =/  after  policy(trusted (my ~[[~bud ~[%skills %web %web]]]))
  (expect !>(!(affected:c before after dm)))
++  test-actor-grant-change-retires-its-authorization
  =/  policy  policy
  =/  next  policy(trusted (my ~[[~bud ~[%skills]]]))
  (expect !>((affected:c policy next dm)))
++  test-removal-and-regrant-are-not-the-same-authority
  =/  policy  policy
  =/  revoked  policy(trusted ~)
  (expect !>(&((affected:c policy revoked dm) (affected:c revoked policy dm))))
++  test-owner-handoff-preserves-unrelated-trusted-actor
  =/  policy  policy
  (expect !>(!(affected:c policy policy(owner `~nec) dm)))
++  test-promotion-changes-authority-even-with-same-tools
  =/  policy  policy
  (expect !>((affected:c policy policy(owner `~bud) dm)))
++  test-mentions-change-affects-channels-not-dms
  =/  policy  policy
  =/  dm  dm
  =/  next  policy(mentions |)
  =/  channel  dm(to [%channel [%chat ~nec %test] ~])
  (expect !>(&(!(affected:c policy next dm) (affected:c policy next channel))))
++  test-disable-and-enable-fence-all-actors
  =/  policy  policy
  =/  disabled  policy(enabled |)
  (expect !>(&((affected:c policy disabled dm) (affected:c disabled policy dm))))
++  test-binding-generation-is-separate-from-identity
  =/  dm  dm
  =/  sid  (identity:c ~bud to.dm)
  (expect !>(&(!=((binding:c sid 7) (binding:c sid 8)) =(sid (identity:c ~bud to.dm)))))
++  test-unrelated-edit-keeps-existing-admission-cutoff
  =/  policy  policy
  =/  new  policy(trusted (~(put by trusted.policy) ~zod ~[%skills]))
  =/  cuts  (cutoffs:c policy new ~ (my ~[[~bud ~2026.9.5]]) ~2026.9.6)
  (expect !>(&(=(~2026.9.5 (~(got by cuts) ~bud)) =(~2026.9.6 (~(got by cuts) ~zod)))))
++  test-cutoff-tombstones-are-bounded
  =/  cuts  (cutoffs:c policy policy ~ (my ~[[~nec ~2026.9.5]]) ~2026.9.6)
  (expect !>(!(~(has by cuts) ~nec)))
++  test-identities-separate-actors-and-exact-threads
  =/  dm  dm
  =/  sid  (identity:c ~bud to.dm)
  (expect !>(&(!=(sid (identity:c ~lux to.dm)) !=(sid (identity:c ~bud [%dm ~bud `[~bud ~2026.9.6]])))))
++  test-migration-keeps-current-head-and-legacy-binding
  =/  dm  dm
  =/  old=state-10:t  *state-10:t
  =.  lanes.old  (my ~[['legacy-head' dm]])
  =/  next  (upgrade:c old)
  (expect !>(&(=('legacy-head' (~(got by identities.next) [~bud to.dm])) =(['legacy-head' %ready] (~(got by routes.next) 'legacy-head')) =(lanes.old lanes.next))))
++  test-migration-does-not-alias-scheduled-heads
  =/  dm  dm
  =/  old=state-10:t  *state-10:t
  =.  lanes.old  (my ~[['legacy-head' dm] ['cron-head' dm]])
  =/  job=job-0:cr  *job-0:cr
  =.  cron.old  (my ~[[0v1 job(sid 'legacy-head', run-sid 'cron-head')]])
  =/  next  (upgrade:c old)
  (expect !>(&(=(1 ~(wyt by identities.next)) =('legacy-head' (~(got by identities.next) [~bud to.dm])) =(2 ~(wyt by routes.next)))))
++  test-migration-keeps-unfinished-creation-closed
  =/  dm  dm
  =/  old=state-10:t  *state-10:t
  =.  lanes.old  (my ~[['legacy-head' dm]])
  =.  jobs.old  (my ~[[0v1 [[~bud 'event' to.dm 'text'] 'legacy-head' %create '']]])
  =/  next  (upgrade:c old)
  (expect !>(=(%create phase:(~(got by routes.next) 'legacy-head'))))
--
