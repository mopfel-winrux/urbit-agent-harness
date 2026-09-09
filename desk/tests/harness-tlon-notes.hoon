/-  n=tlon-notes, s=tlon-story, d=tlon-channels-ver
/+  *test, imports=harness-tlon-notes-import, md=harness-tlon-notes-markdown, migration=harness-tlon-notes-migration, notes=harness-tlon-notes-tool, spec=harness-tlon-tool
|%
++  args
  |=  raw=@t
  (pairs:enjs:format ~[['tree' %s raw]])
++  test-import-flat-and-tree
  =/  tree  (tree:imports (args '[{"type":"note","title":"First","text":""},{"type":"folder","title":"Folder","children":[{"type":"note","title":"Nested","text":"Body"}]}]'))
  (expect-eq !>([2 1 4]) !>((sizes:imports tree)))
++  test-import-rejects-malformed-or-lossy-payload
  =/  bad=(list @t)
    :~  '[]'  '{}'  '[{"type":"note","title":"A"}]'
        '[{"type":"note","title":"A","text":3}]'
        '[{"type":"note","title":"A","text":"body","typo":"lost"}]'
        '[{"type":"folder","title":"..","children":[]}]'
        '[{"type":"folder","title":"A","children":{}}]'
        '[{"type":"unknown","title":"A"}]'
    ==
  (expect !>((levy bad |=(raw=@t =(~ (mole |.((tree:imports (args raw)))))))))
++  test-import-node-cap
  =/  value=json  [%a (reap 101 (need (de:json:html '{"type":"note","title":"A","text":""}')))]
  (expect !>(=(~ (mole |.((tree:imports (args (en:json:html value))))))))
++  test-import-depth-cap
  =/  value=json  [%a ~[[%o (~(put by *(map @t json)) 'unused' ~)]]]
  (expect !>(=(~ (mole |.((nodes:imports value 9 0))))))
++  test-notes-role-parsing-is-strict
  =/  lib  ~(. notes *bowl:gall)
  =/  bad=(list @t)  ~['{}' '[3]' '["admin","admin"]' '["not a role"]']
  (expect !>((levy bad |=(raw=@t =(~ (mole |.((readers:lib (pairs:enjs:format ~[['readers' %s raw]])))))))))
++  test-group-nest-notes-is-not-a-message-destination
  =/  nest  (group-nest:spec 'notes/~lux/book')
  (expect !>(&(=(%notes kind.nest) =(~ (mole |.((nest:spec 'notes/~lux/book')))))))
++  test-migration-widening
  =/  lib  ~(. migration *bowl:gall)
  (expect !>(&((widening:lib ~ (silt ~[%editors]) ~ |) (widening:lib ~ ~ ~ &) (widening:lib (silt ~[%readers]) (silt ~[%editors]) ~ |) !(widening:lib (silt ~[%editors]) (silt ~[%editors]) ~ |) !(widening:lib (silt ~[%admins]) (silt ~[%editors]) (silt ~[%admins]) |) !(widening:lib ~ ~ ~ |))))
++  test-markdown-preserves-rich-content
  =/  value=story:s
    :~  [%block %header %h2 ~['Heading']]
        [%inline ~[[%bold ~['bold']] ' ' [%italics ~['italic']] [%tag 'tag'] [%block 1 'reference'] [%sect ~] [%task & ~['task']]]]
        [%block %image 'https://example.com/a.png' 1 1 'alt']
        [%block %listing %list %ordered ~[[%item ~['one']] [%item ~['two']]] ~]
        [%block %code '```\0aexample' 'hoon']
    ==
  =/  out  (markdown:md value)
  =/  expected=(list @t)  ~['## Heading' '**bold**' '*italic*' 'reference' 'tag' '@all' '[x] task' '![alt](https://example.com/a.png)' '1. one' '````hoon']
  (expect !>((levy expected |=(part=@t ?=(^ (find (trip part) (trip out)))))))
++  test-markdown-escapes-prose-and-url-delimiters
  (expect !>(&(=('&lt;script&gt;' (escape:md '<script>')) =('https://example.com/a%28b%29' (url:md 'https://example.com/a(b)')) =(~ (mole |.((url:md 'https://example.com/\0abad')))))))
++  test-migration-records-attribution-and-source
  =/  lib  ~(. migration *bowl:gall)
  =/  post=post:v10:d  *post:v10:d
  =.  post  post(id ~2026.9.9, seq 1, sent ~2026.9.9, author ~lux, content ~[[%inline ~['Body']]])
  =/  note  (converted:lib 'diary/~lux/source' post)
  (expect !>(&(?=(^ (find "Originally posted by ~lux" (trip body.note))) ?=(^ (find "/1/chan/diary/~lux/source/note/" (trip body.note))) ?=(^ (find (trip marker.note) (trip body.note))))))
++  test-migration-rejects-unknown-payload
  =/  lib  ~(. migration *bowl:gall)
  =/  post=post:v10:d  *post:v10:d
  =.  post  post(blob `'custom')
  (expect !>(=(~ (mole |.((converted:lib 'diary/~lux/source' post))))))
++  test-migration-provenance-is-a-complete-final-line
  =/  lib  ~(. migration *bowl:gall)
  =/  marker  '<!-- harness-notes-migrate: diary/~lux/source 123 -->'
  (expect !>(&(=(`marker (provenance:lib (cat 3 'body\0a' marker))) =(~ (provenance:lib (cat 3 marker '\0aunrelated'))))))
--
