::  Native Notes only: no publishing, hooks, API keys or arbitrary commands.
/-  n=tlon-notes
/+  spec=harness-tlon-tool, hp=harness-tlon-history-page
|_  bowl=bowl:gall
++  handles
  |=  action=@t
  =/  actions=(list @t)
    ~['list_notebooks' 'list_notebook_invites' 'get_notebook' 'list_folders' 'list_notes' 'get_note' 'note_revisions' 'create_notebook' 'rename_notebook' 'delete_notebook' 'invite_to_notebook' 'join_notebook' 'leave_notebook' 'accept_notebook_invite' 'decline_notebook_invite' 'create_folder' 'rename_folder' 'move_folder' 'delete_folder' 'create_note' 'edit_note' 'rename_note' 'move_note' 'delete_note' 'restore_note']
  (lien actions |=(value=@t =(value action)))
++  id
  |=  flag=flag:n
  (rap 3 (scot %p ship.flag) '/' name.flag ~)
++  deletion-confirmed
  |=  args=json
  ^-  ?
  ?.  =('delete_notebook' (required:spec args 'action' 32))  |
  =/  flag  (flag:spec (required:spec args 'notebook' 256))
  =/  rows=(list notebook-summary:n)
    .^((list notebook-summary:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notebooks/noun)
  !(lien rows |=(item=notebook-summary:n =(flag flag.item)))
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
  ?:  =('get_notebook' action)
    =/  item=notebook-detail:n
      .^(notebook-detail:n %gx (weld prefix (weld /notebook (weld suffix /noun))))
    [(en:json:html (notebook-json item)) ~]
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
    ?:  =('create_notebook' action)  [%create-notebook (required:spec args 'title' 128)]
    ?:  =('join_notebook' action)  [%join flag]
    ?:  =('leave_notebook' action)  [%leave flag]
    ?:  =('accept_notebook_invite' action)  [%accept-invite flag]
    ?:  =('decline_notebook_invite' action)  [%decline-invite flag]
    :-  %notebook  :-  flag
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
