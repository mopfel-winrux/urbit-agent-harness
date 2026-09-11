::  Native Notes projection and request preparation. This is an adapter, not
::  a second document engine: all accepted bodies/history come from Notes.
/-  n=tlon-notes, w=harness-workspace, hn=harness-notes
/+  codec=harness-workspace-json, work=harness-workspace
|%
++  owns
  |=  action=@t
  ^-  ?
  (lien `(list @t)`~['artifact-create' 'artifact-save' 'artifact-rename' 'publish' 'unpublish'] |=(value=@t =(action value)))
++  accepts
  |=  [action=@t args=json]
  ^-  ?
  ?:  (owns action)  &
  &(=('review' action) (boolean:codec args 'accept' |))
++  needs-notes
  |=  action=@t
  ^-  ?
  (lien `(list @t)`~['artifacts' 'artifact' 'revisions' 'revision' 'proposals' 'proposal' 'preview' 'artifact-create' 'artifact-save' 'artifact-archive' 'artifact-rename' 'propose' 'review' 'publish' 'unpublish'] |=(item=@t =(action item)))
++  public-path
  |=  [book=flag:n note=@ud]
  ^-  @t
  (rap 3 '/notes/pub/' (scot %p ship.book) '/' name.book '/' (scot %ud note) ~)
++  decorate
  |=  [native=state:hn value=json]
  ^-  json
  ?~  value  ~
  ?:  ?=(%a -.value)  [%a (turn p.value |=(item=json (decorate native item)))]
  ?.  ?=(%o -.value)  value
  =/  mapped=(map @t json)
    %+  roll  ~(tap by p.value)
    |=  [[key=@t item=json] out=(map @t json)]
    (~(put by out) key (decorate native item))
  =.  value  [%o mapped]
  ?.  &((~(has by p.value) 'head') ?=(^ book.native))  value
  =/  id  (optional:codec value 'id')
  ?~  id  value
  =/  link  (~(get by links.native) u.id)
  ?~  link  value
  =/  book  u.book.native
  =/  info
    (pairs:enjs:format ~[['notebook' %s (rap 3 (scot %p ship.book) '/' name.book ~)] ['noteId' %s (scot %ud note.u.link)] ['path' %s (public-path book note.u.link)]])
  [%o (~(put by p.value) 'notes' info)]
++  request-id
  |=  pending=pending:hn
  ^-  @uv
  (sham [id.pending stage.pending])
++  revision
  |=  [link=link:hn number=@ud at=@da author=@p title=@t body=@t]
  ^-  revision:w
  =/  writer=actor:w  (fall (~(get by authors.link) number) [0v0 (scot %p author)])
  [at writer [title body (fall (~(get by sources.link) number) ~)]]
++  project-note
  |=  [art=artifact:w link=link:hn note=note:n history=(list note-revision:n)]
  ^-  artifact:w
  =/  revisions=(map @ud revision:w)
    %+  roll  history
    |=  [old=note-revision:n out=(map @ud revision:w)]
    (~(put by out) +(rev.old) (revision link +(rev.old) at.old author.old title.old body-md.old))
  =.  revisions
    (~(put by revisions) +(revision.note) (revision link +(revision.note) updated-at.note updated-by.note title.note body-md.note))
  art(label title.note, head +(revision.note), revisions revisions)
++  project-book
  |=  [db=state:w native=state:hn book=notebook-state:n]
  ^-  state:w
  %+  roll  ~(tap by links.native)
  |=  [[id=@t link=link:hn] out=_db]
  =/  art  (~(get by artifacts.out) id)
  ?~  art  out
  =/  note  (~(get by notes.book) note.link)
  ?~  note  out(artifacts (~(del by artifacts.out) id), writes +(writes.out))
  =/  history  (fall (~(get by history.book) note.link) ~)
  =/  next  (project-note u.art link u.note history)
  ?:  =(next u.art)  out
  out(artifacts (~(put by artifacts.out) id next), writes +(writes.out))
++  project-update
  |=  [db=state:w native=state:hn update=u-notebook:n]
  ^-  state:w
  ?.  ?=(%note -.update)  db
  %+  roll  ~(tap by links.native)
  |=  [[id=@t link=link:hn] out=_db]
  ?.  =(note.link id.update)  out
  =/  art  (~(get by artifacts.out) id)
  ?~  art  out
  ?:  ?=(%deleted -.u-note.update)
    out(artifacts (~(del by artifacts.out) id), writes +(writes.out))
  =/  next=artifact:w
    ?:  ?=(%updated -.u-note.update)
      =/  note  note.u-note.update
      =/  current  (revision link +(revision.note) updated-at.note updated-by.note title.note body-md.note)
      u.art(label title.note, head +(revision.note), revisions (~(put by revisions.u.art) +(revision.note) current))
    ?:  ?=(%history-archived -.u-note.update)
      =/  old  note-revision.u-note.update
      u.art(revisions (~(put by revisions.u.art) +(rev.old) (revision link +(rev.old) at.old author.old title.old body-md.old)))
    u.art
  ?:  =(next u.art)  out
  out(artifacts (~(put by artifacts.out) id next), writes +(writes.out))
++  prepare
  |=  [db=state:w native=state:hn reply=reply:hn action=@t args=json fallback=@t now=@da request=@uv]
  ^-  (each pending:hn @t)
  ?^  pending.native  [%| 'A Notes operation is still in progress. Inspect its result before submitting another document change.']
  =/  target  (fall (optional:codec args 'id') fallback)
  =/  owner=authority:w  [& [0v0 'Owner'] 0v0]
  =/  candidate=artifact:w  *artifact:w
  =/  value=content:w  *content:w
  =/  writer=actor:w  by.owner
  =/  proposal=(unit @t)  ~
  =/  command=a-notes:n  [%create-notebook 'Harness artifacts']
  ?:  =('artifact-rename' action)
    =/  art  (~(get by artifacts.db) target)
    =/  link  (~(get by links.native) target)
    ?.  &(?=(^ art) ?=(^ link) ?=(^ book.native))  [%| 'Native Notes document not found']
    ?:  archived.u.art  [%| 'Restore the artifact before renaming']
    =/  title  (string:codec args 'title')
    ?.  &((gth (met 3 title) 0) (lte (met 3 title) 256))  [%| 'Title must contain 1–256 UTF-8 bytes']
    [%& [request reply action args target u.art value writer ~ %write | [%notebook u.book.native %note note.u.link %rename title] |]]
  =/  decoded  (mule |.((decode:codec db action args fallback)))
  ?.  ?=(%& -.decoded)  [%| 'Invalid Notes action or parameters']
  =/  act  p.decoded
  ::  Existing pure validation supplies project access and proposal fences.
  ::  Its hypothetical document mutation is never persisted or served.
  =/  checked  (apply:work db owner act now)
  ?.  ?=(%& -.checked)  [%| p.checked]
  =?  target  ?=(%review -.act)
    artifact:(~(got by proposals.db) id.act)
  =.  candidate  (~(got by artifacts.p.checked) target)
  =?  value  ?=(%review -.act)
    value:(~(got by proposals.db) id.act)
  =?  writer  ?=(%review -.act)
    by:(~(got by proposals.db) id.act)
  =?  proposal  ?=(%review -.act)  `id.act
  =?  value  ?=(?(%artifact-create %artifact-save) -.act)
    ?:  ?=(%artifact-create -.act)  value.act
    ?>  ?=(%artifact-save -.act)
    value.act
  =/  link  (~(get by links.native) target)
  =/  creating  ?=(~ link)
  ?.  |(creating ?=(^ book.native))  [%| 'Native Notes notebook is unavailable']
  =/  command=a-notes:n
    ?~  book.native  [%create-notebook 'Harness artifacts']
    :-  %notebook  :-  u.book.native
    ?:  creating  [%create-note folder.native title.value body.value]
    :-  %note  :-  note:(need link)
    ?:  ?=(%publish -.act)  [%publish html.act]
    ?:  ?=(%unpublish -.act)  [%unpublish ~]
    ::  Titles are native metadata, not body revisions. Never turn a body
    ::  proposal into an unfenced rename or a hidden two-command save.
    [%update body.value (dec head:(~(got by artifacts.db) target))]
  ?:  &(!creating ?=(?(%artifact-save %review) -.act) !=(title.value label:(~(got by artifacts.db) target)))
    [%| 'Titles are separate Notes metadata. Rename the document explicitly; body saves and proposals must retain its current title.']
  [%& [request reply action args target candidate(revisions ~) value writer proposal ?:(?=(~ book.native) %book %write) | command |]]
++  complete
  |=  [db=state:w native=state:hn note=note:n history=(list note-revision:n) number=@ud now=@da]
  ^-  [db=state:w native=state:hn]
  =/  pending  (need pending.native)
  =/  id  artifact.pending
  =/  link=link:hn  (fall (~(get by links.native) id) [id.note ~ ~])
  =?  link  |(=('artifact-create' action.pending) =('artifact-save' action.pending) ?=(^ proposal.pending))
    link(sources (~(put by sources.link) number sources.value.pending), authors (~(put by authors.link) number by.pending))
  =/  candidate  candidate.pending
  =?  publication.candidate  ?=(^ publication.candidate)
    `u.publication.candidate(slug (public-path (need book.native) id.note), html '')
  =/  art  (project-note candidate link note history)
  =?  proposals.db  ?=(^ proposal.pending)
    =/  pid  u.proposal.pending
    =/  old  (~(got by proposals.db) pid)
    (~(put by proposals.db) pid old(status %accepted, decided `now, decision (fall (optional:codec args.pending 'reason') ''), revision `number))
  =.  db
    db(artifacts (~(put by artifacts.db) id art), writes +(writes.db), history [[now by.pending action.pending id] (scag 2.047 history.db)])
  =?  bytes.db  |(=('artifact-create' action.pending) =('artifact-save' action.pending))
    (add bytes.db (content-size:work value.pending))
  [db native(links (~(put by links.native) id link), pending ~)]
++  reader
  |_  bowl=bowl:gall
  ++  note
    |=  [book=flag:n id=@ud]
    ^-  note:n
    .^(note:n %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/note/(scot %p ship.book)/[name.book]/(scot %ud id)/noun)
  ++  history
    |=  [book=flag:n id=@ud]
    ^-  (list note-revision:n)
    .^((list note-revision:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/note-history/(scot %p ship.book)/[name.book]/(scot %ud id)/noun)
  ++  published
    ^-  (list published-record:n)
    .^((list published-record:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/published/notes-published)
  ++  visible
    |=  [book=flag:n id=@ud]
    (lien published |=(item=published-record:n &(=(book flag.item) =(id note-id.item))))
  ++  refresh
    |=  [db=state:w native=state:hn]
    ^-  state:w
    ?~  book.native  db
    =/  book  u.book.native
    =/  rows=(list note:n)
      .^((list note:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notes/(scot %p ship.book)/[name.book]/noun)
    =/  pages  published
    %+  roll  ~(tap by links.native)
    |=  [[id=@t link=link:hn] out=_db]
    =/  art  (~(get by artifacts.out) id)
    ?~  art  out
    =/  public  (lien pages |=(item=published-record:n &(=(book flag.item) =(note.link note-id.item))))
    =?  art  !=(public ?=(^ publication.u.art))
      `u.art(publication ?:(public `[0 (public-path book note.link) '' now.bowl] ~), exposure +(exposure.u.art))
    =?  writes.out  !=(art (~(get by artifacts.out) id))  +(writes.out)
    =.  artifacts.out  (~(put by artifacts.out) id u.art)
    =/  found  (skim rows |=(item=note:n =(id.item note.link)))
    ?~  found  out(artifacts (~(del by artifacts.out) id), writes +(writes.out))
    =/  current  i.found
    =/  last  (~(get by revisions.u.art) +(revision.current))
    ::  Only changed notes require a history scry and projection rebuild.
    ?:  ?&(?=(^ last) =(head.u.art +(revision.current)) =(title.current label.u.art) =(body-md.current body.value.u.last))
      out
    =/  next  (project-note u.art link current (history book note.link))
    out(artifacts (~(put by artifacts.out) id next), writes +(writes.out))
  --
--
