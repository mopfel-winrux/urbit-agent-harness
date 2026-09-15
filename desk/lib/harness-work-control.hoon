::  Bounded confirmation policy shared by all human conversation ingress.
::  The head supplies authenticated provenance and checks current authority.
/-  h=harness, c=harness-work-control, w=harness-workspace, hh=harness-hand
/+  j=harness-workspace-json, workspace=harness-workspace, view=harness-work-view, copy=harness-work-copy
|%
++  capacity  2.048
++  active
  |=  [r=request:c now=@da]
  ^-  ?
  |(=(%running status.r) &(=(%pending status.r) (lth now expires.r)))
++  same-origin
  |=  [a=input-source:h b=input-source:h]
  ^-  ?
  ?.  =(-.a -.b)  |
  ?+  -.a  |
    %acp   &(?=(%acp -.b) =(client.a client.b))
    %poke  &(?=(%poke -.b) =(ship.a ship.b))
    %hand
      ?&  ?=(%hand -.b)
          =(binding.a binding.b)
          =(hand.a hand.b)
          =(address.a address.b)
          =(actor.a actor.b)
      ==
  ==
++  matches
  |=  [r=request:c sid=@t scope=@uv source=input-source:h actor=(unit @p)]
  ^-  ?
  &((same-origin source.r source) =(sid.r sid) =(scope.r scope) =(actor.r actor))
++  permitted
  |=  action=@t
  ^-  ?
  (lien `(list @t)`~['hand-access' 'project-edit' 'member' 'artifact-create' 'artifact-save' 'artifact-archive' 'propose' 'review' 'publish' 'unpublish' 'task-reply'] |=(name=@t =(name action)))
++  reply-key
  |=  args=json
  [(get:j args 'id') (get:j args 'artifact') (number:j args 'revision' 0) (get:j args 'binding') (get:j args 'actor')]
++  reply-request
  |=  [db=state:c args=json]
  ^-  (unit @uv)
  =/  rows  ~(tap by requests.db)
  |-  ^-  (unit @uv)
  ?~  rows  ~
  =/  r  q.i.rows
  ?:  &(&(=('task-reply' action.r) =(%done status.r)) =((reply-key args) (reply-key args.r)))  `p.i.rows
  $(rows t.rows)
++  prepare
  |=  [db=state:c id=@uv r=request:c now=@da]
  ^-  (each state:c @t)
  ?.  (permitted action.r)  [%| 'Unsupported work action.']
  ?.  &(?=(%o -.args.r) (lte (met 3 (en:json:html args.r)) 32.768))
    [%| 'Work arguments must be an object of at most 32768 encoded bytes.']
  ?:  (~(has by requests.db) id)  [%| 'This work request identity is already used.']
  ::  Admission bounds outstanding work, not the lifetime of the ledger.
  ::  Retained receipts remain available for inspection and delivery deduplication.
  =/  outstanding  (skim ~(tap by requests.db) |=([id=@uv r=request:c] (active r now)))
  ?:  (gte (lent outstanding) capacity)  [%| 'Too many active work approvals. Settle pending work before preparing another change.']
  [%& db(requests (~(put by requests.db) id r(expires (add now ~m15), status %pending, result ~)))]
++  confirm
  |=  [db=state:c id=@uv sid=@t scope=@uv source=input-source:h actor=(unit @p) fence=@uvH now=@da]
  ^-  (each state:c @t)
  =/  r  (~(get by requests.db) id)
  ?~  r  [%| 'Work request not found.']
  ?.  (matches u.r sid scope source actor)  [%| 'Confirm from the same conversation and sender that requested this action.']
  ?.  (permitted action.u.r)  [%| 'Unsupported work action.']
  ?.  =(%pending status.u.r)  [%| 'This work request is already settled or submitted; inspect its result instead of repeating it.']
  ?:  (gte now expires.u.r)  [%| 'Work confirmation expired. Prepare the action again.']
  ?.  =(fence fence.u.r)  [%| 'Work changed. Inspect the current record and prepare the action again.']
  [%& db(requests (~(put by requests.db) id u.r(status %running)))]
++  reject
  |=  [db=state:c id=@uv sid=@t scope=@uv source=input-source:h actor=(unit @p)]
  ^-  (each state:c @t)
  =/  r  (~(get by requests.db) id)
  ?~  r  [%| 'Work request not found.']
  ?.  (matches u.r sid scope source actor)  [%| 'Reject from the same conversation and sender that requested this action.']
  ?.  =(%pending status.u.r)  [%| 'Only a pending request can be rejected; rejection cannot undo a submitted operation.']
  [%& db(requests (~(put by requests.db) id u.r(status %rejected)))]
++  complete
  |=  [db=state:c id=@uv result=(each json @t)]
  ^-  state:c
  =/  r  (~(get by requests.db) id)
  ?~  r  db
  ?.  =(%running status.u.r)  db
  db(requests (~(put by requests.db) id u.r(status ?:(?=(%& -.result) %done %failed), result `result)))
++  snapshot
  |=  [db=state:w action=@t args=json]
  ^-  @uvH
  ::  Bind only the operation's read set. The write sequence allocates versions;
  ::  it is not an authority or a dependency on unrelated bookkeeping.
  =/  id  (fall (optional:j args 'id') '')
  ?:  |(=('project-edit' action) =('member' action))
    (sham [action args (~(get by projects.db) id)])
  ?:  =('hand-access' action)  (sham [action args])
  =/  proposal
    ?:  (lien `(list @t)`~['review' 'propose' 'artifact-create'] |=(name=@t =(name action)))
      (~(get by proposals.db) id)
    ~
  =/  art-id
    ?:  |(=('propose' action) =('task-reply' action))  (fall (optional:j args 'artifact') '')
    id
  =?  art-id  &(=('review' action) ?=(^ proposal))  artifact.u.proposal
  =/  art  (~(get by artifacts.db) art-id)
  =/  project
    ?:  =('artifact-create' action)  (optional:j args 'project')
    ?~(art ~ project.u.art)
  =/  group  ?~(project ~ (~(get by projects.db) u.project))
  =/  task  ?:(=('task-reply' action) (~(get by tasks.db) id) ~)
  (sham [action args art proposal group task])
++  fence
  |=  [db=state:w hands=state:hh names=(map @t @uv) owners=(set [binding=@t actor=@t]) action=@t args=json]
  ^-  @uvH
  =/  base  (snapshot db action args)
  ?.  |(=('task-reply' action) =('hand-access' action))  base
  =/  target
    %-  mule  |.
    =/  key  (string:j args 'binding')
    =/  binding  (~(got by bindings.hands) key)
    [binding (~(get by names) sid.binding) ?:(=('hand-access' action) `(~(has in owners) [key (string:j args 'actor')]) ~)]
  (sham [base target])
++  visible
  |=  [db=state:w who=authority:w r=request:c]
  ^-  ?
  ?:  owner.who  &
  =/  id  (fall (optional:j args.r 'id') '')
  ?:  =('project-edit' action.r)  ?=(^ (project-role:workspace db who id))
  ?:  =('artifact-create' action.r)
    =/  project  (optional:j args.r 'project')
    ?~  project  &
    ?=(^ (project-role:workspace db who u.project))
  ?:  =('propose' action.r)
    =/  art  (~(get by artifacts.db) (string:j args.r 'artifact'))
    ?~  art  |
    (can-read:workspace db who u.art)
  |
++  encode
  |=  [id=@uv r=request:c]
  ^-  json
  =/  key  (key:copy (pairs:enjs:format ~[['id' %s (scot %uv id)] ['action' %s action.r] ['args' args.r]]))
  %-  pairs:enjs:format
  :~  ['id' %s (scot %uv id)]
      ['action' %s action.r]
      ['args' args.r]
      ['status' %s status.r]
      ['expires' %s (scot %da expires.r)]
      ['inspect' %s (cat 3 '/work result ' key)]
      ['confirm' %s (cat 3 '/work confirm ' key)]
      ['reject' %s (cat 3 '/work reject ' key)]
      ['result' ?~(result.r ~ ?:(?=(%& -.u.result.r) p.u.result.r [%s p.u.result.r]))]
  ==
++  resolve
  |=  [db=state:c token=@t]
  ^-  @uv
  =/  matches
    (skim ~(tap by requests.db) |=([id=@uv r=request:c] |(=(token (scot %uv id)) =(token (key:copy (encode id r))))))
  ?>  &(?=(^ matches) ?=(~ t.matches))
  p.i.matches
++  previewed
  |=  [log=(list event:h) id=@uv preview=json]
  ^-  ?
  ::  Only head-authored command receipts prove an exact preview was emitted.
  ::  Model text and tool results cannot satisfy this gate.
  ?.  =(`[%s (scot %uv id)] (get:j preview 'id'))  |
  ?.  =(`[%s 'pending'] (get:j preview 'status'))  |
  =/  text  (receipt:view preview)
  %+  lien  (scag 64 log)
  |=  event=event:h
  ?.  &(?=(%command-completed -.event) =('work' name.event))  |
  =(text body.event)
--
