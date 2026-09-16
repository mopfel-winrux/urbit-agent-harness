/-  hooks=tlon-hooks
/+  *test, html=harness-tlon-publish-html, hook=harness-tlon-hook-tool, publishing=harness-tlon-publish-tool
|%
++  test-public-html-escapes-note-and-title
  =/  page  (page:html '<script>title</script>' '<img src=x onerror=alert(1)>' ~)
  (expect !>(&(?=(^ (find "&lt;script&gt;title&lt;/script&gt;" (trip page))) ?=(^ (find "&lt;img" (trip page))) =(~ (find "<script>" (trip page))))))
++  test-public-html-allows-formatting-and-safe-links
  =/  raw  '<h2>Heading</h2><p><strong>Bold</strong> <a href="https://example.com">link</a></p><br/>'
  (expect !>(?=(^ (mole |.((page:html 'Title' '' `raw))))))
++  test-public-html-rejects-active-content
  =/  samples=(list @t)
    :~  '<script>alert(1)</script>'
        '<img src="https://example.com/p.png" onerror="alert(1)"/>'
        '<a href="javascript:alert(1)">x</a>'
        '<a href="javascript&#58;alert(1)">x</a>'
        '<form action="https://example.com"><input/></form>'
        '<iframe src="https://example.com"></iframe>'
        '<svg><script>alert(1)</script></svg>'
        '<p style="display:none">x</p>'
        '<meta http-equiv="refresh" content="0;url=https://example.com"/>'
    ==
  (expect !>((levy samples |=(raw=@t =(~ (mole |.((page:html 'Title' '' `raw))))))))
++  test-public-citations-reject-replies-and-arbitrary-desks
  =/  lib  ~(. publishing *bowl:gall)
  =/  bad=(list @t)  ~['/1/desk/~lux/base/file' '/1/group/~lux/test' '/1/chan/chat/~lux/test/msg/1/2' '/1/chan/notes/~lux/test/note/1' '/1/chan/chat/~lux/test/msg/001' '/1/chan/chat/~lux/test/msg/123.456']
  (expect !>((levy bad |=(raw=@t =(~ (mole |.((reference:lib (pairs:enjs:format ~[['citation' %s raw]])))))))))
++  test-public-citations-allow-root-channel-posts
  =/  lib  ~(. publishing *bowl:gall)
  =/  good=(list @t)  ~['/1/chan/chat/~lux/test/msg/123456' '/1/chan/diary/~lux/test/note/1' '/1/chan/heap/~lux/test/curio/1']
  (expect !>((levy good |=(raw=@t ?=(^ (mole |.((reference:lib (pairs:enjs:format ~[['citation' %s raw]])))))))))
++  test-history-message-target-becomes-native-citation
  =/  lib  ~(. publishing *bowl:gall)
  =/  args  (pairs:enjs:format ~[['channel' %s 'chat/~lux/test'] ['message_id' %s (scot %da ~2026.9.9)]])
  =/  ref  (reference:lib args)
  ?>  ?=([%chan * %msg @ ~] ref)
  (expect-eq !>((crip (a-co:co ~2026.9.9))) !>(i.t.wer.ref))
++  test-hook-ids-and-config-are-typed
  =/  lib  ~(. hook *bowl:gall)
  =/  config  (config:lib (pairs:enjs:format ~[['config' %s '{"emoji":"ok","delay":"~m1"}']]))
  (expect !>(&(=('ok' (~(got by config) 'emoji')) =(~ (mole |.((identifier:lib '123')))) =(~ (mole |.((config:lib (pairs:enjs:format ~[['config' %s '{"number":3}']]))))))))
++  test-hook-compilation-failure-is-not-success
  =/  lib  ~(. hook *bowl:gall)
  =/  args  (pairs:enjs:format ~[['action' %s 'add_hook'] ['title' %s 'Fixture'] ['source' %s 'bad']])
  =/  reply=response:hooks  [%set 0v1 'Fixture' 'bad' ['' '' '' ''] `~[leaf+"bad source"]]
  =/  result  (response:lib args reply)
  (expect !>(?&(?=(^ result) =('failed:' (end [3 7] u.result)))))
++  test-hook-stop-response-must-match-origin
  =/  lib  ~(. hook *bowl:gall)
  =/  args  (pairs:enjs:format ~[['action' %s 'stop_hook'] ['hook_id' %s '0v1'] ['channel' %s 'chat/~lux/test']])
  =/  wrong  (response:lib args [%rest 0v1 ~])
  =/  right  (response:lib args [%rest 0v1 [%chat ~lux %test]])
  (expect !>(&(=(~ wrong) ?=(^ right))))
--
