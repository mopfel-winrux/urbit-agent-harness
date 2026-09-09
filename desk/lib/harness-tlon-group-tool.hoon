::  Group administration and invitation workflows: one durable native effect.
/-  g=tlon-groups-ver
/+  spec=harness-tlon-tool, policy=harness-tlon-group-policy
|_  bowl=bowl:gall
++  handles
  |=  action=@t
  =/  actions=(list @t)
    ~['create_group' 'list_roles' 'create_role' 'update_role' 'assign_role' 'remove_role' 'promote_member' 'demote_member' 'set_group_privacy' 'list_group_requests' 'approve_join_request' 'reject_join_request' 'revoke_group_invite' 'list_group_invites' 'request_group_invite' 'accept_group_invite' 'decline_group_invite' 'cancel_group_join']
  (lien actions |=(value=@t =(value action)))
++  groups
  ^-  groups:v9:g
  .^(groups:v9:g %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v2/groups/noun)
++  foreigns
  ^-  foreigns:v8:g
  .^(foreigns:v8:g %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v1/foreigns/noun)
++  group-id
  |=  flag=[@p @tas]
  (rap 3 (scot %p -.flag) '/' +.flag ~)
++  invited
  |=  foreign=foreign:v8:g
  (lien invites.foreign |=(invite=invite:v8:g valid.invite))
++  run
  |=  [args=json wire=wire]
  ^-  [body=@t effect=(unit card:agent:gall)]
  ?>  .^(? %gu /(scot %p our.bowl)/groups/(scot %da now.bowl)/$)
  =/  action  (required:spec args 'action' 32)
  ?>  (handles action)
  ?:  =('list_group_invites' action)
    =/  rows  ~(tap by foreigns)
    =/  items
      %+  turn  (scag 100 rows)
      |=  [flag=[@p @tas] foreign=foreign:v8:g]
      (pairs:enjs:format ~[['group' %s (group-id flag)] ['title' %s ?~(preview.foreign '' title.meta.u.preview.foreign)] ['has_invite' %b (invited foreign)] ['progress' ?~(progress.foreign ~ [%s u.progress.foreign])]])
    [(en:json:html (pairs:enjs:format ~[['items' %a items] ['has_more' %b (gth (lent rows) 100)]])) ~]
  ?:  |(=('list_roles' action) =('list_group_requests' action))
    =/  flag  (flag:spec (required:spec args 'group' 256))
    =/  group  (~(got by groups) flag)
    ?:  =('list_roles' action)
      =/  rows  ~(tap by roles.group)
      =/  items
        %+  turn  (scag 100 rows)
        |=  [id=@tas role=role:v9:g]
        (pairs:enjs:format ~[['role' %s id] ['title' %s title.meta.role] ['description' %s description.meta.role] ['admin' %b (~(has in admins.group) id)]])
      [(en:json:html (pairs:enjs:format ~[['items' %a items] ['has_more' %b (gth (lent rows) 100)]])) ~]
    ?>  (admin:policy our.bowl -.flag group)
    ::  Never expose invitation tokens, referral links or request bodies.
    =/  pending  ~(tap in ~(key by pending.admissions.group))
    =/  requests  ~(tap in ~(key by requests.admissions.group))
    =/  invites  ~(tap in ~(key by invited.admissions.group))
    =/  ships  |=  rows=(list @p)
      [%a (turn (scag 100 rows) |=(who=@p [%s (scot %p who)]))]
    =/  result
      (pairs:enjs:format ~[['pending' (ships pending)] ['requests' (ships requests)] ['invited' (ships invites)] ['has_more' %b |((gth (lent pending) 100) (gth (lent requests) 100) (gth (lent invites) 100))]])
    [(en:json:html result) ~]
  =/  card=card:agent:gall
    ?:  =('create_group' action)
      [%pass wire %agent [our.bowl %groups] %poke %group-command !>(`c-groups:v8:g`[%create (create:policy args our.bowl groups)])]
    =/  flag  (flag:spec (required:spec args 'group' 256))
    ?:  =('request_group_invite' action)
      ?>  !(~(has by groups) flag)
      [%pass wire %agent [our.bowl %groups] %poke %group-knock !>(flag)]
    ?:  |(=('accept_group_invite' action) =('decline_group_invite' action) =('cancel_group_join' action))
      ?>  !(~(has by groups) flag)
      =/  foreign  (~(got by foreigns) flag)
      ?:  =('cancel_group_join' action)
        ?>  ?=(^ progress.foreign)
        [%pass wire %agent [our.bowl %groups] %poke %group-cancel !>(flag)]
      ?>  (invited foreign)
      ?:  =('accept_group_invite' action)
        [%pass wire %agent [our.bowl %groups] %poke %group-join !>([flag &])]
      [%pass wire %agent [our.bowl %groups] %poke %invite-decline !>(flag)]
    =/  group  (~(got by groups) flag)
    [%pass wire %agent [our.bowl %groups] %poke %group-action-4 !>(`a-groups:v8:g`[%group flag (manage:policy args our.bowl flag group)])]
  [(rap 3 'accepted: local Tlon acknowledged ' action '; verify with list_roles/list_members/list_group_requests/list_group_invites; remote completion is not confirmed' ~) `card]
--
