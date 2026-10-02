::  Native Messages JSON and SSE. Transport, credentials and session state
::  remain outside this codec; signed thinking blocks are opaque continuations.
/+  w=harness-provider-wire, failure=harness-failure
|%
++  request
  |=  chat=json
  ^-  json
  =/  messages  (need (get:w chat 'messages'))
  ?>  ?=(%a -.messages)
  =/  system
    %+  rap  3
    %+  murn  p.messages
    |=  message=json
    ?.  =('system' (str:w message 'role'))  ~
    `(cat 3 (str:w message 'content') '\0a\0a')
  =/  ordinary
    (skim p.messages |=(message=json !=('system' (str:w message 'role'))))
  =/  base=json
    %-  pairs:enjs:format
    :~  ['model' (need (get:w chat 'model'))]
        ['system' %s system]
        ['messages' %a (group (turn ordinary message))]
        ['max_tokens' (need (get:w chat 'max_tokens'))]
        ['stream' %b &]
    ==
  =/  tools  (get:w chat 'tools')
  ?.  ?=([~ %a *] tools)  base
  %^  put:w  base  'tools'
  :-  %a
  %+  turn  p.u.tools
  |=  entry=json
  =/  function  (need (get:w entry 'function'))
  %-  pairs:enjs:format
  :~  ['name' (need (get:w function 'name'))]
      ['description' (need (get:w function 'description'))]
      ['input_schema' (need (get:w function 'parameters'))]
  ==
::
++  message
  |=  chat=json
  ^-  json
  =/  role  (str:w chat 'role')
  =/  content  (get:w chat 'content')
  ::  A matching continuation already contains the exact native block order.
  ?:  ?=([~ %a *] content)
    (pairs:enjs:format ~[['role' %s role] ['content' u.content]])
  =/  blocks=(list json)
    ?:  =('tool' role)
      :_  ~
      %-  pairs:enjs:format
      :~  ['type' %s 'tool_result']
          ['tool_use_id' (need (get:w chat 'tool_call_id'))]
          ['content' %s (str:w chat 'content')]
      ==
    =/  text  (str:w chat 'content')
    ?:(=('' text) ~ ~[(pairs:enjs:format ~[['type' %s 'text'] ['text' %s text]])])
  =/  calls  (get:w chat 'tool_calls')
  =?  blocks  ?=([~ %a *] calls)
    %+  weld  blocks
    %+  turn  p.u.calls
    |=  call=json
    =/  function  (need (get:w call 'function'))
    =/  input  (need (de:json:html (str:w function 'arguments')))
    ?>  ?=(%o -.input)
    %-  pairs:enjs:format
    :~  ['type' %s 'tool_use']
        ['id' (need (get:w call 'id'))]
        ['name' (need (get:w function 'name'))]
        ['input' input]
    ==
  %-  pairs:enjs:format
  :~  ['role' %s ?:(=('tool' role) 'user' role)]
      ['content' %a blocks]
  ==
::  Parallel tool results belong to one user message, immediately after the
::  assistant's tool-use blocks. Adjacent user context follows those results.
::
++  group
  |=  messages=(list json)
  ^-  (list json)
  ?~  messages  ~
  ?~  t.messages  messages
  ?.  =((str:w i.messages 'role') (str:w i.t.messages 'role'))
    [i.messages $(messages t.messages)]
  =/  first  (need (get:w i.messages 'content'))
  =/  second  (need (get:w i.t.messages 'content'))
  ?>  &(?=(%a -.first) ?=(%a -.second))
  =/  joined  (put:w i.messages 'content' [%a (weld p.first p.second)])
  $(messages [joined t.t.messages])
::
++  stream-text
  |=  body=@t
  ^-  @t
  %+  rap  3
  %+  turn  (events:w body)
  |=  event=json
  ?:  =('content_block_start' (str:w event 'type'))
    =/  block  (fall (get:w event 'content_block') ~)
    ?:(=('text' (str:w block 'type')) (str:w block 'text') '')
  ?.  =('content_block_delta' (str:w event 'type'))  ''
  =/  delta  (fall (get:w event 'delta') ~)
  ?:(=('text_delta' (str:w delta 'type')) (str:w delta 'text') '')
::  Collect complete blocks, including streamed signatures and tool arguments.
::  Require message_stop and closed blocks before accepting any tool calls.
::
++  response
  |=  body=@t
  ^-  json
  =/  direct  (de:json:html body)
  ?^  direct  u.direct
  |^
  =/  events  (events:w body)
  =/  collected  (roll events collect-event)
  ?^  error.collected
    (pairs:enjs:format ~[['error' %s u.error.collected]])
  ?>  ?&  =(~ opened.collected)
          (lien events |=(event=json =('message_stop' (str:w event 'type'))))
      ==
  =/  ordered
    %+  sort  ~(tap by blocks.collected)
    |=  [a=[@ud json] b=[@ud json]]
    (lth -.a -.b)
  %^  put:w  message.collected  'content'
  [%a (turn ordered |=([index=@ud block=json] block))]
  ::
  +$  stream
    $:  message=json
        blocks=(map @ud json)
        arguments=(map @ud @t)
        opened=(set @ud)
        error=(unit @t)
    ==
  ::
  ++  collect-event
    |=  [event=json collected=stream]
    ^-  stream
    =/  error  (wire-error:failure event)
    ?^  error  collected(error error)
    =/  type  (str:w event 'type')
    ?:  =('message_start' type)
      collected(message (need (get:w event 'message')))
    ?:  =('message_delta' type)
      =/  message  (merge:w message.collected (need (get:w event 'delta')))
      =/  usage  (get:w event 'usage')
      =?  message  ?=(^ usage)
        %^  put:w  message  'usage'
        (merge:w (fall (get:w message 'usage') [%o ~]) u.usage)
      collected(message message)
    =/  index  (num:w event 'index')
    ?:  =('content_block_start' type)
      %=  collected
        blocks   (~(put by blocks.collected) index (need (get:w event 'content_block')))
        opened   (~(put in opened.collected) index)
      ==
    ?.  |(=('content_block_delta' type) =('content_block_stop' type))
      collected
    ?>  (~(has in opened.collected) index)
    ?:  =('content_block_stop' type)
      (close-block index collected)
    (collect-delta index (need (get:w event 'delta')) collected)
  ::  Tool arguments are JSON fragments until their block closes. Parse the
  ::  assembled object once and retain the block's native position.
  ::
  ++  close-block
    |=  [index=@ud collected=stream]
    ^-  stream
    =/  block  (~(got by blocks.collected) index)
    =/  input  (~(get by arguments.collected) index)
    =?  block  ?=(^ input)
      =/  parsed  (need (de:json:html u.input))
      ?>  ?=(%o -.parsed)
      (put:w block 'input' parsed)
    %=  collected
      blocks  (~(put by blocks.collected) index block)
      opened  (~(del in opened.collected) index)
    ==
  ::
  ++  collect-delta
    |=  [index=@ud delta=json collected=stream]
    ^-  stream
    =/  type  (str:w delta 'type')
    ?:  =('input_json_delta' type)
      =/  prior  (fall (~(get by arguments.collected) index) '')
      =/  joined  (cat 3 prior (str:w delta 'partial_json'))
      collected(arguments (~(put by arguments.collected) index joined))
    =/  field=@t
      ?+  type  ''
        %'text_delta'       'text'
        %'thinking_delta'   'thinking'
        %'signature_delta'  'signature'
      ==
    ?:  =('' field)  collected
    =/  block  (~(got by blocks.collected) index)
    =/  joined  (append:w block field (str:w delta field))
    collected(blocks (~(put by blocks.collected) index joined))
  --
::  Project native output into the common chat decoder without exposing
::  thinking. The original content array is stored separately for replay.
::
++  chat-response
  |=  message=json
  ^-  json
  =/  error  (wire-error:failure message)
  ?^  error  (pairs:enjs:format ~[['error' %s u.error]])
  ?>  =('message' (str:w message 'type'))
  =/  content  (need (get:w message 'content'))
  ?>  ?=(%a -.content)
  =/  text
    %+  rap  3
    %+  turn  p.content
    |=  block=json
    ?:(=('text' (str:w block 'type')) (str:w block 'text') '')
  =/  calls
    %+  murn  p.content
    |=  block=json
    ^-  (unit json)
    ?.  =('tool_use' (str:w block 'type'))  ~
    =/  input  (need (get:w block 'input'))
    ?>  ?&  ?=(%o -.input)
            !=('' (str:w block 'id'))
            !=('' (str:w block 'name'))
        ==
    :-  ~
    %-  pairs:enjs:format
    :~  ['id' (need (get:w block 'id'))]
        ['type' %s 'function']
        :-  'function'
        %-  pairs:enjs:format
        :~  ['name' (need (get:w block 'name'))]
            ['arguments' %s (en:json:html input)]
        ==
    ==
  =/  stop  (str:w message 'stop_reason')
  ?>  !=('' stop)
  ?>  |(!=('' text) !=(~ calls) =('max_tokens' stop))
  =/  finish=@t
    ?:  =('tool_use' stop)  'tool_calls'
    ?:  =('max_tokens' stop)  'length'
    ?:  (lien `(list @t)`~['end_turn' 'stop_sequence' 'refusal'] |=(s=@t =(s stop)))  'stop'
    'error'
  ::  Do not execute a tool whose generation ends at the output limit.
  ?>  |(=(~ calls) =('tool_use' stop))
  =/  usage  (fall (get:w message 'usage') [%o ~])
  =/  input
    ;:  add
      (num:w usage 'input_tokens')
      (num:w usage 'cache_read_input_tokens')
      (num:w usage 'cache_creation_input_tokens')
    ==
  =/  assistant
    %-  pairs:enjs:format
    :~  ['role' %s 'assistant']
        ['content' %s text]
        ['tool_calls' %a calls]
    ==
  =/  choice
    (pairs:enjs:format ~[['finish_reason' %s finish] ['message' assistant]])
  %-  pairs:enjs:format
  :~  ['choices' %a ~[choice]]
      :-  'usage'
      %-  pairs:enjs:format
      :~  ['prompt_tokens' (numb:enjs:format input)]
          ['completion_tokens' (numb:enjs:format (num:w usage 'output_tokens'))]
      ==
  ==
::
++  continuation
  |=  message=json
  ^-  @t
  =/  content  (get:w message 'content')
  ?.  ?=([~ %a *] content)  ''
  =/  thinking
    %+  lien  p.u.content
    |=  block=json
    |(=('thinking' (str:w block 'type')) =('redacted_thinking' (str:w block 'type')))
  ?.  thinking  ''
  ?>  %+  levy  p.u.content
      |=  block=json
      ?:  =('thinking' (str:w block 'type'))  !=('' (str:w block 'signature'))
      ?:  =('redacted_thinking' (str:w block 'type'))  !=('' (str:w block 'data'))
      &
  (en:json:html (pairs:enjs:format ~[['content' u.content]]))
--
