::  Ship-wide Tlon operations. The adapter owns live grants and receipts;
::  this core reads public native state and builds one effect per invocation.
/-  t=harness-tlon, g=tlon-groups-ver, d=tlon-channels-ver
/+  spec=harness-tlon-tool, io=harness-tlon-io
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
++  run
  |=  [args=json wire=wire sent=@da]
  ^-  [body=@t effect=(unit card:agent:gall)]
  =/  action  (required:spec args 'action' 32)
  ?:  =('help' action)  [help:spec ~]
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
  ?:  |(=('get_group' action) =('list_channels' action))
    =/  flag  (flag:spec (required:spec args 'group' 256))
    =/  group  (~(got by groups) flag)
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
    ?:  |(=('send_dm' action) =('send_channel' action))
      =/  to=destination:t
        ?:  =('send_dm' action)
          [%dm (ship:spec (required:spec args 'ship' 128)) ~]
        [%channel (nest:spec (required:spec args 'channel' 256)) ~]
      (publish:~(. io bowl) wire to (required:spec args 'text' 16.384) sent)
    ?:  =('create_group' action)
      =/  privacy  (string:spec args 'privacy' 'secret' 16)
      ?>  ?=(?(%secret %private %public) privacy)
      =/  create=create-group:v8:g
        :*  (slug:spec (required:spec args 'name' 64))
            [(required:spec args 'title' 128) (string:spec args 'description' '' 1.024) '' '']
            privacy  [~ ~]  ~
        ==
      [%pass wire %agent [our.bowl %groups] %poke %group-command !>(`c-groups:v8:g`[%create create])]
    =/  flag  (flag:spec (required:spec args 'group' 256))
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
