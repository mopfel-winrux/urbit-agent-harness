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
    |=  msg=json
    ?.(=('system' (str:w msg 'role')) ~ `(cat 3 (str:w msg 'content') '\0a\0a'))
  =/  ordinary
    (skim p.messages |=(msg=json !=('system' (str:w msg 'role'))))
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
  =/  fun  (need (get:w entry 'function'))
  (pairs:enjs:format ~[['name' (need (get:w fun 'name'))] ['description' (need (get:w fun 'description'))] ['input_schema' (need (get:w fun 'parameters'))]])
++  message
  |=  msg=json
  ^-  json
  =/  role  (str:w msg 'role')
  =/  content  (get:w msg 'content')
  ::  A matching continuation already contains the exact native block order.
  ?:  ?=([~ %a *] content)
    (pairs:enjs:format ~[['role' %s role] ['content' u.content]])
  =/  blocks=(list json)
    ?:  =('tool' role)
      ~[(pairs:enjs:format ~[['type' %s 'tool_result'] ['tool_use_id' (need (get:w msg 'tool_call_id'))] ['content' %s (str:w msg 'content')]])]
    =/  text  (str:w msg 'content')
    ?:(=('' text) ~ ~[(pairs:enjs:format ~[['type' %s 'text'] ['text' %s text]])])
  =/  calls  (get:w msg 'tool_calls')
  =?  blocks  ?=([~ %a *] calls)
    %+  weld  blocks
    %+  turn  p.u.calls
    |=  call=json
    =/  fun  (need (get:w call 'function'))
    =/  input  (need (de:json:html (str:w fun 'arguments')))
    ?>  ?=(%o -.input)
    (pairs:enjs:format ~[['type' %s 'tool_use'] ['id' (need (get:w call 'id'))] ['name' (need (get:w fun 'name'))] ['input' input]])
  (pairs:enjs:format ~[['role' %s ?:(=('tool' role) 'user' role)] ['content' %a blocks]])
::  Parallel tool results belong to one user message, immediately after the
::  assistant's tool-use blocks. Adjacent user context follows those results.
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
  $(messages [(put:w i.messages 'content' [%a (weld p.first p.second)]) t.t.messages])
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
++  response
  |=  body=@t
  ^-  json
  =/  direct  (de:json:html body)
  ?^  direct  u.direct
  =/  collected
    %+  roll  (events:w body)
    |=  [event=json acc=[msg=json blocks=(map @ud json) args=(map @ud @t) opened=(set @ud) error=(unit @t)]]
    ^+  acc
    =/  err  (wire-error:failure event)
    ?^  err  acc(error err)
    =/  type  (str:w event 'type')
    ?:  =('message_start' type)  acc(msg (need (get:w event 'message')))
    ?:  =('message_delta' type)
      =/  next  (merge:w msg.acc (need (get:w event 'delta')))
      =/  usage  (get:w event 'usage')
      ?~  usage  acc(msg next)
      acc(msg (put:w next 'usage' (merge:w (fall (get:w next 'usage') [%o ~]) u.usage)))
    =/  at  (num:w event 'index')
    ?:  =('content_block_start' type)
      acc(blocks (~(put by blocks.acc) at (need (get:w event 'content_block'))), opened (~(put in opened.acc) at))
    ?.  |(=('content_block_delta' type) =('content_block_stop' type))  acc
    ?>  (~(has in opened.acc) at)
    =/  block  (~(got by blocks.acc) at)
    ?:  =('content_block_stop' type)
      =/  input  (~(get by args.acc) at)
      =?  block  ?=(^ input)
        =/  parsed  (need (de:json:html u.input))
        ?>  ?=(%o -.parsed)
        (put:w block 'input' parsed)
      acc(blocks (~(put by blocks.acc) at block), opened (~(del in opened.acc) at))
    =/  delta  (need (get:w event 'delta'))
    =/  kind  (str:w delta 'type')
    ?:  =('input_json_delta' kind)
      acc(args (~(put by args.acc) at (cat 3 (fall (~(get by args.acc) at) '') (str:w delta 'partial_json'))))
    =/  field=@t
      ?+  kind  ''
        %'text_delta'       'text'
        %'thinking_delta'   'thinking'
        %'signature_delta'  'signature'
      ==
    ?:  =('' field)  acc
    acc(blocks (~(put by blocks.acc) at (append:w block field (str:w delta field))))
  ?^  error.collected
    (pairs:enjs:format ~[['error' %s u.error.collected]])
  ?>  &((lien (events:w body) |=(event=json =('message_stop' (str:w event 'type')))) =(~ opened.collected))
  =/  ordered
    (sort ~(tap by blocks.collected) |=([a=[@ud json] b=[@ud json]] (lth -.a -.b)))
  (put:w msg.collected 'content' [%a (turn ordered |=([at=@ud block=json] block))])
::  Project native output into the common chat decoder without exposing
::  thinking. The original content array is stored separately for replay.
++  chat-response
  |=  msg=json
  ^-  json
  =/  err  (wire-error:failure msg)
  ?^  err  (pairs:enjs:format ~[['error' %s u.err]])
  ?>  =('message' (str:w msg 'type'))
  =/  content  (need (get:w msg 'content'))
  ?>  ?=(%a -.content)
  =/  text  (rap 3 (turn p.content |=(block=json ?:(=('text' (str:w block 'type')) (str:w block 'text') ''))))
  =/  calls
    %+  murn  p.content
    |=  block=json
    ^-  (unit json)
    ?.  =('tool_use' (str:w block 'type'))  ~
    =/  input  (need (get:w block 'input'))
    ?>  &(?=(%o -.input) !=('' (str:w block 'id')) !=('' (str:w block 'name')))
    `(pairs:enjs:format ~[['id' (need (get:w block 'id'))] ['type' %s 'function'] ['function' (pairs:enjs:format ~[['name' (need (get:w block 'name'))] ['arguments' %s (en:json:html input)]])]])
  =/  stop  (str:w msg 'stop_reason')
  ?>  !=('' stop)
  ?>  |(!=('' text) !=(~ calls) =('max_tokens' stop))
  =/  finish=@t
    ?:  =('tool_use' stop)  'tool_calls'
    ?:  =('max_tokens' stop)  'length'
    ?:  (lien `(list @t)`~['end_turn' 'stop_sequence' 'refusal'] |=(s=@t =(s stop)))  'stop'
    'error'
  ::  Do not execute a tool whose generation ends at the output limit.
  ?>  |(=(~ calls) =('tool_use' stop))
  =/  usage  (fall (get:w msg 'usage') [%o ~])
  =/  input  :(add (num:w usage 'input_tokens') (num:w usage 'cache_read_input_tokens') (num:w usage 'cache_creation_input_tokens'))
  =/  assistant  (pairs:enjs:format ~[['role' %s 'assistant'] ['content' %s text] ['tool_calls' %a calls]])
  (pairs:enjs:format ~[['choices' %a ~[(pairs:enjs:format ~[['finish_reason' %s finish] ['message' assistant]])]] ['usage' (pairs:enjs:format ~[['prompt_tokens' (numb:enjs:format input)] ['completion_tokens' (numb:enjs:format (num:w usage 'output_tokens'))]])]])
++  continuation
  |=  msg=json
  ^-  @t
  =/  content  (get:w msg 'content')
  ?.  ?=([~ %a *] content)  ''
  ?.  (lien p.u.content |=(block=json |(=('thinking' (str:w block 'type')) =('redacted_thinking' (str:w block 'type')))))  ''
  ?>  %+  levy  p.u.content
      |=  block=json
      ?:  =('thinking' (str:w block 'type'))  !=('' (str:w block 'signature'))
      ?:  =('redacted_thinking' (str:w block 'type'))  !=('' (str:w block 'data'))
      &
  (en:json:html (pairs:enjs:format ~[['content' u.content]]))
--
