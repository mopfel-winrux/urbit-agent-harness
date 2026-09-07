/-  h=harness
/+  *test, hs=harness-session
|%
++  test-pages-preserve-addresses
  =/  log=(list event:h)
    (turn (gulf 1 95) |=(n=@ud `event:h`[%command-completed `@uv`n 'fixture' 'reply']))
  =/  ses=session:h  [log 1]
  =/  recent  (history:hs ses ~)
  =/  older  (history:hs ses `56)
  =/  first  (history:hs ses `16)
  ;:  weld
    (expect-eq !>(before.recent) !>(`json`[%n '56']))
    (expect-eq !>(before.older) !>(`json`[%n '16']))
    (expect-eq !>(before.first) !>(`json`~))
    (expect-eq !>(entries:(history:hs ses `0)) !>(`json`[%a ~]))
  ==
++  test-cancellation-receipts-stay-together
  =/  tail=(list event:h)
    :~  [%cancelled ~ (silt ~['a' 'b']) 'cancelled by client']
        [%llm-completed 0 %tool-calls [1 1] [%assistant '' ~[['a' 'http_fetch' '{}'] ['b' 'http_fetch' '{}']]]]
    ==
  =/  log  (weld (turn (gulf 1 39) |=(n=@ud `event:h`[%command-completed `@uv`n 'fixture' 'reply'])) tail)
  =/  page  (history:hs [log 1] ~)
  ?>  ?=(%a -.entries.page)
  ;:  weld
    (expect-eq !>((lent p.entries.page)) !>(41))
    (expect-eq !>(before.page) !>(`json`[%n '2']))
  ==
--
