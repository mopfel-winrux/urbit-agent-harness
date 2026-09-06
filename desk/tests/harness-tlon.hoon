/-  t=harness-tlon, h=harness, a=tlon-activity-ver, ct=tlon-contacts, ad=harness-adapter, dv=tlon-channels-ver
/+  *test, p=harness-tlon-policy, story=harness-tlon-story, ht=harness-tools, profile=harness-tlon-profile, presence=harness-tlon-presence, clock=harness-tlon-clock, io=harness-tlon-io, publication=harness-tlon-publication
|%
++  test-channel-confirmation-matches-author-and-client-stamp
  =/  post=post:v9:dv  *post:v9:dv
  =.  +.+.post  +.+.post(author ~lux, sent ~2026.9.5)
  =/  response=r-channels:v9:dv  [[%chat ~nec %fixture] %post ~2026.9.6 %set %& post]
  (expect-eq !>(~[`publication-proof:t`[[%channel [%chat ~nec %fixture] ~] ~2026.9.5 ~2026.9.6]]) !>((channel:publication ~lux response)))
++  test-channel-confirmation-ignores-other-authors-and-tombstones
  =/  post=post:v9:dv  *post:v9:dv
  =.  +.+.post  +.+.post(author ~bud)
  =/  response=r-channels:v9:dv  [[%chat ~nec %fixture] %post ~2026.9.6 %set %& post]
  =/  deleted=r-channels:v9:dv  [[%chat ~nec %fixture] %post ~2026.9.6 %set %| *tombstone:v9:dv]
  (expect !>(&(=(~ (channel:publication ~lux response)) =(~ (channel:publication ~lux deleted)))))
++  test-channel-confirmation-ignores-pending-client-echoes
  =/  response=r-channels:v9:dv
    [[%chat ~nec %fixture] %pending [~lux ~2026.9.5] *r-pending:v9:dv]
  (expect-eq !>(`(list publication-proof:t)`~) !>((channel:publication ~lux response)))
++  test-thread-confirmation-retains-the-parent
  =/  reply=reply:v9:dv  *reply:v9:dv
  =.  +.+.reply  +.+.reply(author ~lux, sent ~2026.9.5)
  =/  response=r-channels:v9:dv
    [[%chat ~nec %fixture] %post ~2026.9.4 %reply ~2026.9.6 *reply-meta:v9:dv %set %& reply]
  (expect-eq !>(~[`publication-proof:t`[[%channel [%chat ~nec %fixture] `~2026.9.4] ~2026.9.5 ~2026.9.6]]) !>((channel:publication ~lux response)))
++  test-channel-publication-keeps-the-versioned-groups-client-route
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~lux
  =/  card  (publish:~(. io bowl) /test [%channel [%chat ~nec %fixture] ~] 'hello' ~2026.9.5)
  (expect !>(?=([%pass * %agent [@ %channels] %poke %channel-action-1 *] card)))
++  test-dm-publication-keeps-its-native-local-messenger-route
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~lux
  =/  card  (publish:~(. io bowl) /test [%dm ~nec ~] 'hello' ~2026.9.5)
  (expect !>(?=([%pass * %agent [@ %chat] %poke %chat-dm-action-2 *] card)))
++  test-message-stamps-are-distinct-in-one-native-event
  =/  first  (next-message-stamp:p ~2026.9.5 `@da`0)
  =/  second  (next-message-stamp:p ~2026.9.5 first)
  =/  third  (next-message-stamp:p ~2026.9.4 second)
  (expect !>(&((lth first second) (lth second third) =(second (slav %da (scot %da second))))))
++  test-delivery-migration-keeps-all-previous-evidence
  =/  old=state-5:t  *state-5:t
  =.  epoch.old  31
  =.  deliveries.old  (my ~[[0v1 [2 %send %uncertain 'native-message-id']]])
  =.  wake.old  `~2026.9.4
  =/  next  (upgrade-delivery:p old)
  (expect !>(&(=(0 last-sent.next) =(+.old +.+.next))))
++  test-message-routing-and-stale-wakes-never-create-a-timer
  =/  state=state:t  *state:t
  =.  policy.state  [& `~bud ~ &]
  =.  watching.state  &
  =.  wake.state  `~2026.9.4
  =.  lanes.state  (my ~[['s' [~bud [%dm ~bud ~] 0 ~]]])
  =.  deliveries.state  (~(put by deliveries.state) 0v1 `delivery:t`[1 %send %uncertain 'external'])
  (expect-eq !>(`(unit @da)`~) !>((deadline:clock ~2026.9.5 state)))
++  test-maintenance-renews-the-presence-lease-at-its-deadline
  =/  state=state:t  *state:t
  =.  policy.state  [& `~bud ~ &]
  =.  watching.state  &
  =.  computing.state  (my ~[[/dm/~bud [~2026.9.5 ~]]])
  (expect-eq !>(`(unit @da)`[~ (add ~2026.9.5 ~s10)]) !>((deadline:clock ~2026.9.5 state)))
++  test-maintenance-tool-timeout-is-not-a-message-poll
  =/  state=state:t  *state:t
  =.  policy.state  [& `~bud ~ &]
  =.  watching.state  &
  =.  tool-receipts.state
    (my ~[[0v1 [['s' 1 ['call' 'tlon_react' '{}']] %sending '' ~2026.9.5]]])
  (expect-eq !>(`(unit @da)`[~ (add ~2026.9.5 ~m1)]) !>((deadline:clock ~2026.9.5 state)))
++  test-disabled-hand-has-no-maintenance-wake
  =/  state=state:t  *state:t
  =.  enabled.policy.state  |
  =.  computing.state  (my ~[[/dm/~bud [~2026.9.5 ~]]])
  (expect-eq !>(`(unit @da)`~) !>((deadline:clock ~2026.9.5 state)))
++  test-tool-upgrade-preserves-existing-admission-and-delivery-evidence
  =/  old=state-3:t  *state-3:t
  =.  epoch.old  19
  =.  lanes.old  (my ~[['s' [~nec [%dm ~nec ~] 19 ~[%web]]]])
  =.  computing.old  (my ~[[/dm/~nec [~2026.9.5 &]]])
  =.  deliveries.old  (~(put by deliveries.old) 0v1 `delivery:t`[2 %send %uncertain 'external-id'])
  =/  next  (upgrade-tools:p old)
  (expect !>(&(=(lanes.old lanes.next) =(computing.old computing.next) =(deliveries.old deliveries.next) =(19 epoch.next) =(~ cron.next) =(~ tool-receipts.next))))
++  test-hand-tool-generations-have-distinct-receipt-identities
  =/  req=tool-request:ad  ['fixture' 1 ['reused-id' 'tlon_react' '{}']]
  (expect !>(!=((sham req) (sham req(generation 2)))))
++  test-tlon-participation-implies-all-conversation-tools
  =/  tools  (with-tlon:ht ~)
  (expect !>(&((tool-granted:ht 'tlon_read_history' tools) (tool-granted:ht 'tlon_react' tools) (tool-granted:ht 'cron_add' tools) !(tool-granted:ht 'http_fetch' tools) !(tool-granted:ht 'call_mcp_tool' tools))))
++  test-legacy-tlon-flags-do-not-authorize-unbound-sessions
  (expect-eq !>(`(list tool-grant:h)`~[%web]) !>((without-tlon:ht ~[%tlon-read %web %tlon-write %cron])))
++  test-tlon-is-not-a-configurable-resource-grant
  (expect !>((levy configurable-tools:ht |=(family=term !?=(?(%tlon-read %tlon-write %cron) family)))))
++  test-rehearsals-cannot-retain-tlon-effects-or-cron
  (expect-eq !>(`(list tool-grant:h)`~) !>((rehearsal-tools:ht ~[%tlon-read %tlon-write %cron])))
++  test-presence-threads-share-one-context
  =/  a=$>(%dm destination:t)  [%dm ~nec ~]
  =/  b  a(parent `[~nec ~2026.9.4])
  (expect-eq !>((context:presence a)) !>((context:presence b)))
++  test-presence-aggregation-keeps-tools-visible
  =/  to=destination:t  [%dm ~nec ~]
  =/  active  (merge:presence ~ to (silt ~['web_search']))
  (expect-eq !>(active) !>((merge:presence active to ~)))
++  test-presence-renews-only-when-due
  =/  active=(map path (set @t))  (my ~[[/dm/~nec ~]])
  =/  first  (sync:presence ~lux ~2026.9.5 ~ active)
  =/  early  (sync:presence ~lux (add ~2026.9.5 ~s2) +.first active)
  =/  due  (sync:presence ~lux (add ~2026.9.5 ~s10) +.early active)
  (expect !>(&(=(1 (lent -.first)) =(~ -.early) =(1 (lent -.due)))))
++  test-presence-clear-and-start-are-both-emitted
  =/  old=(map path presence-lease:t)  (my ~[[/dm/~nec [~2026.9.5 ~]]])
  =/  active=(map path (set @t))  (my ~[[/dm/~zod (silt ~['web_search'])]])
  =/  out  (sync:presence ~lux ~2026.9.5 old active)
  (expect !>(&(=(2 (lent -.out)) !(~(has by +.out) /dm/~nec) (~(has by +.out) /dm/~zod))))
++  test-presence-disable-clears-every-context
  =/  old=(map path presence-lease:t)  (my ~[[/dm/~nec [~2026.9.5 ~]] [/channel/chat/~nec/test [~2026.9.5 (silt ~['web_search'])]]])
  =/  out  (sync:presence ~lux ~2026.9.5 old ~)
  (expect !>(&(=(2 (lent -.out)) =(~ +.out))))
++  test-presence-tool-name-change-refreshes-within-the-lease
  =/  old=(map path presence-lease:t)  (my ~[[/dm/~nec [~2026.9.5 (silt ~['web_search'])]]])
  =/  active=(map path (set @t))  (my ~[[/dm/~nec (silt ~['http_fetch'])]])
  (expect-eq !>(1) !>((lent -:(sync:presence ~lux (add ~2026.9.5 ~s2) old active))))
++  test-presence-projects-only-unfinished-known-tool-names
  =/  view=view:h  *view:h
  =.  wait.view  (silt ~['pending' 'unknown'])
  =.  items.view
    :~  [%assistant 'private response' ~[['pending' 'read_desk_file' 'old private args']]]
        [%assistant 'private response' ~[['done' 'web_search' 'secret query'] ['pending' 'http_fetch' 'private URL'] ['unknown' 'secret-in-name' 'private args']]]
    ==
  (expect-eq !>((silt ~['http_fetch' 'tools'])) !>((names:presence view)))
++  test-presence-empty-wait-does-not-revive-past-tools
  =/  view=view:h  *view:h
  =.  items.view  ~[[%assistant '' ~[['old' 'web_search' '{}']]]]
  (expect-eq !>(`(set @t)`~) !>((names:presence view)))
++  test-presence-display-uses-current-groups-payload
  =/  shown  (display:presence (silt ~['web_search']))
  =/  blob  (need (de:json:html (need blob.shown)))
  =/  expected
    %-  pairs:enjs:format
    :~  ['protocol' %s 'tlon.computing-status.v1']
        ['thinking' %b |]
        ['toolCalls' %a ~[(pairs:enjs:format ~[['toolName' %s 'web_search'] ['label' %s 'Searching the web']])]]
    ==
  (expect-eq !>(expected) !>(blob))
++  test-presence-migration-preserves-authority-jobs-and-delivery
  =/  old=state-4:t  *state-4:t
  =.  epoch.old  23
  =.  lanes.old  (my ~[['s' [~nec [%dm ~nec ~] 23 ~[%web]]]])
  =.  deliveries.old  (~(put by deliveries.old) 0v1 `delivery:t`[2 %send %uncertain 'external-id'])
  =.  computing.old  (my ~[[/dm/~nec [~2026.9.5 &]]])
  =/  next  (upgrade-presence:p old)
  (expect !>(&(=(lanes.old lanes.next) =(deliveries.old deliveries.next) =(cron.old cron.next) =(tool-receipts.old tool-receipts.next) =(23 epoch.next) =(policy.old policy.next) (~(has by computing.next) /dm/~nec) =(0 at:(~(got by computing.next) /dm/~nec)))))
++  test-profile-edits-only-nickname-and-avatar
  =/  patch  (decode:profile (pairs:enjs:format ~[['nickname' %s 'Bot'] ['avatar' %s 'https://example.com/bot.png']]))
  (expect-eq !>(`contact:ct`(my ~[[%nickname %text 'Bot'] [%avatar %look %'https://example.com/bot.png']])) !>(patch))
++  test-profile-empty-fields-remove-attributes
  =/  patch  (decode:profile (pairs:enjs:format ~[['nickname' %s ''] ['avatar' %s '']]))
  (expect-eq !>(`contact:ct`(my ~[[%nickname ~] [%avatar ~]])) !>(patch))
++  test-profile-ignores-unrelated-fields
  =/  con=contact:ct  (my ~[[%nickname %text 'Bot'] [%bio %text 'Keep me']])
  (expect-eq !>((pairs:enjs:format ~[['nickname' %s 'Bot'] ['avatar' %s '']])) !>((encode:profile con)))
++  test-profile-rejects-script-urls
  =/  result  (mule |.((decode:profile (pairs:enjs:format ~[['nickname' %s 'Bot'] ['avatar' %s 'javascript:alert(1)']]))))
  (expect !>(?=(%| -.result)))
++  policy  `policy:t`[& `~zod (my ~[[~nec ~[[%clay /harness/lib]]] [~bud ~]]) &]
++  dm
  |=  who=@p
  ^-  incoming-event:v8:a
  [%dm-post [[who ~2026.9.4] ~2026.9.4] [%ship who] ~[[%inline ~['hello']]] |]
++  test-owner-inherits-configured-defaults-not-the-catalog
  (expect-eq !>(`(list term)`~[%web %skills]) !>((need (grants:p policy ~zod ~[%web %skills]))))
++  test-owner-can-chat-with-no-default-tools
  (expect-eq !>(`(unit (list term))`[~ ~]) !>((grants:p policy ~zod ~)))
++  test-trusted-does-not-inherit-owner-defaults
  (expect-eq !>(`(list tool-grant:h)`~[[%clay /harness/lib]]) !>((need (grants:p policy ~nec all-tools:ht))))
++  test-trusted-can-have-no-tools
  (expect-eq !>(`(list term)`~) !>((need (grants:p policy ~bud all-tools:ht))))
++  test-strangers-are-not-admitted
  (expect-eq !>(`(unit input:t)`~) !>((normalize:p ~lux policy (dm ~wes))))
++  test-disable-revokes-admission
  =/  cfg  policy
  (expect-eq !>(`(unit input:t)`~) !>((normalize:p ~lux cfg(enabled |) (dm ~zod))))
++  test-dms-do-not-need-mentions
  (expect !>(?=(^ (normalize:p ~lux policy (dm ~zod)))))
++  test-self-messages-do-not-loop
  (expect-eq !>(`(unit input:t)`~) !>((normalize:p ~zod policy (dm ~zod))))
++  test-channel-address-requires-mention
  =/  evt=$>(%post incoming-event:v8:a)
    [%post [[~zod ~2026.9.4] ~2026.9.4] [%chat ~zod %test] [~zod %test] ~[[%inline ~['hello']]] |]
  (expect !>(&(=(~ (normalize:p ~lux policy evt)) ?=(^ (normalize:p ~lux policy evt(mention &))))))
++  test-session-identity-separates-actors-and-threads
  =/  to=$>(%channel destination:t)  [%channel [%chat ~zod %test] ~]
  =/  sid  (session-id:p 1 ~zod to)
  (expect !>(&(!=(sid (session-id:p 1 ~nec to)) !=(sid (session-id:p 2 ~zod to)) !=(sid (session-id:p 1 ~zod to(parent `~2026.9.4))))))
++  test-dm-thread-keeps-author-id-not-activity-time
  =/  evt=incoming-event:v8:a
    [%dm-reply [[~zod ~2026.9.4] ~2026.9.5] [[~nec ~2026.9.2] ~2026.9.3] [%ship ~zod] ~[[%inline ~['hello']]] |]
  =/  input  (need (normalize:p ~lux policy evt))
  (expect-eq !>(`destination:t`[%dm ~zod `[~nec ~2026.9.2]]) !>(to.input))
++  test-policy-json-roundtrips
  (expect-eq !>(policy) !>((json-policy:p (policy-json:p policy))))
++  test-story-preserves-ships-and-formatting
  (expect-eq !>('hello ~zod and bold') !>((story-to-text:story (text-to-story:story 'hello ~zod and **bold**'))))
++  test-code-fence-preserves-blank-lines-and-literal-delimiters
  (expect-eq !>(`@t`'```js\0a**literal**\0a\0aline\0a\0a```') !>((story-to-text:story (text-to-story:story '```js\0a**literal**\0a\0aline\0a```'))))
++  test-story-links-keep-their-destination
  (expect-eq !>('docs (https://urbit.org)') !>((story-to-text:story (text-to-story:story '[docs](https://urbit.org)'))))
--
