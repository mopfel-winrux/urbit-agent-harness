::  Pure group command construction. Role names never imply admin authority.
/-  g=tlon-groups-ver, meta=tlon-meta
/+  spec=harness-tlon-tool
|%
++  admin
  |=  [who=@p host=@p group=group:v9:g]
  ^-  ?
  ?:  =(who host)  &
  =/  seat  (~(get by seats.group) who)
  ?~  seat  |
  !=(~ (~(int in roles.u.seat) admins.group))
++  create
  |=  [args=json our=@p known=groups:v9:g]
  ^-  create-group:v8:g
  =/  name  (slug:spec (required:spec args 'name' 64))
  ::  Native %create replaces a same-named group. Never allow that here.
  ?>  !(~(has by known) [our name])
  =/  privacy  (string:spec args 'privacy' 'secret' 16)
  ?>  ?=(?(%secret %private %public) privacy)
  =/  members=(jug @p @tas)
    ?.  (has:spec args 'owner')  ~
    =/  owner  (ship:spec (required:spec args 'owner' 128))
    (~(put ju *(jug @p @tas)) owner %admin)
  :*  name
      [(required:spec args 'title' 128) (string:spec args 'description' '' 1.024) '' '']
      privacy  [~ ~]  members
  ==
++  manage
  |=  [args=json our=@p flag=[@p @tas] group=group:v9:g]
  ^-  a-group:v8:g
  ?>  (admin our -.flag group)
  =/  action  (required:spec args 'action' 32)
  ?:  =('set_group_privacy' action)
    =/  privacy  (required:spec args 'privacy' 16)
    ?>  ?=(?(%secret %private %public) privacy)
    [%entry %privacy privacy]
  ?:  |(=('create_role' action) =('update_role' action))
    =/  role  (slug:spec (required:spec args 'role' 64))
    =/  old  (~(get by roles.group) role)
    ?:  =('create_role' action)
      ?>  ?=(~ old)
      [%role (silt ~[role]) %add [(required:spec args 'title' 128) (string:spec args 'description' '' 1.024) '' '']]
    ?>  ?=(^ old)
    ?>  |((has:spec args 'title') (has:spec args 'description'))
    =/  title  (string:spec args 'title' title.meta.u.old 128)
    ?>  !=('' title)
    [%role (silt ~[role]) %edit meta.u.old(title title, description (string:spec args 'description' description.meta.u.old 1.024))]
  =/  who  (ship:spec (required:spec args 'ship' 128))
  =/  ships  (silt ~[who])
  ?:  |(=('approve_join_request' action) =('reject_join_request' action))
    ?>  (~(has by requests.admissions.group) who)
    [%entry %ask ships ?:(=('approve_join_request' action) %approve %deny)]
  ?:  =('revoke_group_invite' action)
    ?>  |((~(has by pending.admissions.group) who) (~(has by invited.admissions.group) who))
    [%entry %pending ships %del ~]
  ?>  (~(has by seats.group) who)
  ?:  =('demote_member' action)
    ::  The host cannot be demoted. Remove all admin roles in one command,
    ::  so a self-demotion cannot stop halfway through multiple effects.
    ?>  !=(who -.flag)
    [%seat ships %del-roles admins.group]
  ?:  =('promote_member' action)
    =/  candidates  (~(int in admins.group) ~(key by roles.group))
    ?>  !=(~ candidates)
    =/  role
      ?:  (has:spec args 'role')  (slug:spec (required:spec args 'role' 64))
      ?:  (~(has in candidates) %admin)  %admin
      (snag 0 ~(tap in candidates))
    ?>  (~(has in candidates) role)
    [%seat ships %add-roles (silt ~[role])]
  ?>  |(=('assign_role' action) =('remove_role' action))
  =/  role  (slug:spec (required:spec args 'role' 64))
  ?>  (~(has by roles.group) role)
  :+  %seat  ships
  ?:  =('assign_role' action)  [%add-roles (silt ~[role])]
  [%del-roles (silt ~[role])]
--
