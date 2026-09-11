::  Pure work-record transitions. No provider, Gall, timer, delivery or session
::  store dependency. The head supplies live authority and persists the result.
/-  w=harness-workspace
|%
++  project-role
  |=  [db=state:w who=authority:w id=id:w]
  ^-  (unit role:w)
  =/  project  (~(get by projects.db) id)
  ?~  project  ~
  ?:  archived.u.project  ~
  ?:  owner.who  `%contributor
  ?:  =(0 access.who)  ~
  (~(get by members.u.project) access.who)
++  can-read
  |=  [db=state:w who=authority:w art=artifact:w]
  ^-  ?
  ?:  owner.who  &
  ?:  archived.art  |
  ?~  project.art  &(!=(0 access.who) =(owner.art access.who))
  ?=(^ (project-role db who u.project.art))
++  can-propose
  |=  [db=state:w who=authority:w art=artifact:w]
  ^-  ?
  ?:  archived.art  |
  ?:  owner.who  &
  ?~  project.art  &(!=(0 access.who) =(owner.art access.who))
  =(`%contributor (project-role db who u.project.art))
++  content-size
  |=  value=content:w
  ^-  @ud
  %+  add  (add (met 3 title.value) (met 3 body.value))
  (roll sources.value |=([s=source:w n=@ud] (add n (add (met 3 label.s) (met 3 url.s)))))
++  valid-content
  |=  value=content:w
  ^-  ?
  ?&  (gth (met 3 title.value) 0)
      (lte (met 3 title.value) 256)
      (lte (met 3 body.value) 262.144)
      (lte (lent sources.value) 16)
      (levy sources.value |=(s=source:w &((lte (met 3 label.s) 256) (lte (met 3 url.s) 2.048))))
  ==
++  can-add-content
  |=  [db=state:w value=content:w]
  &((valid-content value) (lte (add bytes.db (content-size value)) 67.108.864))
++  valid-id
  |=  id=@t
  ^-  ?
  ?&  (gth (met 3 id) 0)
      (lte (met 3 id) 96)
      (levy (trip id) |=(c=@t |(&((gte c 'a') (lte c 'z')) &((gte c '0') (lte c '9')) =(c '-'))))
  ==
++  valid-slug
  |=  slug=@t
  ^-  ?
  ?&  (valid-id slug)
      (lte (met 3 slug) 80)
      !=('-' (end [3 1] slug))
      !=('-' (rsh [3 (dec (met 3 slug))] slug))
  ==
++  record
  |=  [db=state:w who=authority:w action=@t target=id:w now=@da]
  ^-  state:w
  ::  Keep recent operational evidence bounded without ever exhausting the
  ::  ability to revoke access or unpublish. Accepted revisions stay immutable.
  db(writes +(writes.db), history [[now by.who action target] (scag 2.047 history.db)])
++  revise
  |=  [art=artifact:w value=content:w who=authority:w now=@da]
  ^-  artifact:w
  %=  art
    head  +(head.art)
    label  title.value
    revisions  (~(put by revisions.art) +(head.art) [now by.who value])
  ==
++  apply
  |=  [db=state:w who=authority:w act=action:w now=@da]
  ^-  (each state:w @t)
  ?.  (valid-id id.act)  [%| 'Invalid work record ID']
  =/  done
    |=  next=state:w
    ^-  (each state:w @t)
    [%& (record next who (scot %tas -.act) id.act now)]
  ?:  ?=(%project-create -.act)
    ?.  owner.who  [%| 'Only the owner can create projects']
    ?:  (~(has by projects.db) id.act)  [%| 'Project ID already exists']
    ?.  ?&((gth (met 3 title.act) 0) (lte (met 3 title.act) 256) (lte (met 3 description.act) 4.096) (lth ~(wyt by projects.db) 128))
      [%| 'Project title, description or capacity limit exceeded']
    (done db(projects (~(put by projects.db) id.act [title.act description.act 1 ~ |])))
  ?:  ?=(?(%project-edit %member) -.act)
    ?.  owner.who  [%| 'Only the owner can change project access or settings']
    =/  project  (~(get by projects.db) id.act)
    ?~  project  [%| 'Project not found']
    ?.  =(version.act version.u.project)  [%| 'Project changed; reload before saving']
    =/  next=project:w
      ?:  ?=(%member -.act)
        %=  u.project
          version  +(version.u.project)
          members  ?~(role.act (~(del by members.u.project) scope.act) (~(put by members.u.project) scope.act u.role.act))
        ==
      u.project(title title.act, description description.act, archived archived.act, version +(version.u.project))
    ?.  ?&((gth (met 3 title.next) 0) (lte (met 3 title.next) 256) (lte (met 3 description.next) 4.096) (lte ~(wyt by members.next) 64))
      [%| 'Project title, description or membership limit exceeded']
    (done db(projects (~(put by projects.db) id.act next)))
  ?:  ?=(%artifact-create -.act)
    ?:  (~(has by artifacts.db) id.act)  [%| 'Artifact ID already exists']
    ?.  (lth ~(wyt by artifacts.db) 512)  [%| 'Artifact capacity reached']
    ?.  (can-add-content db value.act)  [%| 'Document or retained-content capacity limit exceeded']
    ?.  ?~(project.act |(owner.who !=(0 access.who)) =(`%contributor (project-role db who u.project.act)))
      [%| 'No contributor access to this project']
    =/  art=artifact:w  [access.who project.act title.value.act 0 ~ ~ 0 |]
    =.  db  db(bytes (add bytes.db (content-size value.act)))
    ?:  owner.who
      (done db(artifacts (~(put by artifacts.db) id.act (revise art value.act who now))))
    ::  New agent-authored documents start as a reviewable proposal, not as
    ::  already accepted project knowledge. The artifact itself has identity.
    ?:  (~(has by proposals.db) id.act)  [%| 'Proposal ID already exists']
    ?.  (lth ~(wyt by proposals.db) 2.048)  [%| 'Proposal capacity reached']
    =/  proposal=proposal:w  [id.act 0 by.who access.who now value.act 'New document' %pending ~ '' ~]
    (done db(artifacts (~(put by artifacts.db) id.act art), proposals (~(put by proposals.db) id.act proposal)))
  ?:  ?=(%propose -.act)
    ?:  (~(has by proposals.db) id.act)  [%| 'Proposal ID already exists']
    =/  art  (~(get by artifacts.db) artifact.act)
    ?~  art  [%| 'Artifact not found or unavailable']
    ?.  (can-propose db who u.art)  [%| 'No contributor access to this artifact']
    ?.  =(base.act head.u.art)  [%| 'Artifact changed; read the current revision before proposing']
    ?.  &((can-add-content db value.act) (lte (met 3 reason.act) 4.096))  [%| 'Proposal content limit exceeded']
    ?.  (lth ~(wyt by proposals.db) 2.048)  [%| 'Proposal capacity reached']
    =/  next=proposal:w  [artifact.act base.act by.who access.who now value.act reason.act %pending ~ '' ~]
    (done db(proposals (~(put by proposals.db) id.act next), bytes (add bytes.db (content-size value.act))))
  ?:  ?=(%review -.act)
    ?.  owner.who  [%| 'Only the owner can accept or reject a proposal']
    =/  proposal  (~(get by proposals.db) id.act)
    ?~  proposal  [%| 'Proposal not found']
    ?.  =(%pending status.u.proposal)  [%| 'Proposal was already reviewed']
    ?.  (lte (met 3 reason.act) 4.096)  [%| 'Review note exceeds limit']
    =/  next  u.proposal(status ?:(accept.act %accepted %rejected), decided `now, decision reason.act)
    ?.  accept.act  (done db(proposals (~(put by proposals.db) id.act next)))
    =/  art  (~(get by artifacts.db) artifact.u.proposal)
    ?~  art  [%| 'Artifact no longer exists']
    ?.  =(base.u.proposal head.u.art)  [%| 'Proposal is stale; it cannot overwrite a newer revision']
    =/  author=authority:w  [=(0 access.u.proposal) by.u.proposal access.u.proposal]
    ?.  (can-propose db author u.art)  [%| 'Proposal author no longer has contributor access']
    ?.  (lth head.u.art 256)  [%| 'Artifact revision capacity reached']
    =/  revised  (revise u.art value.u.proposal author now)
    ::  Proposal and revision share the same immutable content noun.
    (done db(artifacts (~(put by artifacts.db) artifact.u.proposal revised), proposals (~(put by proposals.db) id.act next(revision `head.revised))))
  ?:  ?=(?(%artifact-save %artifact-archive %publish %unpublish) -.act)
    ?.  owner.who  [%| 'Only the owner can save accepted revisions or change publication']
    =/  art  (~(get by artifacts.db) id.act)
    ?~  art  [%| 'Artifact not found']
    ?:  ?=(%artifact-save -.act)
      ?.  =(base.act head.u.art)  [%| 'Artifact changed; your draft was not overwritten. Reload the current revision']
      ?:  archived.u.art  [%| 'Restore the artifact before editing']
      ?.  =(project.act project.u.art)  [%| 'Project scope is fixed; copy the selected revision into a new artifact to share it']
      ?.  ?~(project.act & ?=(^ (project-role db who u.project.act)))  [%| 'Project not found or archived']
      ?.  &((can-add-content db value.act) (lth head.u.art 256))  [%| 'Document, revision or retained-content capacity limit exceeded']
      =/  revised  (revise u.art(project project.act) value.act who now)
      (done db(artifacts (~(put by artifacts.db) id.act revised), bytes (add bytes.db (content-size value.act))))
    ?:  ?=(%artifact-archive -.act)
      ?.  =(base.act head.u.art)  [%| 'Artifact changed; reload before archiving']
      ?:  ?=(^ publication.u.art)  [%| 'Unpublish the artifact before archiving']
      (done db(artifacts (~(put by artifacts.db) id.act u.art(archived archived.act))))
    =/  expected  ?:(?=(%publish -.act) exposure.act exposure.act)
    ?.  =(expected exposure.u.art)  [%| 'Publication changed; inspect its current state']
    =/  slugs  ?~(publication.u.art slugs.db (~(del by slugs.db) slug.u.publication.u.art))
    ?:  ?=(%unpublish -.act)
      (done db(slugs slugs, artifacts (~(put by artifacts.db) id.act u.art(publication ~, exposure +(exposure.u.art)))))
    ?:  archived.u.art  [%| 'Restore the artifact before publishing']
    ?.  =(head.act head.u.art)  [%| 'Artifact changed; preview the publication again']
    ?.  (~(has by revisions.u.art) revision.act)  [%| 'Only accepted revisions can be published']
    ?.  (valid-slug slug.act)  [%| 'Public slug must use lowercase letters, digits and interior hyphens, up to 80 characters']
    ?:  (~(has by slugs) slug.act)  [%| 'This public URL belongs to another artifact']
    ?.  (lte (met 3 html.act) 2.097.152)  [%| 'Rendered page exceeds publication limit']
    =/  next  u.art(publication `[revision.act slug.act html.act now], exposure +(exposure.u.art))
    (done db(slugs (~(put by slugs) slug.act id.act), artifacts (~(put by artifacts.db) id.act next)))
  ?:  ?=(%task-create -.act)
    ?.  =(`%contributor (project-role db who project.act))  [%| 'No contributor access to this project']
    ?:  (~(has by tasks.db) id.act)  [%| 'Task ID already exists']
    ?.  ?&((gth (met 3 title.act) 0) (lte (met 3 title.act) 256) (lte (met 3 description.act) 4.096) (lth ~(wyt by tasks.db) 2.048))
      [%| 'Task title, description or capacity limit exceeded']
    (done db(tasks (~(put by tasks.db) id.act [project.act title.act description.act 1 %open ~ '' ~ now])))
  =/  task  (~(get by tasks.db) id.act)
  ?~  task  [%| 'Task not found or unavailable']
  ?.  =(`%contributor (project-role db who project.u.task))  [%| 'No contributor access to this project']
  =/  expected  ?:(?=(%task-claim -.act) version.act version.act)
  ?.  =(expected version.u.task)  [%| 'Task changed; inspect its current claim before acting']
  ?:  ?=(%task-claim -.act)
    ?.  =(%open status.u.task)  [%| 'Task is not available to claim']
    (done db(tasks (~(put by tasks.db) id.act u.task(version +(version.u.task), status %claimed, claimant `by.who, updated now))))
  ?.  |(owner.who =(`scope.by.who ?~(claimant.u.task ~ `scope.u.claimant.u.task)))
    [%| 'Only the claiming agent or owner can update this task']
  ?.  (lte (met 3 outcome.act) 4.096)  [%| 'Task outcome exceeds limit']
  =/  linked  ?~(artifact.act ~ (~(get by artifacts.db) u.artifact.act))
  ?.  ?~(artifact.act & &(?=(^ linked) =(`project.u.task project.u.linked) (can-read db who u.linked)))
    [%| 'Task artifact must be accessible in the same project']
  =/  next
    %=  u.task
      version  +(version.u.task)
      status  status.act
      claimant  ?:(=(%open status.act) ~ ?~(claimant.u.task `by.who claimant.u.task))
      outcome  outcome.act
      artifact  artifact.act
      updated  now
    ==
  (done db(tasks (~(put by tasks.db) id.act next)))
--
