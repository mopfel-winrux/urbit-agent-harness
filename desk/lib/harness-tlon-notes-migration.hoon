::  Explicit, resumable diary -> Notes copying. Source is never mutated.
::  A fresh plan binds source content, permissions and destination state.
/-  n=tlon-notes, g=tlon-groups-ver, d=tlon-channels-ver
/+  spec=harness-tlon-tool, md=harness-tlon-notes-markdown, hp=harness-tlon-history-page
|_  bowl=bowl:gall
++  handles
  |=  action=@t
  |(=('plan_notes_migration' action) =('migrate_notes' action))
++  group-id
  |=  flag=flag:n
  (rap 3 (scot %p ship.flag) '/' name.flag ~)
++  widening
  |=  [readers=(set @tas) writers=(set @tas) admins=(set @tas) public=?]
  ^-  ?
  ?:  =(~ readers)  |(public !=(~ writers))
  ?.  !=(~ writers)  |
  (lien ~(tap in readers) |=(role=@tas &(!(~(has in writers) role) !(~(has in admins) role))))
++  provenance
  |=  body=@t
  ^-  (unit @t)
  =/  tail  (rsh [3 (sub (met 3 body) (min 512 (met 3 body)))] body)
  =/  chars  (flop (trip tail))
  =/  line=tape  ~
  |-
  ?:  |(?=(~ chars) =(10 i.chars))
    =/  value  (crip line)
    =/  prefix  '<!-- harness-notes-migrate: '
    ?.  =(prefix (end [3 (met 3 prefix)] value))  ~
    `value
  $(chars t.chars, line [i.chars line])
++  index
  |=  notes=(list note:n)
  ^-  (map @t (list note:n))
  %+  roll  notes
  |=  [note=note:n out=(map @t (list note:n))]
  =/  marker  (provenance body-md.note)
  ?~  marker  out
  (~(put by out) u.marker [note (fall (~(get by out) u.marker) ~)])
++  converted
  |=  [channel=@t post=post:v10:d]
  ^-  [title=@t body=@t marker=@t]
  ::  Unknown custom payloads must not be silently discarded.
  ?>  ?=(~ blob.post)
  =/  title  ?~(meta.post (scot %da id.post) title.u.meta.post)
  =?  title  =('' title)  (scot %da id.post)
  ?>  (lte (met 3 title) 1.024)
  =/  content  (markdown:md content.post)
  =/  pictures
    ?~  meta.post  ''
    =/  images=(list @t)  ~[image.u.meta.post cover.u.meta.post]
    (rap 3 (turn (skim images |=(s=@t !=('' s))) |=(s=@t (rap 3 '![](' (url:md s) ')\0a\0a' ~))))
  =/  description  ?~(meta.post '' description.u.meta.post)
  =/  who  ?@(author.post author.post ship.author.post)
  =/  decimal  (crip (a-co:co id.post))
  =/  marker  (rap 3 '<!-- harness-notes-migrate: ' channel ' ' decimal ' -->' ~)
  =/  body
    %+  rap  3
    :~  pictures  ?:(=('' description) '' (cat 3 (escape:md description) '\0a\0a'))
        content  '*Originally posted by '  (scot %p who)  ' at '  (scot %da sent.post)  '.*\0a\0a'
        'Source: `/1/chan/'  channel  '/note/'  decimal  '`\0a\0a'
        '<!-- harness-notes-source: '  (scot %uv (sham +.post))  ' -->\0a'
        marker
    ==
  ?>  (lte (met 3 body) 131.072)
  [title body marker]
++  prepare
  |=  args=json
  ^-  [preview=json flag=flag:n folder=@ud batch=(list [title=@t body=@t]) revision=@t widening=?]
  =/  channel  (required:spec args 'channel' 256)
  =/  nest  (nest:spec channel)
  ?>  &(=(%diary kind.nest) =(our.bowl ship.nest))
  =/  perm=perm:v9:d
    .^(perm:v9:d %gx /(scot %p our.bowl)/channels/(scot %da now.bowl)/diary/(scot %p ship.nest)/[name.nest]/perm/channel-perm)
  =/  gf=flag:n  group.perm
  ?>  =(our.bowl ship.gf)
  =/  groups=groups:v9:g
    .^(groups:v9:g %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v2/groups/noun)
  =/  group  (~(got by groups) gf)
  =/  source  (~(got by channels.group) nest)
  =/  wide  (widening readers.source writers.perm admins.group =(%public privacy.admissions.group))
  =/  flag=flag:n
    ?:  (has:spec args 'notebook')  (flag:spec (required:spec args 'notebook' 256))
    [our.bowl %unused]
  =/  [folder=@ud folders=(list folder:n) notes=(list note:n) target=(unit channel:v9:g)]
    ?.  (has:spec args 'notebook')  [0 ~ ~ ~]
    ?>  =(our.bowl ship.flag)
    =/  target  (~(got by channels.group) [%notes flag])
    ?>  =(readers.source readers.target)
    =/  folders=(list folder:n)
      .^((list folder:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/folders/(scot %p ship.flag)/[name.flag]/noun)
    =/  detail=notebook-detail:n
      .^(notebook-detail:n %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notebook/(scot %p ship.flag)/[name.flag]/noun)
    =/  folder  (number:spec args 'folder_id' +(id.notebook.detail))
    ?>  (lien folders |=(f=folder:n =(folder id.f)))
    =/  notes=(list note:n)
      .^((list note:n) %gx /(scot %p our.bowl)/notes/(scot %da now.bowl)/v0/notes/(scot %p ship.flag)/[name.flag]/noun)
    ?>  (lte (lent notes) 10.000)
    [folder folders notes `target]
  =/  prior  (index notes)
  ::  One coherent local snapshot, bounded with one lookahead row. Outline
  ::  retains full essays and reply counts without fetching comment bodies.
  =/  page=paged-posts:v10:d
    .^(paged-posts:v10:d %gx /(scot %p our.bowl)/channels/(scot %da now.bowl)/v5/diary/(scot %p ship.nest)/[name.nest]/posts/newest/5.001/outline/channel-posts-5)
  =/  rows  (tap:on-posts:v10:d posts.page)
  ?>  &((lte total.page 5.000) =((lent rows) total.page) =(~ older.page))
  =/  revision  (scot %uv (sham [%notes-migration channel page gf group perm flag folder folders notes target]))
  =/  eligible=@ud  0
  =/  skipped=@ud  0
  =/  imported=@ud  0
  =/  conflicts=@ud  0
  =/  comments=@ud  0
  =/  reactions=@ud  0
  =/  bytes=@ud  0
  =/  batch-bytes=@ud  0
  =/  batch=(list [title=@t body=@t])  ~
  =/  titles=(list json)  ~
  =/  blocked=?  |
  |-  ^-  [preview=json flag=flag:n folder=@ud batch=(list [title=@t body=@t]) revision=@t widening=?]
  ?~  rows
    =/  remaining  (sub eligible imported)
    =/  preview
      %-  pairs:enjs:format
      :~  ['channel' %s channel]  ['group' %s (group-id gf)]
          ['suggested_title' %s title.meta.source]
          ['readers' %a (turn ~(tap in readers.source) |=(r=@tas [%s r]))]
          ['writers' %a (turn ~(tap in writers.perm) |=(r=@tas [%s r]))]
          ['write_widening' %b wide]  ['eligible' (numb:enjs:format eligible)]
          ['skipped_deleted_or_stub' (numb:enjs:format skipped)]
          ['already_imported' (numb:enjs:format imported)]  ['conflicts' (numb:enjs:format conflicts)]
          ['remaining' (numb:enjs:format remaining)]  ['batch_count' (numb:enjs:format (lent batch))]
          ['body_bytes' (numb:enjs:format bytes)]  ['batch_bytes' (numb:enjs:format batch-bytes)]
          ['archive_comments' (numb:enjs:format comments)]  ['archive_reactions' (numb:enjs:format reactions)]
          ['preview_titles' %a (flop titles)]
          ['ready' %b &(?=(^ target) =(conflicts 0) (gth (lent batch) 0))]
          ['complete' %b &(?=(^ target) =(remaining 0) =(conflicts 0))]
          ['revision' ?~(target ~ [%s revision])]
          ['confirm' ?~(target ~ [%s (rap 3 channel ' -> ' (group-id flag) '/folder/' (scot %ud folder) ~)])]
          ['folder_id' ?~(target ~ [%s (scot %ud folder)])]
          ['note' %s 'Source diary is preserved unchanged. Replies/reactions, native revision history and dynamic references remain in the source; authors/timestamps and source links are recorded in imported Markdown. Create a group notebook with these exact readers, then re-plan with notebook. Confirm each batch; allow_write_widening=true requires explicit consent when flagged. Re-plan after every batch. Modified imports are conflicts, never overwritten.']
      ==
    ?>  (lte (met 3 (en:json:html preview)) 23.000)
    [preview flag folder (flop batch) revision wide]
  =/  row  +.i.rows
  ?:  ?=(%| -.row)  $(rows t.rows, skipped +(skipped))
  =/  post  +.row
  ?:  =(seq.post 0)  $(rows t.rows, skipped +(skipped))
  =/  note  (converted channel post)
  =/  size  (add (met 3 title.note) (met 3 body.note))
  ?>  (lte size 131.072)
  =.  bytes  (add bytes size)
  ?>  (lte bytes 8.388.608)
  =.  eligible  +(eligible)
  =.  comments  (add comments reply-count.reply-meta.post)
  =.  reactions  (add reactions ~(wyt by reacts.post))
  =/  matches  (fall (~(get by prior) marker.note) ~)
  ?^  matches
    =/  exact  &(=(~ t.matches) =(folder folder-id.i.matches) =(title.note title.i.matches) =(body.note body-md.i.matches))
    ?:  exact  $(rows t.rows, imported +(imported))
    $(rows t.rows, conflicts +(conflicts))
  =.  titles  ?:(=(8 (lent titles)) titles [[%s (clip-text:hp title.note 128)] titles])
  ?:  |(blocked =(64 (lent batch)) (gth (add batch-bytes size) 131.072))
    $(rows t.rows, blocked &)
  $(rows t.rows, batch [[title.note body.note] batch], batch-bytes (add batch-bytes size))
++  approved
  |=  args=json
  ^+  (prepare args)
  =/  data  (prepare args)
  ?>  ?=(%o -.preview.data)
  ?>  =([%b &] (~(got by p.preview.data) 'ready'))
  ?>  =(revision.data (required:spec args 'revision' 128))
  ?>  =((so:dejs:format (~(got by p.preview.data) 'confirm')) (required:spec args 'confirm' 768))
  =/  consent  (string:spec args 'allow_write_widening' 'false' 5)
  ?>  |(=('true' consent) =('false' consent))
  ?>  |(!widening.data =('true' consent))
  data
++  command
  |=  [args=json snapshot=response:n]
  ^-  a-notes:n
  =/  data  (approved args)
  ?>  ?=(%snapshot -.snapshot)
  ?>  =(flag.data flag.snapshot)
  ?>  ?=(%o -.preview.data)
  =/  gf  (flag:spec (so:dejs:format (~(got by p.preview.data) 'group')))
  ?>  =(`gf group.notebook-state.snapshot)
  [%notebook flag.data %batch-import folder.data batch.data]
++  run
  |=  [args=json wire=wire]
  ^-  [body=@t effect=(unit card:agent:gall)]
  ?:  =('plan_notes_migration' (required:spec args 'action' 32))
    =/  data  (prepare args)
    [(en:json:html preview.data) ~]
  =/  data  (approved args)
  ?>  ?=([@ @ ~] wire)
  ['pending: verifying native Notes affiliation' `[%pass /tlon-notes-migration/[i.t.wire] %agent [our.bowl %notes] %watch /v0/notes/(scot %p ship.flag.data)/[name.flag.data]/stream]]
--
