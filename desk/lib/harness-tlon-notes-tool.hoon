::  Native Notes, including explicitly confirmed inert public snapshots.
/-  n=tlon-notes, g=tlon-groups-ver
/+  spec=harness-tlon-tool, hp=harness-tlon-history-page, publish-html=harness-tlon-publish-html, imports=harness-tlon-notes-import, policy=harness-tlon-group-policy
|_  bowl=bowl:gall
++  handles
  |=  action=@t
  =/  actions=(list @t)
    ~['list_notebooks' 'list_notebook_invites' 'get_notebook' 'list_notebook_members' 'list_folders' 'list_notes' 'get_note' 'note_revisions' 'create_notebook' 'rename_notebook' 'delete_notebook' 'set_notebook_visibility' 'invite_to_notebook' 'join_notebook' 'leave_notebook' 'accept_notebook_invite' 'decline_notebook_invite' 'create_folder' 'rename_folder' 'move_folder' 'delete_folder' 'create_note' 'edit_note' 'rename_note' 'move_note' 'delete_note' 'restore_note' 'list_published_notes' 'get_note_publication' 'publish_note' 'unpublish_note' 'plan_notes_import' 'import_notes']
  (lien actions |=(value=@t =(value action)))
++  id
  |=  flag=flag:n
  (rap 3 (scot %p ship.flag) '/' name.flag ~)
++  mutates
  |=  action=@t
  =/  reads=(list @t)
    ~['list_notebooks' 'list_notebook_invites' 'get_notebook' 'list_notebook_members' 'list_folders' 'list_notes' 'get_note' 'note_revisions' 'list_published_notes' 'get_note_publication' 'plan_notes_import']
  &((handles action) !(lien reads |=(item=@t =(item action))))
++  groups
  ^-  groups:v9:g
  .^(groups:v9:g %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v2/groups/noun)
++  readers
  |=  args=json
  ^-  (set @tas)
  =/  value  (need (de:json:html (string:spec args 'readers' '[]' 4.096)))
  ?>  &(?=(%a -.value) (lte (lent p.value) 64))
  =/  rows  (turn p.value |=(item=json (slug:spec (so:dejs:format item))))
  =/  out  (silt rows)
  ?>  =((lent rows) ~(wyt in out))
  out
++  affiliations
  |=  flag=flag:n
  ^-  (list [flag=flag:n channel=channel:v9:g])
  %+  murn  ~(tap by groups)
  |=  [gf=flag:n group=group:v9:g]
  =/  ch  (~(get by channels.group) [%notes flag])
  ?~  ch  ~
  `[gf u.ch]
++  created
  |=  [args=json item=notebook-summary:n]
  =/  linked  (has:spec args 'group')
  =/  verified
    ?.  linked  &
    =/  gf  (flag:spec (required:spec args 'group' 256))
    =/  rows  (affiliations flag.item)
    (lien rows |=(row=[flag=flag:n channel=channel:v9:g] &(=(gf flag.row) =((readers args) readers.channel.row))))
  (pairs:enjs:format ~[['status' %s ?:(verified 'saved' 'uncertain')] ['notebook' %s (id flag.item)] ['root_folder_id' %s (scot %ud +(id.notebook.item))] ['channel' ?:(linked [%s (cat 3 'notes/' (id flag.item))] ~)] ['group_listing_verified' %b &(linked verified)] ['note' %s ?:(verified 'Native Notes creation confirmed.' 'Notebook created; group listing/readers are not yet verified. Inspect get_notebook before writing; do not repeat creation.')]])
++  import-data
  |=  args=json
  ^-  [flag=flag:n folder=@ud tree=(list import-node:n) revision=@t]
  =/  flag=flag:n  (flag:spec (required:spec args 'notebook' 256))
  =/  folder  (number:spec args 'folder_id' 0)
  =/  folders=(list folder:n)
    .^((list folder:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/folders/(scot %p ship.flag)/[name.flag]/noun)
  ?>  (lien folders |=(f=folder:n =(folder id.f)))
  =/  notes=(list note:n)
    .^((list note:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notes/(scot %p ship.flag)/[name.flag]/noun)
  =/  tree  (tree:imports args)
  [flag folder tree (scot %uv (sham [%notes-import flag folder folders notes tree]))]
++  deletion-confirmed
  |=  args=json
  ^-  ?
  =/  action  (required:spec args 'action' 32)
  ?.  |(=('delete_notebook' action) =('delete_channel' action))  |
  =/  flag
    ?:  =('delete_notebook' action)  (flag:spec (required:spec args 'notebook' 256))
    =/  nest  (group-nest:spec (required:spec args 'channel' 256))
    ?>  =(%notes kind.nest)
    +.nest
  =/  rows=(list notebook-summary:n)
    .^((list notebook-summary:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notebooks/noun)
  !(lien rows |=(item=notebook-summary:n =(flag flag.item)))
++  publication-confirmed
  |=  args=json
  ^-  ?
  =/  action  (required:spec args 'action' 32)
  ?>  |(=('publish_note' action) =('unpublish_note' action))
  =/  flag  (flag:spec (required:spec args 'notebook' 256))
  =/  nid  (number:spec args 'note_id' 0)
  =/  rows=(list published-record:n)
    .^((list published-record:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/published/notes-published)
  =/  visible  (lien rows |=(item=published-record:n &(=(flag flag.item) =(nid note-id.item))))
  =(visible =('publish_note' action))
++  notebook-json
  |=  item=notebook-summary:n
  (pairs:enjs:format ~[['notebook' %s (id flag.item)] ['title' %s title.notebook.item] ['root_folder_id' %s (scot %ud +(id.notebook.item))] ['visibility' %s visibility.item]])
++  chunk
  |=  [args=json body=@t]
  ^-  json
  =/  start  (offset:spec args)
  ?>  (lte start (met 3 body))
  =/  rest  (rsh [3 start] body)
  ?>  |(=('' rest) (lth (end [3 1] rest) 128) (gte (end [3 1] rest) 192))
  =/  text  (clip-text:hp rest 2.000)
  =/  end  (add start (met 3 text))
  (pairs:enjs:format ~[['text' %s text] ['total_bytes' (numb:enjs:format (met 3 body))] ['next_offset' ?:((lth end (met 3 body)) [%s (scot %ud end)] ~)]])
++  run
  |=  [args=json wire=wire]
  ^-  [body=@t effect=(unit card:agent:gall)]
  ?>  .^(? %gu /(scot %p our.bowl)/notes/(scot %da now.bowl)/$)
  =/  action  (required:spec args 'action' 32)
  ?:  =('plan_notes_import' action)
    =/  data  (import-data args)
    =/  sizes  (sizes:imports tree.data)
    [(en:json:html (pairs:enjs:format ~[['revision' %s revision.data] ['notes' (numb:enjs:format notes.sizes)] ['folders' (numb:enjs:format folders.sizes)] ['body_bytes' (numb:enjs:format bytes.sizes)] ['confirm' %s (rap 3 (id flag.data) '/folder/' (scot %ud folder.data) ~)] ['note' %s 'Adds new items without overwriting existing items. Confirm this exact tree and destination. Never repeat an uncertain import automatically.']])) ~]
  ?:  =('list_published_notes' action)
    =/  rows=(list published-record:n)
      .^((list published-record:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/published/notes-published)
    =/  items
      %+  turn  rows
      |=  item=published-record:n
      (pairs:enjs:format ~[['notebook' %s (id flag.item)] ['note_id' %s (scot %ud note-id.item)] ['public_path' %s (rap 3 '/notes/pub/' (id flag.item) '/' (scot %ud note-id.item) ~)]])
    [(en:json:html (directory:spec args items)) ~]
  ?:  =('list_notebooks' action)
    =/  rows=(list notebook-summary:n)
      .^((list notebook-summary:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notebooks/noun)
    [(en:json:html (directory:spec args (turn rows notebook-json))) ~]
  ?:  =('list_notebook_invites' action)
    =/  rows=(list invite-record:n)
      .^((list invite-record:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/invites/noun)
    =/  items  (turn rows |=(item=invite-record:n (pairs:enjs:format ~[['notebook' %s (id flag.item)] ['title' %s title.invite-info.item] ['from' %s (scot %p from.invite-info.item)]])))
    [(en:json:html (directory:spec args items)) ~]
  =/  flag=flag:n
    ?:  =('create_notebook' action)  [our.bowl %unused]
    (flag:spec (required:spec args 'notebook' 256))
  =/  prefix=path  /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0
  =/  suffix=path  /(scot %p ship.flag)/[name.flag]
  ?:  =('get_note_publication' action)
    =/  nid  (number:spec args 'note_id' 0)
    ?>  (gth nid 0)
    =/  rows=(list published-record:n)
      .^((list published-record:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/published/notes-published)
    =/  visible  (lien rows |=(item=published-record:n &(=(flag flag.item) =(nid note-id.item))))
    [(en:json:html (pairs:enjs:format ~[['published' %b visible] ['public_path' ?:(visible [%s (rap 3 '/notes/pub/' (id flag) '/' (scot %ud nid) ~)] ~)] ['note' %s 'Public HTML is a snapshot, not live Markdown. Unpublishing cannot erase copies or caches held by other people.']])) ~]
  ?:  =('get_notebook' action)
    =/  item=notebook-detail:n
      .^(notebook-detail:n %gx (weld prefix (weld /notebook (weld suffix /noun))))
    =/  linked  (affiliations flag)
    =/  links  (turn linked |=(row=[flag=flag:n channel=channel:v9:g] (pairs:enjs:format ~[['group' %s (id flag.row)] ['readers' %a (turn ~(tap in readers.channel.row) |=(role=@tas [%s role]))]])))
    =/  base  (notebook-json item)
    ?>  ?=(%o -.base)
    =/  body  (en:json:html [%o (~(put by p.base) 'group_channels' [%a links])])
    ?>  (lte (met 3 body) 23.000)
    [body ~]
  ?:  =('list_notebook_members' action)
    =/  rows=(list member-record:n)
      .^((list member-record:n) %gx (weld prefix (weld /members (weld suffix /noun))))
    =/  items  (turn rows |=(item=member-record:n (pairs:enjs:format ~[['ship' %s (scot %p ship.item)] ['role' %s role.item]])))
    [(en:json:html (directory:spec args items)) ~]
  ?:  =('list_folders' action)
    =/  rows=(list folder:n)
      .^((list folder:n) %gx (weld prefix (weld /folders (weld suffix /noun))))
    =/  items
      %+  turn  rows
      |=  f=folder:n
      (pairs:enjs:format ~[['folder_id' %s (scot %ud id.f)] ['name' %s name.f] ['parent_folder_id' ?~(parent-folder-id.f ~ [%s (scot %ud u.parent-folder-id.f)])]])
    [(en:json:html (directory:spec args items)) ~]
  ?:  =('list_notes' action)
    =/  rows=(list note:n)
      .^((list note:n) %gx (weld prefix (weld /notes (weld suffix /noun))))
    =/  items
      %+  turn  rows
      |=  note=note:n
      (pairs:enjs:format ~[['note_id' %s (scot %ud id.note)] ['title' %s title.note] ['folder_id' %s (scot %ud folder-id.note)] ['revision' %s (scot %ud revision.note)]])
    [(en:json:html (directory:spec args items)) ~]
  ?:  |(=('get_note' action) =('note_revisions' action))
    =/  nid  (number:spec args 'note_id' 0)
    ?>  (gth nid 0)
    ?:  =('note_revisions' action)
      =/  rows=(list note-revision:n)
        .^((list note-revision:n) %gx (weld prefix (weld /note-history (weld suffix /(scot %ud nid)/noun))))
      =/  items
        %+  turn  rows
        |=  revision=note-revision:n
        (pairs:enjs:format ~[['revision' %s (scot %ud rev.revision)] ['title' %s title.revision] ['author' %s (scot %p author.revision)] ['at' %s (scot %da at.revision)]])
      [(en:json:html (directory:spec args items)) ~]
    =/  note=note:n
      .^(note:n %gx (weld prefix (weld /note (weld suffix /(scot %ud nid)/noun))))
    ?:  (has:spec args 'revision')
      =/  rev  (number:spec args 'revision' 0)
      =/  rows=(list note-revision:n)
        .^((list note-revision:n) %gx (weld prefix (weld /note-history (weld suffix /(scot %ud nid)/noun))))
      =/  found  (skim rows |=(r=note-revision:n =(rev rev.r)))
      ?~  found  !!
      [(en:json:html (pairs:enjs:format ~[['note_id' %s (scot %ud nid)] ['revision' %s (scot %ud rev)] ['title' %s title.i.found] ['body' (chunk args body-md.i.found)]])) ~]
    [(en:json:html (pairs:enjs:format ~[['note_id' %s (scot %ud nid)] ['revision' %s (scot %ud revision.note)] ['title' %s title.note] ['folder_id' %s (scot %ud folder-id.note)] ['body' (chunk args body-md.note)]])) ~]
  =/  act=a-notes:n
    ?:  =('create_notebook' action)
      =/  title  (required:spec args 'title' 128)
      ?.  (has:spec args 'group')
        ?>  !(has:spec args 'readers')
        [%create-notebook title]
      =/  gf=flag:n  (flag:spec (required:spec args 'group' 256))
      =/  group  (~(got by groups) gf)
      ?>  (admin:policy our.bowl ship.gf group)
      =/  allowed  (readers args)
      ?>  (levy ~(tap in allowed) |=(role=@tas (~(has by roles.group) role)))
      [%create-group-notebook title gf allowed]
    ?:  =('join_notebook' action)  [%join flag]
    ?:  =('leave_notebook' action)  [%leave flag]
    ?:  =('accept_notebook_invite' action)  [%accept-invite flag]
    ?:  =('decline_notebook_invite' action)  [%decline-invite flag]
    :-  %notebook  :-  flag
    ?:  =('import_notes' action)
      =/  data  (import-data args)
      ?>  =(revision.data (required:spec args 'revision' 128))
      ?>  =((rap 3 (id flag) '/folder/' (scot %ud folder.data) ~) (required:spec args 'confirm' 384))
      [%batch-import-tree folder.data tree.data]
    ?:  =('set_notebook_visibility' action)
      ?>  =((id flag) (required:spec args 'confirm' 256))
      ?>  =(~ (affiliations flag))
      =/  visibility  (required:spec args 'visibility' 16)
      ?>  ?=(?(%public %private) visibility)
      [%visibility visibility]
    ?:  =('rename_notebook' action)  [%rename (required:spec args 'title' 128)]
    ?:  =('delete_notebook' action)
      ?>  =((id flag) (required:spec args 'confirm' 256))
      [%delete ~]
    ?:  =('invite_to_notebook' action)  [%invite (ship:spec (required:spec args 'ship' 128))]
    ?:  =('create_folder' action)  [%create-folder (number:spec args 'folder_id' 0) (required:spec args 'title' 128)]
    ?:  =('create_note' action)  [%create-note (number:spec args 'folder_id' 0) (required:spec args 'title' 128) (string:spec args 'text' '' 16.384)]
    ?:  |(=('rename_folder' action) =('move_folder' action) =('delete_folder' action))
      =/  fid  (number:spec args 'folder_id' 0)
      ?>  (gth fid 0)
      :-  %folder  :-  fid
      ?:  =('rename_folder' action)  [%rename (required:spec args 'title' 128)]
      ?:  =('move_folder' action)  [%move (number:spec args 'new_parent' 0)]
      ?>  =((scot %ud fid) (required:spec args 'confirm' 256))
      [%delete =('true' (string:spec args 'recursive' 'false' 5))]
    =/  nid  (number:spec args 'note_id' 0)
    ?>  (gth nid 0)
    :-  %note  :-  nid
    ?:  |(=('publish_note' action) =('unpublish_note' action))
      =/  target  (rap 3 (id flag) '/note/' (scot %ud nid) ~)
      ?>  =(target (required:spec args 'confirm' 384))
      ?:  =('unpublish_note' action)  [%unpublish ~]
      =/  note=note:n
        .^(note:n %gx (weld prefix (weld /note (weld suffix /(scot %ud nid)/noun))))
      ?>  (has:spec args 'revision')
      ?>  =((number:spec args 'revision' 0) revision.note)
      =/  html=(unit @t)  ?:((has:spec args 'html') `(required:spec args 'html' 16.384) ~)
      [%publish (page:publish-html title.note body-md.note html)]
    ?:  =('rename_note' action)  [%rename (required:spec args 'title' 128)]
    ?:  =('move_note' action)  [%move (number:spec args 'folder_id' 0)]
    ?:  =('delete_note' action)
      ?>  =((scot %ud nid) (required:spec args 'confirm' 256))
      [%delete ~]
    ?>  (has:spec args 'revision')
    ?:  =('restore_note' action)  [%restore (number:spec args 'revision' 0)]
    ?>  =('edit_note' action)
    ?>  (has:spec args 'text')
    [%update (string:spec args 'text' '' 16.384) (number:spec args 'revision' 0)]
  ?>  ?=([@ @ ~] wire)
  =/  rid=@uv  (slav %uv i.t.wire)
  ['pending: awaiting native Notes result' `[%pass wire %agent [our.bowl %notes] %poke %notes-action-1 !>(`action:v1:n`[rid act])]]
--
