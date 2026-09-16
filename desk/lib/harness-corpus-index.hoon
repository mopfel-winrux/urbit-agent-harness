::  Adapted from tlon-apps reid/global-search, commit 95dee1d91.
::  Keep the standard map/set nouns and ordered mop/on posting trees: their
::  native operations, bounded segments, and exact directory are deliberate.
/-  gs=harness-corpus
|%
::  A posting tree is ordered oldest-to-newest.  Queries traverse it in
::  reverse and can stop as soon as one segment has supplied a page.
::
++  cursor-lte
  cursor-lte:gs
+$  posting  posting:gs
++  on-posting  ((on cursor:gs @ud) cursor-lte)
::
+$  document  document:gs
+$  thread  event-key:gs
::  Segments bound the size of every posting tree.  The exact global
::  directory maps each term to the segments that contain it; set
::  intersection is jetted in Vere and avoids probing unrelated segments.
::
+$  segment  segment:gs
+$  index  index:gs
++  segment-size  4.096
++  fuzzy-limit  32
++  fuzzy-scan-limit  4.096
++  fuzzy-prefix-size  2
::  Lowercase ASCII and split text into useful search terms.  Non-ASCII bytes
::  are retained as term bytes, so literal UTF-8 searches work even though
::  full Unicode case folding is intentionally out of scope for this index.
::
++  tokenize
  |=  texts=(list @t)
  ^-  (set @t)
  %+  roll  texts
  |=  [text=@t out=(set @t)]
  (~(uni in out) (tokenize-text text))
::
++  tokenize-text
  |=  text=@t
  ^-  (set @t)
  =/  chars=tape  (trip (lower-text text))
  =/  parsed=[cur=tape out=(set @t)]
    %+  roll  chars
    |=  [char=@ cur=tape out=(set @t)]
    ?:  (term-char char)
      [[char cur] out]
    ?~  cur  [~ out]
    [~ (~(put in out) (crip (flop cur)))]
  =/  cur=tape  cur.parsed
  =/  out=(set @t)  out.parsed
  ?~  cur  out
  (~(put in out) (crip (flop cur)))
::
++  term-char
  |=  char=@
  ^-  ?
  ?|  &((gte char 'a') (lte char 'z'))
      &((gte char '0') (lte char '9'))
      (gte char 128)
      =('-' char)
      =('_' char)
      =('~' char)
  ==
::
++  lower-text
  |=  text=@t
  ^-  @t
  %^    run
      3
    text
  |=  byte=@
  ^-  @
  ?.  &((gth byte 64) (lth byte 91))
    byte
  (add byte 32)
::
::  Add a document to the active bounded segment.  Document ids remain global
::  so cursors are unambiguous even though document maps are segmented.
::
++  put-document
  |=  [idx=index =ref:gs sent=@da author=@t texts=(list @t)]
  ^-  index
  =/  doc-terms=(set @t)  (tokenize texts)
  ?:  =(~ doc-terms)  (remove-document idx ref)
  =/  thread=thread  [scope.ref at.ref]
  =/  thread-live=(map (unit @ud) @ud)
    (fall (~(get by live.idx) thread) *(map (unit @ud) @ud))
  =/  existed=?  (~(has by thread-live) part.ref)
  =/  id=@ud  +(count.idx)
  =/  segment-id=@ud  (div count.idx segment-size)
  =/  seg=segment
    (fall (~(get by segments.idx) segment-id) *segment)
  =/  doc=document  [ref author]
  =.  docs.seg  (~(put by docs.seg) id doc)
  =.  count.seg  +(count.seg)
  =/  remaining=(list @t)  ~(tap in doc-terms)
  |-  ^-  index
  ?~  remaining
    =.  segments.idx  (~(put by segments.idx) segment-id seg)
    =.  thread-live  (~(put by thread-live) part.ref id)
    =.  live.idx  (~(put by live.idx) thread thread-live)
    =?  live-count.idx  !existed  +(live-count.idx)
    idx(count id)
  =/  term=@t  i.remaining
  =/  list=posting  (fall (~(get by postings.seg) term) *posting)
  =.  postings.seg
    (~(put by postings.seg) term (put:on-posting list [sent id] 0))
  =/  term-segments=(set @ud)
    (fall (~(get by directory.idx) term) *(set @ud))
  =/  new-term=?  =(~ term-segments)
  =?  directory.idx  !(~(has in term-segments) segment-id)
    (~(put by directory.idx) term (~(put in term-segments) segment-id))
  =?  prefixes.idx  new-term
    =/  prefix=@t  (term-prefix term)
    =/  prefix-terms=(set @t)
      (fall (~(get by prefixes.idx) prefix) *(set @t))
    (~(put by prefixes.idx) prefix (~(put in prefix-terms) term))
  $(remaining t.remaining)
::
::  Posting entries are immutable.  Replacement and deletion update the small
::  live-document map; queries ignore superseded postings.  A later rebuild
::  compacts the unreachable entries without making ordinary edits expensive.
::
++  remove-document
  |=  [idx=index =ref:gs]
  ^-  index
  =/  thread=thread  [scope.ref at.ref]
  =/  thread-live=(unit (map (unit @ud) @ud))
    (~(get by live.idx) thread)
  ?~  thread-live  idx
  ?.  (~(has by u.thread-live) part.ref)  idx
  =/  remaining=(map (unit @ud) @ud)
    (~(del by u.thread-live) part.ref)
  =.  live.idx
    ?:(=(~ remaining) (~(del by live.idx) thread) (~(put by live.idx) thread remaining))
  =.  live-count.idx  (dec live-count.idx)
  idx
::
++  remove-thread
  |=  [idx=index =thread]
  ^-  index
  =/  thread-live=(unit (map (unit @ud) @ud))
    (~(get by live.idx) thread)
  ?~  thread-live  idx
  =/  removed=@ud  ~(wyt by u.thread-live)
  =.  live.idx  (~(del by live.idx) thread)
  =.  live-count.idx  (sub live-count.idx removed)
  idx
::
++  remove-source
  |=  [idx=index scope=scope:gs]
  ^-  index
  =/  threads=(list thread)  ~(tap in ~(key by live.idx))
  |-  ^-  index
  ?~  threads  idx
  =/  idx=index
    ?:(=(scope scope.i.threads) (remove-thread idx i.threads) idx)
  $(threads t.threads)
::
::  Exact AND search over normalized terms.  The global directory first
::  intersects the candidate segment sets in native code.  Each candidate
::  segment then drives from its least-frequent posting and returns only a
::  bounded number of hits.  Finally those small lists are merged by cursor.
::
++  search
  |=  [idx=index query=@t after=(unit cursor:gs) limit=@ud]
  (search-scoped idx query after limit ~)
++  search-scoped
  |=  [idx=index query=@t after=(unit cursor:gs) limit=@ud allowed=(unit (set scope:gs))]
  ^-  page:gs
  ?>  &((lte limit 64) (lte (met 3 query) 512))
  ?:  =(0 limit)  [~ ~ & live-count.idx built-at.idx]
  =/  needles=(list @t)  ~(tap in (tokenize-text query))
  ?~  needles  [~ ~ & live-count.idx built-at.idx]
  =/  groups=(list (list @t))
    %+  turn  needles
    |=(needle=@t (candidate-terms idx needle))
  ?:  (lien groups |=(terms=(list @t) =(~ terms)))
    [~ ~ & live-count.idx built-at.idx]
  =/  candidates=(unit (set @ud))  (candidate-segments idx groups)
  ?~  candidates  [~ ~ & live-count.idx built-at.idx]
  =/  max=@ud  +(limit)
  =/  found=(list hit:gs)
    %+  roll  ~(tap in u.candidates)
    |=  [segment-id=@ud out=(list hit:gs)]
    =/  seg=(unit segment)  (~(get by segments.idx) segment-id)
    ?~  seg  out
    (merge (search-segment u.seg live.idx groups after max allowed) out max)
  =/  more=?  (gth (lent found) limit)
  =/  hits=(list hit:gs)  (scag limit found)
  =/  next=(unit cursor:gs)
    ?.  more  ~
    =/  last=hit:gs  (rear hits)
    `cursor.last
  [hits next ?:(more | &) live-count.idx built-at.idx]
::  Each segment returns sorted hits. Retain only one page while merging,
::  rather than accumulating and sorting page-size times every segment.
++  merge
  |=  [a=(list hit:gs) b=(list hit:gs) left=@ud]
  ^-  (list hit:gs)
  ?:  =(0 left)  ~
  ?~  a  (scag left `(list hit:gs)`b)
  ?~  b  (scag left `(list hit:gs)`a)
  ?:  (cursor-gth cursor.i.a cursor.i.b)
    [i.a $(a t.a, left (dec left))]
  [i.b $(b t.b, left (dec left))]
::
++  candidate-segments
  |=  [idx=index groups=(list (list @t))]
  ^-  (unit (set @ud))
  ?~  groups  ~
  =/  result=(set @ud)  (segments-for-terms idx i.groups)
  ?:  =(~ result)  ~
  =/  rest=(list (list @t))  t.groups
  |-  ^-  (unit (set @ud))
  ?~  rest  `result
  =/  next=(set @ud)  (segments-for-terms idx i.rest)
  ?:  =(~ next)  ~
  =.  result  (~(int in result) next)
  ?:  =(~ result)  ~
  $(rest t.rest)
::
++  segments-for-terms
  |=  [idx=index terms=(list @t)]
  ^-  (set @ud)
  %+  roll  terms
  |=  [term=@t out=(set @ud)]
  =/  segments=(unit (set @ud))  (~(get by directory.idx) term)
  ?~(segments out (~(uni in out) u.segments))
::
++  search-segment
  |=  $:  seg=segment
          live=(map thread (map (unit @ud) @ud))
          groups=(list (list @t))
          after=(unit cursor:gs)
          max=@ud
          allowed=(unit (set scope:gs))
      ==
  ^-  (list hit:gs)
  =/  lists=(list posting)
    %+  turn  groups
    |=  terms=(list @t)
    %+  roll  terms
    |=  [term=@t out=posting]
    =/  posting=(unit posting)  (~(get by postings.seg) term)
    ?~(posting out (uni:on-posting out u.posting))
  ?:  (lien lists |=(posting=posting =(~ posting)))  ~
  =/  base=posting  (least lists)
  =?  base  ?=(^ after)
    (lot:on-posting base ~ after)
  (collect base lists docs.seg live max allowed)
::
::  Exact terms never expand.  A missing term may expand only inside a small
::  two-byte prefix bucket, and only to prefix matches or edit distance one.
::  This gives useful typo completion without a vocabulary-wide query scan.
::
++  candidate-terms
  |=  [idx=index needle=@t]
  ^-  (list @t)
  ?:  (~(has by directory.idx) needle)  [needle ~]
  ?:  (lth (met 3 needle) fuzzy-prefix-size)  ~
  =/  bucket=(unit (set @t))
    (~(get by prefixes.idx) (term-prefix needle))
  ?~  bucket  ~
  =/  matches=(list @t)
    %+  skim  (take-terms u.bucket fuzzy-scan-limit)
    |=  term=@t
    ?:  (prefix-match needle term)  &
    (one-edit needle term)
  (scag fuzzy-limit matches)
::  Do not +tap an unbounded bucket before taking a bounded prefix.
++  take-terms
  |=  [tree=(set @t) limit=@ud]
  ^-  (list @t)
  =/  out=[left=@ud terms=(list @t)]  [limit ~]
  =.  out
    |-  ^+  out
    ?:  |(?=(~ tree) =(0 left.out))  out
    =.  out  $(tree l.tree)
    ?:  =(0 left.out)  out
    =.  out  [(dec left.out) [n.tree terms.out]]
    $(tree r.tree)
  (flop terms.out)
::
++  term-prefix
  |=  term=@t
  ^-  @t
  (cut 3 [0 (min fuzzy-prefix-size (met 3 term))] term)
::
++  prefix-match
  |=  [needle=@t term=@t]
  ^-  ?
  =/  needle-size=@ud  (met 3 needle)
  ?:  (gth needle-size (met 3 term))  |
  =((cut 3 [0 needle-size] term) needle)
::
++  one-edit
  |=  [a=@t b=@t]
  ^-  ?
  =/  aa=tape  (trip a)
  =/  bb=tape  (trip b)
  =/  al=@ud  (lent aa)
  =/  bl=@ud  (lent bb)
  ?:  (gth (sub (max al bl) (min al bl)) 1)  |
  ?:  =(al bl)  (one-substitution aa bb |)
  ?:  (gth al bl)  (one-insertion aa bb |)
  (one-insertion bb aa |)
::
++  one-substitution
  |=  [a=tape b=tape used=?]
  ^-  ?
  ?~  a  =(~ b)
  ?~  b  |
  ?:  =(i.a i.b)  (one-substitution t.a t.b used)
  ?:  used  |
  (one-substitution t.a t.b &)
::
++  one-insertion
  |=  [long=tape short=tape used=?]
  ^-  ?
  ?~  short  ?:(used =(0 (lent long)) =(1 (lent long)))
  ?~  long  |
  ?:  =(i.long i.short)  (one-insertion t.long t.short used)
  ?:  used  |
  (one-insertion t.long short &)
::
++  cursor-gth
  |=  [a=cursor:gs b=cursor:gs]
  ^-  ?
  ?:  =(sent.a sent.b)
    (gth id.a id.b)
  (gth sent.a sent.b)
::
::  Walk a posting treap right-to-left and stop once enough matching
::  documents have been found.
::
++  collect
  |=  $:  tree=posting
          lists=(list posting)
          docs=(map @ud document)
          live=(map thread (map (unit @ud) @ud))
          max=@ud
          allowed=(unit (set scope:gs))
      ==
  ^-  (list hit:gs)
  =/  result=[found=(list hit:gs) left=@ud]
    (walk tree lists docs live allowed [~ max])
  (flop found.result)
::
++  walk
  |=  $:  branch=posting
          lists=(list posting)
          docs=(map @ud document)
          live=(map thread (map (unit @ud) @ud))
          allowed=(unit (set scope:gs))
          state=[found=(list hit:gs) left=@ud]
      ==
  ^+  state
  ?:  =(0 left.state)  state
  ?~  branch  state
  =.  state  (walk r.branch lists docs live allowed state)
  ?:  =(0 left.state)  state
  =/  cursor=cursor:gs  key.n.branch
  =/  matches=?
    %+  levy  lists
    |=  list=posting
    (has:on-posting list cursor)
  =?  state  matches
    =/  doc=(unit document)  (~(get by docs) id.cursor)
    ?~  doc  state
    ?.  ?~(allowed & (~(has in u.allowed) scope.ref.u.doc))  state
    ?.  (is-live live ref.u.doc id.cursor)  state
    :-  [[cursor ref.u.doc sent.cursor author.u.doc ''] found.state]
    (dec left.state)
  ?:  =(0 left.state)  state
  (walk l.branch lists docs live allowed state)
::
++  is-live
  |=  [live=(map thread (map (unit @ud) @ud)) =ref:gs id=@ud]
  ^-  ?
  =/  thread-live=(unit (map (unit @ud) @ud))
    (~(get by live) [scope.ref at.ref])
  ?~  thread-live  |
  =/  current=(unit @ud)  (~(get by u.thread-live) part.ref)
  ?~(current | =(u.current id))
::
++  least
  |=  lists=(list posting)
  ^-  posting
  ?>  ?=(^ lists)
  =/  best=posting  i.lists
  =/  rest=(list posting)  t.lists
  |-  ^+  best
  ?~  rest  best
  ?:  (lth (wyt:on-posting i.rest) (wyt:on-posting best))
    $(best i.rest, rest t.rest)
  $(rest t.rest)
::
++  make-snippet
  |=  texts=(list @t)
  ^-  @t
  ?~  texts  ''
  ?:  =('' i.texts)  $(texts t.texts)
  =/  text=@t  i.texts
  =/  size=@ud  (met 3 text)
  ?:  (lte size 512)  text
  ::  Do not split a UTF-8 continuation sequence.  The first excluded byte
  ::  must either begin a new codepoint or be ASCII.
  =/  length=@ud  512
  |-  ^-  @t
  =/  next=@  (cut 3 [length 1] text)
  ?:  &((gte next 128) (lte next 191))
    $(length (dec length))
  (cat 3 (cut 3 [0 length] text) '...')
--
