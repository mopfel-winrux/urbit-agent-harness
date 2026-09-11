::  Owner search merges two disposable indexes. Grouping is native and happens
::  before pagination; a cursor is a position, never permission to read a note.
/-  c=harness-corpus, w=harness-workspace, s=harness-workspace-search
/+  ci=harness-corpus-index, cj=harness-corpus-json, wi=harness-workspace-search, wj=harness-workspace-json, work=harness-workspace
|%
+$  cursor  [sent=@da kind=?(%conversation %artifact %project %task) id=@t ordinal=@ud]
+$  hit  [position=cursor value=json]
++  before
  |=  [a=cursor b=cursor]
  ^-  ?
  ?:  =(a b)  |
  ?:  !=(sent.a sent.b)  (gth sent.a sent.b)
  ?:  !=(=(%conversation kind.a) =(%conversation kind.b))  =(%conversation kind.a)
  ?:  =(%conversation kind.a)  (gth ordinal.a ordinal.b)
  (gor [kind.a id.a] [kind.b id.b])
++  insert
  |=  [row=hit rows=(list hit) limit=@ud]
  ^-  (list hit)
  ?:  =(0 limit)  ~
  ?~  rows  ~[row]
  ?:  (before position.row position.i.rows)
    [row (scag (dec limit) `(list hit)`rows)]
  [i.rows $(rows t.rows, limit (dec limit))]
++  token
  |=  [corpus=state:c idx=state:s db=state:w allowed=(set scope:c) query=@t available=?]
  ^-  @t
  (scot %uv (sham [query allowed built-at.index.corpus epoch.idx writes.db available]))
++  encode
  |=  [fence=@t position=cursor]
  ^-  @t
  %-  en:json:html
  (pairs:enjs:format ~[['fence' %s fence] ['sent' %s (scot %da sent.position)] ['kind' %s kind.position] ['id' %s id.position] ['ordinal' (numb:enjs:format ordinal.position)]])
++  decode
  |=  [fence=@t raw=@t]
  ^-  (unit cursor)
  ?.  (lte (met 3 raw) 4.096)  ~
  %-  mole  |.
  =/  json  (need (de:json:html raw))
  ?>  =((string:wj json 'fence') fence)
  =/  kind  (string:wj json 'kind')
  ?>  (lien `(list @t)`~['conversation' 'artifact' 'project' 'task'] |=(item=@t =(item kind)))
  [(slav %da (string:wj json 'sent')) ;;(?(%conversation %artifact %project %task) kind) (string:wj json 'id') (number:wj json 'ordinal' 0)]
++  status
  |=  [corpus=state:c idx=state:s allowed=(set scope:c) available=?]
  ^-  json
  =/  base  (status:cj corpus allowed)
  ?>  ?=(%o -.base)
  =.  p.base  (~(put by p.base) 'workspaceRecords' (numb:enjs:format ~(wyt by documents.idx)))
  =.  p.base  (~(put by p.base) 'workspaceAvailable' [%b available])
  =.  p.base  (~(put by p.base) 'workspaceIndexing' [%b |(!initialized.idx ?=(^ queued.idx))])
  base
++  versions
  |=  [idx=state:s db=state:w who=authority:w key=key:s matches=(set @ud)]
  ^-  (set @ud)
  =/  permitted
    ?:  =(%artifact kind.key)
      =/  art  (~(get by artifacts.db) id.key)
      ?~(art | (can-read:work db who u.art))
    ?:  =(%project kind.key)
      &((~(has by projects.db) id.key) |(owner.who ?=(^ (project-role:work db who id.key))))
    =/  task  (~(get by tasks.db) id.key)
    ?~(task | |(owner.who ?=(^ (project-role:work db who project.u.task))))
  ?.  permitted  ~
  %-  silt
  %+  skim  ~(tap in matches)
  |=(revision=@ud (live:wi idx db [key revision]))
++  workspace-hit
  |=  [idx=state:s db=state:w who=authority:w key=key:s matches=(set @ud) fence=@t]
  ^-  (unit hit)
  =/  matches  (versions idx db who key matches)
  ?~  matches  ~
  =/  available=(set @ud)  matches
  =/  number  (roll ~(tap in available) max)
  =/  indexed  (~(got by documents.idx) [key number])
  =/  texts  (need (source:wi db [key number]))
  =/  title  ?~(texts '' i.texts)
  =/  project=(unit @t)  ~
  =/  head=@ud  0
  =/  archived=?  |
  =?  title  =(%artifact kind.key)  label:(~(got by artifacts.db) id.key)
  =?  project  =(%artifact kind.key)  project:(~(got by artifacts.db) id.key)
  =?  project  =(%task kind.key)  `project:(~(got by tasks.db) id.key)
  =?  head  =(%artifact kind.key)  head:(~(got by artifacts.db) id.key)
  =?  archived  =(%artifact kind.key)  archived:(~(got by artifacts.db) id.key)
  =?  archived  =(%project kind.key)  archived:(~(got by projects.db) id.key)
  =/  value
    %-  pairs:enjs:format
    :~  ['kind' %s kind.key]
        ['id' %s id.key]
        ['title' %s title]
        ['project' (nullable:wj project)]
        ['head' (numb:enjs:format head)]
        ['revision' (numb:enjs:format number)]
        ['matchCount' (numb:enjs:format ~(wyt in available))]
        ['currentMatches' %b (~(has in available) head)]
        ['archived' %b archived]
        ['sent' (stamp:wj at.indexed)]
        ['snippet' %s (make-snippet:ci ?~(texts ~ (weld t.texts ~[i.texts])))]
        ['searchToken' %s fence]
    ==
  `[[at.indexed kind.key id.key 0] value]
++  search
  |=  [corpus=state:c idx=state:s db=state:w allowed=(set scope:c) who=authority:w available=? query=@t cursor=(unit @t) limit=@ud]
  ^-  (each json @t)
  ?.  &((lte (met 3 query) 512) (gth limit 0) (lte limit 32))
    [%| 'Search accepts at most 512 query bytes and 1–32 results per page.']
  =/  fence  (token corpus idx db allowed query available)
  =/  after  ?~(cursor ~ (decode fence u.cursor))
  ?:  &(?=(^ cursor) ?=(~ after))
    [%| 'Search content or access changed. Run the search again from the first page.']
  =/  corpus-after=(unit cursor:c)
    ?~  after  ~
    `[sent.u.after ?:(=(%conversation kind.u.after) ordinal.u.after 0)]
  =/  conversation-page  (search-scoped:ci index.corpus query corpus-after +(limit) `allowed)
  =/  rows=(list hit)
    %+  turn  hits.conversation-page
    |=  item=hit:c
    [[sent.cursor.item %conversation '' id.cursor.item] (record-json:cj corpus scope.ref.item at.ref.item)]
  =?  rows  available
    %+  roll  ~(tap by (search:wi idx query))
    |=  [[key=key:s matches=(set @ud)] out=_rows]
    =/  row  (workspace-hit idx db who key matches fence)
    ?~  row  out
    ?:  ?~(after | !(before u.after position.u.row))  out
    (insert u.row out +(limit))
  =/  more  (gth (lent rows) limit)
  =/  selected  (scag limit rows)
  =/  next=(unit @t)
    ?.  more  ~
    `(encode fence position:(rear selected))
  :-  %&
  %-  pairs:enjs:format
  :~  ['hits' %a (turn selected |=(row=hit value.row))]
      ['cursor' (nullable:wj next)]
      ['complete' %b !more]
      ['status' (status corpus idx allowed available)]
  ==
++  expand
  |=  [corpus=state:c idx=state:s db=state:w allowed=(set scope:c) who=authority:w available=? args=json]
  ^-  (each json @t)
  ?.  available  [%| 'Native Notes is unavailable; no cached revision was returned.']
  =/  query  (string:wj args 'query')
  =/  fence  (token corpus idx db allowed query available)
  ?.  =(fence (string:wj args 'searchToken'))
    [%| 'Search content or access changed. Run the search again to inspect matching revisions.']
  =/  id  (string:wj args 'id')
  =/  key=key:s  [%artifact id]
  =/  matches  (versions idx db who key (fall (~(get by (search:wi idx query)) key) *(set @ud)))
  =/  numbers  (sort ~(tap in matches) gth)
  =/  offset  (number:wj args 'offset' 0)
  =/  limit  (number:wj args 'limit' 16)
  ?.  &((gth limit 0) (lte limit 32) (lte offset (lent numbers)))
    [%| 'Invalid matching-revision offset or limit.']
  =/  selected  (scag limit (slag offset numbers))
  =/  items
    %+  turn  selected
    |=  number=@ud
    =/  rev  (~(got by revisions:(~(got by artifacts.db) id)) number)
    (pairs:enjs:format ~[['revision' (numb:enjs:format number)] ['title' %s title.value.rev] ['at' (stamp:wj at.rev)] ['by' (actor-json:wj by.rev)]])
  =/  through  (add offset (lent selected))
  [%& (pairs:enjs:format ~[['items' %a items] ['nextOffset' ?:((gte through (lent numbers)) ~ (numb:enjs:format through))] ['searchToken' %s fence]])]
++  read
  |=  [corpus=state:c idx=state:s db=state:w allowed=(set scope:c) who=authority:w available=? args=json]
  ^-  (each json @t)
  ?.  available  [%| 'Native Notes is unavailable; no cached workspace content was returned.']
  =/  query  (string:wj args 'query')
  ?.  =((token corpus idx db allowed query available) (string:wj args 'searchToken'))
    [%| 'Search content or access changed. Run the search again before opening this result.']
  =/  kind  (string:wj args 'kind')
  ?>  |(=('artifact' kind) =('project' kind) =('task' kind))
  =/  id  (string:wj args 'id')
  =/  key=key:s  [;;(?(%artifact %project %task) kind) id]
  =/  revision  ?:(=('artifact' kind) (number:wj args 'revision' 0) 0)
  =/  matches  (versions idx db who key (fall (~(get by (search:wi idx query)) key) *(set @ud)))
  ?.  (~(has in matches) revision)  [%| 'This record no longer matches the search or is no longer available.']
  [%& (read:wj db who ?:(=('artifact' kind) 'revision' kind) args)]
--
