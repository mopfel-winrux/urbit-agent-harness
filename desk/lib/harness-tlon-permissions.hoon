::  One revision-checked conversation policy for native and hosted settings.
/-  t=harness-tlon, g=tlon-groups-ver, c=tlon-channels
/+  p=harness-tlon-policy, j=harness-workspace-json
|%
++  revision
  |=  [policy=policy:t epoch=@ud]
  (scot %uv (sham [policy epoch]))
++  view
  |=  [policy=policy:t epoch=@ud]
  ^-  json
  (pairs:enjs:format ~[['revision' %s (revision policy epoch)] ['enabled' %b enabled.policy] ['owner' ?~(owner.policy ~ [%s (scot %p u.owner.policy)])] ['allowedShips' %a (turn ~(tap in (~(uni in allowed.policy) ~(key by trusted.policy))) |=(who=@p [%s (scot %p who)]))] ['response' %s response.policy] ['channels' (channels-json:p channels.policy)]])
++  apply
  |=  [policy=policy:t epoch=@ud args=json]
  ^-  (each policy:t [status=@ud error=@t])
  ?.  ?=(%o -.args)  [%| 400 'Expected permission settings.']
  ?.  (levy ~(tap by p.args) |=([key=@t value=json] (~(has in (silt ~['revision' 'enabled' 'allowedShips' 'response' 'channels'])) key)))
    [%| 400 'Unknown permission setting.']
  ?.  =(`[%s (revision policy epoch)] (get:j args 'revision'))
    [%| 409 'Permissions changed. Reload before saving.']
  =/  parsed
    %-  mole  |.
    =,  dejs:format
    =/  value=[enabled=? ships=(list @p) response=@t channels=(map nest:c channel-rule:t)]
      ((ot ~[['enabled' bo] ['allowedShips' (ar (se %p))] ['response' so] ['channels' json-channels:p]]) args)
    ?>  (lte (lent ships.value) 64)
    =/  ships  (silt ships.value)
    ?>  =(~(wyt in ships) (lent ships.value))
    ?>  ?=(?(%off %mentions %all) response.value)
    ::  Retain explicit resource grants; adding a ship grants no peer access.
    =/  trusted  (my (skim ~(tap by trusted.policy) |=([who=@p tools=*] (~(has in ships) who))))
    policy(enabled enabled.value, allowed (~(dif in ships) ~(key by trusted)), trusted trusted, response response.value, channels channels.value)
  ?~  parsed  [%| 400 'Use unique ship names and valid channel response rules.']
  [%& u.parsed]
++  envelope
  |=  [status=@ud body=json]
  (pairs:enjs:format ~[['status' (numb:enjs:format status)] ['body' body]])
++  error
  |=  [status=@ud message=@t]
  (envelope status (pairs:enjs:format ~[['error' %s message]]))
++  directory
  |_  bowl=bowl:gall
  ++  groups
    ^-  groups:v9:g
    .^(groups:v9:g %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v2/groups/noun)
  ++  channels
    ^-  json
    =/  rows=(list json)
      %-  zing
      %+  turn  ~(tap by groups)
      |=  [flag=flag:g group=group:v9:g]
      ?~  seat=(~(get by seats.group) our.bowl)  ~
      ?:  =(0 joined.u.seat)  ~
      %+  murn  ~(tap in active-channels.group)
      |=  nest=nest:g
      ?.  ?=(?(%chat %diary %heap) p.nest)  ~
      =/  channel  (~(get by channels.group) nest)
      `(pairs:enjs:format ~[['channel' %s (address:p [%channel nest ~])] ['title' %s ?~(channel q.q.nest title.meta.u.channel)] ['group' %s title.meta.group]])
    [%a rows]
  ++  can-read
    |=  [who=@p nest=nest:g]
    ^-  ?
    =/  allowed
      %+  lien  ~(tap by groups)
      |=  [flag=flag:g group=group:v9:g]
      ?.  (~(has by channels.group) nest)  |
      ?~  seat=(~(get by seats.group) who)  |
      ?:  =(0 joined.u.seat)  |
      =/  native=$-([@p nest:g] ?)
        .^($-([@p nest:g] ?) %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v2/groups/(scot %p p.flag)/[q.flag]/channels/can-read/noun)
      (native who nest)
    allowed
  --
--
