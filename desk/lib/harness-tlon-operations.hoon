::  Ship-wide Tlon operations. The adapter owns live grants and receipts;
::  this core reads public native state and builds one effect per invocation.
/-  t=harness-tlon, g=tlon-groups-ver, d=tlon-channels-ver, ct=tlon-contacts, meta=tlon-meta
/-  cite=tlon-cite
/+  spec=harness-tlon-tool, io=harness-tlon-io, conversation=harness-tlon-conversation-tool, contact=harness-tlon-contact-tool, group-tool=harness-tlon-group-tool, policy=harness-tlon-group-policy, message=harness-tlon-message-tool
/+  notes=harness-tlon-notes-tool, inbox=harness-tlon-inbox-tool, club=harness-tlon-club-tool
/+  hooks=harness-tlon-hook-tool, publishing=harness-tlon-publish-tool
|_  bowl=bowl:gall
++  groups
  ^-  groups:v9:g
  ?>  .^(? %gu /(scot %p our.bowl)/groups/(scot %da now.bowl)/$)
  .^(groups:v9:g %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v2/groups/noun)
++  group-id
  |=  flag=[@p @tas]
  (rap 3 (scot %p -.flag) '/' +.flag ~)
++  channel-id
  |=  nest=[@tas @p @tas]
  (rap 3 -.nest '/' (group-id +.nest) ~)
++  metadata
  |=  [args=json old=data:meta]
  ^-  data:meta
  ?>  |((has:spec args 'title') (has:spec args 'description'))
  =/  title  (string:spec args 'title' title.old 128)
  ?>  !=('' title)
  old(title title, description (string:spec args 'description' description.old 1.024))
++  run
  |=  [args=json wire=wire sent=@da]
  ^-  [body=@t effect=(unit card:agent:gall)]
  =/  action  (required:spec args 'action' 32)
  ?:  =('help' action)  [help:spec ~]
  ?:  (handles:~(. hooks bowl) action)
    ?>  ?=([@ @ ~] wire)
    (run:~(. hooks bowl) args /tlon-hooks/[i.t.wire])
  ?:  (handles:~(. publishing bowl) action)  (run:~(. publishing bowl) args wire)
  ?:  &(=('edit_message' action) !(has:spec args 'channel'))
    ['error: native Tlon supports editing channel posts and replies, not DM or group-DM messages' ~]
  ?:  =('get_message' action)  [(en:json:html (read:~(. message bowl) args)) ~]
  ?:  =('history_around' action)  [(en:json:html (around:~(. message bowl) args)) ~]
  ?:  =('resolve_citation' action)
    =/  value  (parse:cite (need (rush (required:spec args 'citation' 1.024) stap)))
    ?:  ?=(%group -.value)
      $(args (pairs:enjs:format ~[['action' %s 'get_group'] ['group' %s (group-id flag.value)]]))
    ?>  ?=(%chan -.value)
    ?>  ?=([@ @ *] wer.value)
    =/  root  (slav %ud i.t.wer.value)
    ?:  =(%notes p.nest.value)
      $(args (pairs:enjs:format ~[['action' %s 'get_note'] ['notebook' %s (group-id q.nest.value)] ['note_id' %s (scot %ud root)] ['offset' %s (scot %ud (offset:spec args))]]))
    ?>  ?=(?(%msg %note %curio) i.wer.value)
    =/  target  (channel-id nest.value)
    =/  rest  t.t.wer.value
    =/  fields=(list [@t json])
      :~  ['action' %s 'get_message']  ['channel' %s target]  ['offset' %s (scot %ud (offset:spec args))]  ==
    ?~  rest
      $(args (pairs:enjs:format (snoc fields ['message_id' %s (scot %da root)])))
    ?>  ?=([@ ~] rest)
    $(args (pairs:enjs:format (weld fields `(list [@t json])`~[['parent' %s (scot %da root)] ['message_id' %s (scot %da (slav %ud i.rest))]])))
  ?:  (handles:~(. notes bowl) action)  (run:~(. notes bowl) args wire)
  ?:  =('activity_inbox' action)  [(en:json:html (read:~(. inbox bowl) args)) ~]
  ?:  (handles:~(. club bowl) action)  (run:~(. club bowl) args wire sent)
  ?:  (handles:~(. group-tool bowl) action)
    (run:~(. group-tool bowl) args wire)
  ?:  =('get_channel_permissions' action)
    =/  flag  (flag:spec (required:spec args 'group' 256))
    =/  group  (~(got by groups) flag)
    =/  nest  (nest:spec (required:spec args 'channel' 256))
    =/  channel  (~(got by channels.group) nest)
    =/  perm=perm:v9:d
      .^(perm:v9:d %gx /(scot %p our.bowl)/channels/(scot %da now.bowl)/[kind.nest]/(scot %p ship.nest)/[name.nest]/perm/channel-perm)
    =/  roles  |=(values=(set @tas) [%a (turn ~(tap in values) |=(role=@tas [%s role]))])
    [(en:json:html (pairs:enjs:format ~[['readers' (roles readers.channel)] ['writers' (roles writers.perm)] ['empty_means_all_members' %b &]])) ~]
  ?:  =('list_dms' action)  [(en:json:html (dms:~(. conversation bowl) args)) ~]
  ?:  |(=('history' action) =('search_history' action))
    [(en:json:html (history:~(. conversation bowl) args =('search_history' action))) ~]
  ?:  =('get_profile' action)
    ?>  .^(? %gu /(scot %p our.bowl)/contacts/(scot %da now.bowl)/$)
    =/  who  (ship:spec (string:spec args 'ship' (scot %p our.bowl) 128))
    =/  con=contact:ct
      ?:  =(who our.bowl)
        .^(contact:ct %gx /(scot %p our.bowl)/contacts/(scot %da now.bowl)/v1/self/contact-1)
      =/  directory=directory:ct
        .^(directory:ct %gx /(scot %p our.bowl)/contacts/(scot %da now.bowl)/v1/directory/contact-directory-0)
      =/  leaf  (~(got by directory) who)
      (~(uni by mod.leaf) con.leaf)
    [(en:json:html (pairs:enjs:format ~[['ship' %s (scot %p who)] ['profile' (encode:contact con)]])) ~]
  ?:  =('list_contacts' action)
    ?>  .^(? %gu /(scot %p our.bowl)/contacts/(scot %da now.bowl)/$)
    =/  result  contacts:~(. io bowl)
    ?>  ?=(%a -.result)
    [(en:json:html (directory:spec args p.result)) ~]
  ?:  =('list_groups' action)
    =/  rows  ~(tap by groups)
    =/  items
      %+  turn  rows
      |=  [flag=[@p @tas] group=group:v9:g]
      (pairs:enjs:format ~[['group' %s (group-id flag)] ['title' %s title.meta.group] ['privacy' %s privacy.admissions.group]])
    [(en:json:html (directory:spec args items)) ~]
  ?:  |(=('get_group' action) =('list_channels' action) =('list_members' action))
    =/  flag  (flag:spec (required:spec args 'group' 256))
    =/  group  (~(got by groups) flag)
    ?:  =('list_members' action)
      =/  rows  ~(tap by seats.group)
      =/  items
        %+  turn  rows
        |=  [who=@p seat=seat:v9:g]
        =/  admin  |(=(who -.flag) (gth ~(wyt in (~(int in roles.seat) admins.group)) 0))
        (pairs:enjs:format ~[['ship' %s (scot %p who)] ['roles' %a (turn ~(tap in roles.seat) |=(role=@tas [%s role]))] ['admin' %b admin] ['joined' %s (scot %da joined.seat)]])
      [(en:json:html (directory:spec args items)) ~]
    =/  rows  ~(tap by channels.group)
    =/  items
      %+  turn  (scag 100 (slag (offset:spec args) rows))
      |=  [nest=[@tas @p @tas] channel=channel:v9:g]
      (pairs:enjs:format ~[['channel' %s (channel-id nest)] ['title' %s title.meta.channel]])
    =/  result
      %-  pairs:enjs:format
      :~  ['group' %s (group-id flag)]  ['title' %s title.meta.group]
          ['description' %s description.meta.group]  ['privacy' %s privacy.admissions.group]
          ['member_count' (numb:enjs:format ~(wyt by seats.group))]
          ['channels' %a items]  ['has_more' %b (gth (lent rows) (add (offset:spec args) 100))]
          ['next_offset' ?:((gth (lent rows) (add (offset:spec args) 100)) [%s (scot %ud (add (offset:spec args) 100))] ~)]
      ==
    [(en:json:html result) ~]
  =/  card=card:agent:gall
    ?:  |(=('edit_message' action) =('delete_message' action))
      (change:~(. message bowl) args wire)
    ?:  |(=('accept_dm' action) =('decline_dm' action))
      =/  who  (ship:spec (required:spec args 'ship' 128))
      =/  invited=(set @p)
        .^((set @p) %gx /(scot %p our.bowl)/chat/(scot %da now.bowl)/dm/invited/ships)
      ?>  (~(has in invited) who)
      [%pass wire %agent [our.bowl %chat] %poke %chat-dm-rsvp !>([who =('accept_dm' action)])]
    ?:  |(=('add_channel_writers' action) =('remove_channel_writers' action))
      =/  flag  (flag:spec (required:spec args 'group' 256))
      =/  group  (~(got by groups) flag)
      ?>  (admin:policy our.bowl -.flag group)
      =/  nest  (nest:spec (required:spec args 'channel' 256))
      ?>  (~(has by channels.group) nest)
      =/  role  (slug:spec (required:spec args 'role' 64))
      ?>  (~(has by roles.group) role)
      =/  act=a-channels:v10:d
        ?:  =('add_channel_writers' action)  [%channel nest %add-writers (silt ~[role])]
        [%channel nest %del-writers (silt ~[role])]
      [%pass wire %agent [our.bowl %channels] %poke %channel-action-2 !>(act)]
    ?:  =('update_profile' action)
      (edit-profile:~(. io bowl) wire (decode:contact args))
    ?:  |(=('add_contact' action) =('remove_contact' action))
      =/  who  (ship:spec (required:spec args 'ship' 128))
      =/  act=action:ct  ?:  =('add_contact' action)  [%page who ~]
        [%wipe ~[who]]
      [%pass wire %agent [our.bowl %contacts] %poke %contact-action-1 !>(act)]
    ?:  |(=('react' action) =('unreact' action))
      =/  to  (destination:spec args)
      ?>  (available:~(. conversation bowl) to)
      =/  emoji=(unit @t)  ?:  =('unreact' action)  ~
        `(required:spec args 'emoji' 64)
      (reaction:~(. io bowl) wire to (required:spec args 'message_id' 256) emoji)
    ?:  |(=('send_dm' action) =('send_channel' action))
      =/  to  (destination:spec args)
      ?>  =(=('send_dm' action) ?=(%dm -.to))
      (publish:~(. io bowl) wire to (required:spec args 'text' 16.384) sent)
    =/  flag  (flag:spec (required:spec args 'group' 256))
    ?:  |(=('update_group' action) =('update_channel' action))
      =/  group  (~(got by groups) flag)
      =/  act=a-group:v8:g
        ?:  =('update_group' action)  [%meta (metadata args meta.group)]
        =/  nest  (nest:spec (required:spec args 'channel' 256))
        =/  channel  (~(got by channels.group) nest)
        [%channel nest %edit channel(meta (metadata args meta.channel))]
      [%pass wire %agent [our.bowl %groups] %poke %group-action-4 !>(`a-groups:v8:g`[%group flag act])]
    ?:  =('invite_to_group' action)
      =/  who  (ship:spec (required:spec args 'ship' 128))
      [%pass wire %agent [our.bowl %groups] %poke %group-action-4 !>(`a-groups:v8:g`[%invite flag (silt ~[who]) ~ ~])]
    ?:  =('join_group' action)
      [%pass wire %agent [our.bowl %groups] %poke %group-join !>([flag &])]
    ?:  =('leave_group' action)
      [%pass wire %agent [our.bowl %groups] %poke %group-leave !>(flag)]
    ?>  =('create_channel' action)
    =/  kind  (string:spec args 'kind' 'chat' 16)
    ?>  ?=(?(%chat %diary %heap) kind)
    =/  create=create-channel:v10:d
      :*  kind  (slug:spec (required:spec args 'name' 64))  flag
          (required:spec args 'title' 128)  (string:spec args 'description' '' 1.024)
          ~  ~  ~
      ==
    [%pass wire %agent [our.bowl %channels] %poke %channel-action-2 !>(`a-channels:v10:d`[%create create])]
  [(rap 3 'accepted: local Tlon acknowledged ' action '; remote delivery or completion is not confirmed' ~) `card]
--
