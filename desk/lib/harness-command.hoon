::  Human conversation commands: pure parsing, policy changes and replies.
::  Only ingress calls this module. Tool output and model-generated text are
::  never interpreted as commands. No credentials, I/O or execution authority.
/-  h=harness
/+  hp=harness-provider, failure=harness-failure
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
      '/stop — cancel current and queued work\0a\0a'
      'Commands run on the ship without calling a model. '
      'Only /stop interrupts active work. '
      'Model changes preserve instructions and tool permissions.'
  ==
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
            ['stop' 'Cancel current and queued work' '']
        ==
      |=  [name=@t description=@t hint=@t]
      %-  pairs:enjs:format
      %+  weld  ~[['name' %s name] ['description' %s description]]
      ?:  =('' hint)  ~
      ~[['input' (pairs:enjs:format ~[['hint' %s hint]])]]
  ==
--
