::  Human conversation commands: pure parsing, policy changes and replies.
::  Only ingress calls this module. Tool output and model-generated text are
::  never interpreted as commands. No credentials, I/O or execution authority.
/-  h=harness
/+  hp=harness-provider, failure=harness-failure, context=harness-context, memory=harness-memory
|%
+$  command  [name=@t arg=@t]
++  whitespace
  |=(c=@tD |(=(32 c) =(9 c) =(10 c) =(13 c)))
++  trim
  |=  text=tape
  ^-  tape
  =/  left
    |-  ^-  tape
    ?~  text  ~
    ?.((whitespace i.text) text $(text t.text))
  %-  flop
  =/  right  (flop left)
  |-  ^-  tape
  ?~  right  ~
  ?.  (whitespace i.right)  right
  $(right t.right)
++  parse
  |=  text=@t
  ^-  (unit command)
  =/  chars  (trim (trip text))
  ?~  chars  ~
  ?.  =(47 i.chars)  ~
  =/  tail  t.chars
  =|  word=tape
  |-  ^-  (unit command)
  ?:  |(?=(~ tail) (whitespace i.tail))
    ?~  word  ~
    `[(rap 3 (flop word)) (rap 3 (trim tail))]
  ::  Paths, URLs and // escapes are ordinary text, not unknown commands.
  ?.  |(&(=(45 i.tail) !=(~ word)) &((gte i.tail 97) (lte i.tail 122)))  ~
  $(tail t.tail, word [i.tail word])
++  stopping
  |=  text=@t
  =(`[name='stop' arg=''] (parse text))
++  help
  ^-  @t
  %+  rap  3
  :~  '/help — list commands\0a'
      '/status — model, tool grants and token usage\0a'
      '/model — show this conversation\'s model\0a'
      '/model <id> — change model within the current provider\0a'
      '/model default — use the default provider and model\0a'
      '/context — inspect context budgets and checkpoint usage\0a'
      '/compact — summarize older exchanges, keeping the recent turn\0a'
      '/memory — list this conversation\'s pinned notes\0a'
      '/remember <name> <text> — save or replace a pinned note\0a'
      '/forget <name> — unpin a note (does not erase history)\0a'
      '/stop — cancel current and queued work\0a\0a'
      'Only /compact calls a model (to summarize history). '
      'Only /stop interrupts active work. '
      'Model changes preserve instructions and tool permissions.'
  ==
++  context-report
  |=  [v=view:h skills=(map @t skill:h)]
  ^-  @t
  %+  rap  3
  :~  'Context estimate: '  (scot %ud (est-tokens:hp v skills))  ' tokens (encoded bytes / 4, approximate)'
      '\0aConfigured model window: '  (scot %ud max-context.config.v)  ' (catalog or fallback)'
      '\0aInput budget: '  (scot %ud (input-budget:context max-context.config.v))
      '\0aRetained-tail target: '  (scot %ud (tail-budget:context max-context.config.v))  ' (complete exchanges; approximate)'
      '\0aOutput reserve: '  (scot %ud (output-budget:context max-context.config.v))
      '\0aEstimation margin: '  (scot %ud (div max-context.config.v 10))
      '\0aActive items: '  (scot %ud (lent items.v))
      '\0aCheckpoint: '  ?~(summary.v 'none' 'present; source transcript retained')
      '\0aPinned notes: '  (scot %ud (lent ~(tap by memory.v)))  '/16, '  (scot %ud (bytes:memory memory.v))  '/8192 bytes'
      '\0aCompaction tokens: '  (scot %ud prompt.compact-usage.v)  ' input, '
      (scot %ud completion.compact-usage.v)  ' output'
  ==
::  Command effects are nouns, not agent actions. The head records these and
::  the acknowledgement in one admission; all hands get the same semantics.
++  evaluate
  |=  [cmd=command v=view:h defaults=config:h skills=(map @t skill:h)]
  ^-  [events=(list event:h) body=@t]
  ?:  =('context' name.cmd)
    [~ ?:(=('' arg.cmd) (context-report v skills) 'Usage: /context')]
  ?:  =('compact' name.cmd)  [~ 'Usage: /compact']
  ?:  =('memory' name.cmd)
    ?.  =('' arg.cmd)  [~ 'Usage: /memory']
    [~ ?~(memory.v 'No pinned notes. Use /remember <name> <text> to save one for this conversation.' (cat 3 'Pinned notes (this conversation only):\0a' (render:memory memory.v)))]
  ?:  |(=('remember' name.cmd) =('forget' name.cmd))
    =/  chars  (trip arg.cmd)
    =/  split=[key=tape rest=tape]
      =|  key=tape
      |-  ^-  [key=tape rest=tape]
      ?:  |(?=(~ chars) (whitespace i.chars))
        [(flop key) (trim chars)]
      $(chars t.chars, key [i.chars key])
    ?:  |(=(~ key.split) &(=('remember' name.cmd) =(~ rest.split)) &(=('forget' name.cmd) !=(~ rest.split)))
      [~ ?:(=('remember' name.cmd) 'Usage: /remember <name> <text>' 'Usage: /forget <name>')]
    =/  result
      (edit:memory memory.v (crip key.split) ?:(=('forget' name.cmd) ~ `(crip rest.split)))
    ?:  ?=(%| -.result)  [~ p.result]
    [~[p.result] ?:(=('forget' name.cmd) 'Note unpinned. Earlier messages and checkpoints are not erased.' 'Note saved for this conversation. It stays pinned across compaction.')]
  =/  result  (run cmd v defaults)
  [?~(config.result ~ ~[[%config-replaced u.config.result]]) body.result]
++  model-label
  |=  cfg=config:h
  (rap 3 (provider-for-url:hp url.cfg) ' / ' model.cfg ~)
++  run
  |=  [cmd=command v=view:h defaults=config:h]
  ^-  [config=(unit config:h) body=@t]
  ?+  name.cmd  [~ 'Unknown command. Send /help for the available commands.']
    %help  [~ ?:(=('' arg.cmd) help 'Usage: /help')]
    %stop  [~ ?:(=('' arg.cmd) 'Stopped. External actions already started may still have taken effect.' 'Usage: /stop')]
  ::
      %status
    ?.  =('' arg.cmd)  [~ 'Usage: /status']
    :-  ~
    %+  rap  3
    :~  'Model: '  (model-label config.v)
        '\0aTool grants: '  (scot %ud (lent tools.config.v))
        '\0aRecorded tokens: '  (scot %ud prompt.total.v)  ' input, '
        (scot %ud completion.total.v)  ' output'
        ?~(err.v '' (cat 3 '\0aLast failure: ' (public-message:failure u.err.v)))
    ==
  ::
      %model
    ?:  =('' arg.cmd)  [~ (cat 3 'Model: ' (model-label config.v))]
    =/  cfg=config:h  config.v
    ?:  =('default' arg.cmd)
      =.  cfg  cfg(url url.defaults, model model.defaults, key '', headers headers.defaults, max-context max-context.defaults)
      [`cfg (cat 3 'Using default model: ' (model-label cfg))]
    ?:  |((gth (met 3 arg.cmd) 256) (lien (trip arg.cmd) whitespace))
      [~ 'Usage: /model <model-id> or /model default']
    ::  Keep a known context size for the same model. A typed, uncatalogued
    ::  model gets the same conservative fallback as the settings client.
    =.  cfg  cfg(model arg.cmd, max-context ?:(=(arg.cmd model.cfg) max-context.cfg 80.000))
    [`cfg (cat 3 'Model set to: ' (model-label cfg))]
  ==
++  advertised
  ^-  json
  %-  pairs:enjs:format
  :~  ['sessionUpdate' %s 'available_commands_update']
      :-  'availableCommands'
      :-  %a
      %+  turn
        ^-  (list [name=@t description=@t hint=@t])
        :~  ['help' 'List conversation commands' '']
            ['status' 'Show model, tool grants and token usage' '']
            ['model' 'Show or change this conversation\'s model' 'model-id | default']
            ['context' 'Inspect context budgets and checkpoint usage' '']
            ['compact' 'Summarize older exchanges using the current provider' '']
            ['memory' 'List this conversation\'s pinned notes' '']
            ['remember' 'Save or replace a conversation note' 'name text']
            ['forget' 'Unpin a note without erasing history' 'name']
            ['stop' 'Cancel current and queued work' '']
        ==
      |=  [name=@t description=@t hint=@t]
      %-  pairs:enjs:format
      %+  weld  ~[['name' %s name] ['description' %s description]]
      ?:  =('' hint)  ~
      ~[['input' (pairs:enjs:format ~[['hint' %s hint]])]]
  ==
--
