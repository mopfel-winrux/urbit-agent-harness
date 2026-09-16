/-  h=harness
/+  *test, mem=harness-memory, cmd=harness-command, hl=harness, hp=harness-provider, hs=harness-session, ctx=harness-context, policy=harness-defaults
|%
++  fixture
  ^-  view:h
  =/  v=view:h  *view:h
  v(config builtin-config:policy)
++  test-names-and-body-bounds
  =/  invalid  (edit:mem ~ '../other' `'text')
  =/  empty  (edit:mem ~ 'name' `'')
  =/  large  (edit:mem ~ 'name' `(rap 3 (reap 1.025 'x')))
  =/  exact  (edit:mem ~ 'name' `(rap 3 (reap 1.024 'x')))
  (expect !>(&(?=(%| -.invalid) ?=(%| -.empty) ?=(%| -.large) ?=(%& -.exact))))
++  test-map-size-and-replacement
  =/  notes=(map @t @t)
    %-  ~(gas by *(map @t @t))
    (turn (gulf 0 15) |=(n=@ud [(scot %ud n) 'note']))
  =/  full  (edit:mem notes 'extra' `'note')
  =/  update  (edit:mem notes '0' `'replacement')
  (expect !>(&(?=(%| -.full) ?=(%& -.update) =(16 (lent ~(tap by notes))))))
++  test-total-bytes-includes-names-and-utf-eight
  =/  notes=(map @t @t)
    %-  ~(gas by *(map @t @t))
    (turn (gulf 0 7) |=(n=@ud [(scot %ud n) (rap 3 (reap 1.023 'x'))]))
  =/  full  (edit:mem notes 'extra' `'x')
  =/  unicode  (~(put by *(map @t @t)) 'a' 'é')
  (expect !>(&(=(8.192 (bytes:mem notes)) ?=(%| -.full) =(3 (bytes:mem unicode)))))
++  test-command-admission-and-replay
  =/  result  (evaluate:cmd ['remember' 'project Keep it small.'] fixture builtin-config:policy ~)
  =/  log=(list event:h)
    [[%command-completed 0v1 'remember' body.result] (weld (flop events.result) `(list event:h)`~[[%config-replaced builtin-config:policy]])]
  =/  v  (play:hl log)
  (expect !>(&(=(`'Keep it small.' (~(get by memory.v) 'project')) =(~ (next:hs v ~)) =([0 0] total.v))))
++  test-inspection-forgetting-and-invalid-commands
  =/  v  fixture
  =.  v  v(memory (~(put by *(map @t @t)) 'project' 'Keep it small.'))
  =/  read  (evaluate:cmd ['memory' ''] v builtin-config:policy ~)
  =/  forget  (evaluate:cmd ['forget' 'project'] v builtin-config:policy ~)
  =/  invalid  (evaluate:cmd ['forget' 'project extra'] v builtin-config:policy ~)
  =/  missing  (evaluate:cmd ['remember' 'project'] v builtin-config:policy ~)
  =/  result  (play:hl (weld (flop events.forget) `(list event:h)`~[[%memory-set 'project' `'Keep it small.']]))
  (expect !>(&(=(~ events.read) !=('' body.read) =(~ memory.result) =(~ events.invalid) =(~ events.missing))))
++  test-memory-is-session-scoped-and-forked-with-history
  =/  log=(list event:h)
    ~[[%command-completed 0v1 'remember' 'saved'] [%memory-set 'project' `'Keep it small.'] [%config-replaced builtin-config:policy]]
  =/  branch  (branch:hs 'source' [log 0] 3)
  ?>  ?=(%& -.branch)
  =/  v  (play:hl log.p.branch)
  =/  separate  (play:hl ~[[%config-replaced builtin-config:policy]])
  (expect !>(&(=(`'Keep it small.' (~(get by memory.v) 'project')) =(~ memory.separate))))
++  test-memory-is-excluded-from-summary-but-counted-in-turn
  =/  v  fixture
  =/  noted  v(memory (~(put by *(map @t @t)) 'project' (rap 3 (reap 512 'x'))))
  (expect !>(&(=((payload:hp v %compaction ~) (payload:hp noted %compaction ~)) (gth (est-tokens:hp noted ~) (est-tokens:hp v ~)))))
++  test-notes-survive-checkpoints-verbatim
  =/  log=(list event:h)
    ~[[%input-admitted [%user 'current']] [%llm-completed 1 %stop [0 0] [%assistant 'recent answer' ~]] [%input-admitted [%user 'recent']] [%llm-completed 0 %stop [0 0] [%assistant 'older answer that can be summarized' ~]] [%input-admitted [%user 'older']] [%memory-set 'project' `'Keep it small.'] [%config-replaced builtin-config:policy]]
  =/  v  (play:hl log)
  =/  plan  (plan:ctx v (lent log) ~ |=(view:h 1))
  ?>  ?=(%& -.plan)
  =/  compacted  (play:hl [[%checkpoint-completed 2 'Small' [1 1] ~] [%compaction-planned 2 p.plan] log])
  (expect-eq !>(memory.v) !>(memory.compacted))
++  test-responses-keeps-notes-at-user-authority
  =/  v  fixture
  =.  v  v(url.config 'https://chatgpt.com/backend-api/codex/responses', memory (~(put by *(map @t @t)) 'project' 'Keep it small.'))
  =/  body  (payload:hp v %turn ~)
  ?>  ?=(%o -.body)
  =/  input  (need (~(get by p.body) 'input'))
  ?>  ?=(%a -.input)
  =/  expected  (responses-message:hp 'user' (reference:mem memory.v))
  (expect !>((lien p.input |=(entry=json =(entry expected)))))
--
