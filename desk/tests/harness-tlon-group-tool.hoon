/-  g=tlon-groups-ver
/+  *test, policy=harness-tlon-group-policy
|%
++  fixture
  ^-  group:v9:g
  =/  group  *group:v9:g
  =.  roles.group
    (my ~[[%admin `role:v9:g`[['Admin' '' '' ''] ~]] [%steward `role:v9:g`[['Steward' '' '' ''] ~]] [%editors `role:v9:g`[['Editors' 'Keep' 'image' 'cover'] ~]]])
  =.  admins.group  (silt `(list @tas)`~[%admin %steward])
  group(seats (my ~[[~nec `seat:v9:g`[(silt `(list @tas)`~[%editors %admin %steward]) ~2026.9.9]]]))
++  test-role-name-is-not-authority
  =/  group  fixture
  =.  admins.group  ~
  (expect !>(&(!(admin:policy ~nec ~lux group) (admin:policy ~lux ~lux group))))
++  test-create-seeds-owner-admin-in-one-command
  =/  args  (pairs:enjs:format ~[['name' %s 'test'] ['title' %s 'Test'] ['owner' %s '~nec']])
  =/  create  (create:policy args ~lux ~)
  (expect !>(&(=(%secret privacy.create) =(1 ~(wyt by members.create)) =(`(silt ~[%admin]) (~(get by members.create) ~nec)))))
++  test-create-refuses-existing-name
  =/  args  (pairs:enjs:format ~[['name' %s 'test'] ['title' %s 'Replacement']])
  =/  known  (my ~[[[~lux %test] fixture]])
  (expect-eq !>(~) !>((mole |.((create:policy args ~lux known)))))
++  test-promote-requires-an-actually-privileged-role
  =/  bad  (pairs:enjs:format ~[['action' %s 'promote_member'] ['ship' %s '~nec'] ['role' %s 'editors']])
  =/  good  (pairs:enjs:format ~[['action' %s 'promote_member'] ['ship' %s '~nec'] ['role' %s 'steward']])
  =/  expected=a-group:v8:g  [%seat (silt ~[~nec]) %add-roles (silt ~[%steward])]
  (expect !>(&(=(~ (mole |.((manage:policy bad ~lux [~lux %test] fixture)))) =(expected (manage:policy good ~lux [~lux %test] fixture)))))
++  test-demote-removes-all-admin-roles-not-ordinary-roles
  =/  args  (pairs:enjs:format ~[['action' %s 'demote_member'] ['ship' %s '~nec']])
  =/  expected=a-group:v8:g  [%seat (silt ~[~nec]) %del-roles (silt `(list @tas)`~[%admin %steward])]
  (expect-eq !>(expected) !>((manage:policy args ~lux [~lux %test] fixture)))
++  test-refuses-demoting-host
  =/  args  (pairs:enjs:format ~[['action' %s 'demote_member'] ['ship' %s '~nec']])
  (expect-eq !>(~) !>((mole |.((manage:policy args ~nec [~nec %test] fixture)))))
++  test-native-nonadmin-cannot-change-privacy
  =/  args  (pairs:enjs:format ~[['action' %s 'set_group_privacy'] ['privacy' %s 'public']])
  =/  group  fixture
  =.  admins.group  ~
  (expect-eq !>(~) !>((mole |.((manage:policy args ~nec [~lux %test] group)))))
++  test-update-role-preserves-unedited-metadata
  =/  args  (pairs:enjs:format ~[['action' %s 'update_role'] ['role' %s 'editors'] ['title' %s 'Writers']])
  =/  expected=a-group:v8:g  [%role (silt ~[%editors]) %edit ['Writers' 'Keep' 'image' 'cover']]
  (expect-eq !>(expected) !>((manage:policy args ~lux [~lux %test] fixture)))
++  test-rejects-unknown-member-and-join-request
  =/  role  (pairs:enjs:format ~[['action' %s 'assign_role'] ['role' %s 'editors'] ['ship' %s '~bud']])
  =/  join  (pairs:enjs:format ~[['action' %s 'approve_join_request'] ['ship' %s '~bud']])
  =/  okay
    ?&  =(~ (mole |.((manage:policy role ~lux [~lux %test] fixture))))
        =(~ (mole |.((manage:policy join ~lux [~lux %test] fixture))))
    ==
  (expect !>(okay))
--
