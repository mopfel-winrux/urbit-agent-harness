/-  t=harness-tlon, a=tlon-activity-ver, ct=tlon-contacts
/+  *test, p=harness-tlon-policy, story=harness-tlon-story, ht=harness-tools, profile=harness-tlon-profile, presence=harness-tlon-presence
|%
++  test-presence-threads-share-one-context
  =/  a=$>(%dm destination:t)  [%dm ~nec ~]
  =/  b  a(parent `[~nec ~2026.9.4])
  (expect-eq !>((context:presence a)) !>((context:presence b)))
++  test-presence-aggregation-keeps-tools-visible
  =/  to=destination:t  [%dm ~nec ~]
  =/  active  (merge:presence ~ to &)
  (expect-eq !>(active) !>((merge:presence active to |)))
++  test-presence-renews-only-when-due
  =/  active=(map path ?)  (my ~[[/dm/~nec |]])
  =/  first  (sync:presence ~lux ~2026.9.5 ~ active)
  =/  early  (sync:presence ~lux (add ~2026.9.5 ~s2) +.first active)
  =/  due  (sync:presence ~lux (add ~2026.9.5 ~s10) +.early active)
  (expect !>(&(=(1 (lent -.first)) =(~ -.early) =(1 (lent -.due)))))
++  test-presence-clear-and-start-are-both-emitted
  =/  old=(map path presence-lease:t)  (my ~[[/dm/~nec [~2026.9.5 |]]])
  =/  active=(map path ?)  (my ~[[/dm/~zod &]])
  =/  out  (sync:presence ~lux ~2026.9.5 old active)
  (expect !>(&(=(2 (lent -.out)) !(~(has by +.out) /dm/~nec) (~(has by +.out) /dm/~zod))))
++  test-presence-disable-clears-every-context
  =/  old=(map path presence-lease:t)  (my ~[[/dm/~nec [~2026.9.5 |]] [/channel/chat/~nec/test [~2026.9.5 &]]])
  =/  out  (sync:presence ~lux ~2026.9.5 old ~)
  (expect !>(&(=(2 (lent -.out)) =(~ +.out))))
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
++  policy  `policy:t`[& `~zod (my ~[[~nec ~[%clay]] [~bud ~]]) &]
++  dm
  |=  who=@p
  ^-  incoming-event:v8:a
  [%dm-post [[who ~2026.9.4] ~2026.9.4] [%ship who] ~[[%inline ~['hello']]] |]
++  test-owner-has-all-tools
  (expect-eq !>(`all-tools:ht) !>((grants:p policy ~zod)))
++  test-trusted-can-have-no-tools
  (expect-eq !>(`(list term)`~) !>((need (grants:p policy ~bud))))
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
