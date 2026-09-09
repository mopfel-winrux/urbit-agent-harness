::  Ship-wide Tlon operations. The adapter owns live grants and receipts;
::  this core reads public native state and builds one effect per invocation.
/-  t=harness-tlon, g=tlon-groups-ver, d=tlon-channels-ver, ct=tlon-contacts, meta=tlon-meta
/+  spec=harness-tlon-tool, io=harness-tlon-io, conversation=harness-tlon-conversation-tool, contact=harness-tlon-contact-tool, group-tool=harness-tlon-group-tool
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
  ?:  (handles:~(. group-tool bowl) action)
    (run:~(. group-tool bowl) args wire)
  ?:  =('list_dms' action)  [(en:json:html dms:~(. conversation bowl)) ~]
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
    [(en:json:html (pairs:enjs:format ~[['items' %a (scag 100 p.result)] ['has_more' %b (gth (lent p.result) 100)]])) ~]
  ?:  =('list_groups' action)
    =/  rows  ~(tap by groups)
    =/  items
      %+  turn  (scag 100 rows)
      |=  [flag=[@p @tas] group=group:v9:g]
      (pairs:enjs:format ~[['group' %s (group-id flag)] ['title' %s title.meta.group] ['privacy' %s privacy.admissions.group]])
    [(en:json:html (pairs:enjs:format ~[['items' %a items] ['has_more' %b (gth (lent rows) 100)]])) ~]
  ?:  |(=('get_group' action) =('list_channels' action) =('list_members' action))
    =/  flag  (flag:spec (required:spec args 'group' 256))
    =/  group  (~(got by groups) flag)
    ?:  =('list_members' action)
      =/  rows  ~(tap by seats.group)
      =/  items
        %+  turn  (scag 100 rows)
        |=  [who=@p seat=seat:v9:g]
        =/  admin  |(=(who -.flag) (gth ~(wyt in (~(int in roles.seat) admins.group)) 0))
        (pairs:enjs:format ~[['ship' %s (scot %p who)] ['roles' %a (turn ~(tap in roles.seat) |=(role=@tas [%s role]))] ['admin' %b admin] ['joined' %s (scot %da joined.seat)]])
      [(en:json:html (pairs:enjs:format ~[['items' %a items] ['has_more' %b (gth (lent rows) 100)]])) ~]
    =/  rows  ~(tap by channels.group)
    =/  items
      %+  turn  (scag 100 rows)
      |=  [nest=[@tas @p @tas] channel=channel:v9:g]
      (pairs:enjs:format ~[['channel' %s (channel-id nest)] ['title' %s title.meta.channel]])
    =/  result
      %-  pairs:enjs:format
      :~  ['group' %s (group-id flag)]  ['title' %s title.meta.group]
          ['description' %s description.meta.group]  ['privacy' %s privacy.admissions.group]
          ['member_count' (numb:enjs:format ~(wyt by seats.group))]
          ['channels' %a items]  ['has_more' %b (gth (lent rows) 100)]
      ==
    [(en:json:html result) ~]
  =/  card=card:agent:gall
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
