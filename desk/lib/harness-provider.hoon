::  Provider boundary: request encoding, response decoding and model catalogs.
::  No I/O, credentials or session mutation. Decode into Harness nouns first;
::  only the head may accept a result against its outstanding request identity.
/-  h=harness
/+  ht=harness-tools, failure=harness-failure
|%
+$  model-info  [id=@t context=(unit @ud)]
::  +est-tokens: crude budget: request bytes / 4
::
++  est-tokens
  |=  [v=view:h skills=(map @t skill:h)]
  ^-  @ud
  (div (met 3 (en:json:html (request-body v %turn skills))) 4)
::  +request-body: assemble the provider-native request
::
++  request-body
  |=  [v=view:h kind=request-kind:h skills=(map @t skill:h)]
  ^-  json
  =/  msgs=(list json)
    %-  zing
    ^-  (list (list json))
    :~  ~[(msg-json 'system' system.config.v)]
      ::
        ?~  summary.v  ~
        :_  ~
        %+  msg-json  'system'
        (cat 3 'Summary of the conversation so far: ' u.summary.v)
      ::
        ::  the skill catalog rides along whenever %skills is granted;
        ::  names and descriptions only, bodies are read on demand
        ::
        ?.  &((lien tools.config.v |=(t=term =(%skills t))) !=(~ skills))
          ~
        ~[(msg-json 'system' (skills-catalog skills))]
      ::
        (turn items.v item-json)
      ::
        ?.  =(%compaction kind)  ~
        :_  ~
        %+  msg-json  'user'
        '''
        Summarize the conversation so far for your own future reference.
        Preserve all facts, decisions, names, and open tasks.
        Reply with only the summary.
        '''
    ==
  =/  base=(list [@t json])
    :~  ['model' %s model.config.v]
        ['messages' %a msgs]
        ['stream' %b &]
    ==
  =?  base  &(=(%turn kind) !=(~ tools.config.v))
    (snoc base ['tools' (tool-defs:ht tools.config.v)])
  (pairs:enjs:format base)
::  +responses-body: OpenAI Responses wire format, including the Codex
::  subscription endpoint used after device authorization.
::
++  responses-body
  |=  [v=view:h kind=request-kind:h skills=(map @t skill:h)]
  ^-  json
  =/  input=(list json)
    %-  zing
    ^-  (list (list json))
    :~  ?~  summary.v  ~
        ~[(responses-message 'developer' (cat 3 'Summary of the conversation so far: ' u.summary.v))]
      ::
        ?.  &((lien tools.config.v |=(t=term =(%skills t))) !=(~ skills))
          ~
        ~[(responses-message 'developer' (skills-catalog skills))]
      ::
        (zing (turn items.v responses-item))
      ::
        ?.  =(%compaction kind)  ~
        :_  ~
        %+  responses-message  'user'
        '''
        Summarize the conversation so far for your own future reference.
        Preserve all facts, decisions, names, and open tasks.
        Reply with only the summary.
        '''
    ==
  =/  base=(list [@t json])
    :~  ['model' %s model.config.v]
        ['instructions' %s system.config.v]
        ['input' %a input]
        ['tool_choice' %s 'auto']
        ['parallel_tool_calls' %b &]
        ['store' %b |]
        ['stream' %b &]
    ==
  =?  base  &(=(%turn kind) !=(~ tools.config.v))
    (snoc base ['tools' (responses-tool-defs tools.config.v)])
  (pairs:enjs:format base)
::
++  responses-message
  |=  [role=@t text=@t]
  ^-  json
  =/  content=json
    (pairs:enjs:format ~[['type' %s ?:(=('assistant' role) 'output_text' 'input_text')] ['text' %s text]])
  (pairs:enjs:format ~[['role' %s role] ['content' %a ~[content]]])
::
++  responses-item
  |=  it=item:h
  ^-  (list json)
  ?-  -.it
      %user  ~[(responses-message 'user' body.it)]
      %assistant
    =/  msg=(list json)
      ?:(=(0 body.it) ~ ~[(responses-message 'assistant' body.it)])
    %+  weld  msg
    %+  turn  calls.it
    |=  c=tool-call:h
    %-  pairs:enjs:format
    :~  ['type' %s 'function_call']
        ['call_id' %s id.c]
        ['name' %s name.c]
        ['arguments' %s args.c]
    ==
      %tool
    :_  ~
    %-  pairs:enjs:format
    :~  ['type' %s 'function_call_output']
        ['call_id' %s call-id.it]
        ['output' %s body.it]
    ==
  ==
::
++  responses-tool-defs
  |=  tools=(list term)
  ^-  json
  =/  ordinary  (tool-defs:ht tools)
  ?.  ?=(%a -.ordinary)  [%a ~]
  :-  %a
  %+  murn  p.ordinary
  |=  entry=json
  ^-  (unit json)
  ?.  ?=(%o -.entry)  ~
  =/  fun  (~(get by p.entry) 'function')
  ?.  ?=([~ %o *] fun)  ~
  =/  name  (~(get by p.u.fun) 'name')
  =/  description  (~(get by p.u.fun) 'description')
  =/  parameters  (~(get by p.u.fun) 'parameters')
  ?.  &(?=(^ name) ?=(^ description) ?=(^ parameters))  ~
  `(pairs:enjs:format ~[['type' %s 'function'] ['name' u.name] ['description' u.description] ['parameters' u.parameters]])
::  +skills-catalog: the system message advertising available skills
::
++  skills-catalog
  |=  skills=(map @t skill:h)
  ^-  @t
  %+  rap  3
  :-  '''
      You have a library of skills: named instructions for handling
      particular kinds of task. When a task matches a skill, read its
      body with the read_skill tool and follow it. Available skills:

      '''
  %+  turn  ~(tap by skills)
  |=  [name=@t s=skill:h]
  (rap 3 '- ' name ': ' desc.s '\0a' ~)
::
++  msg-json
  |=  [role=@t content=@t]
  ^-  json
  (pairs:enjs:format ~[['role' %s role] ['content' %s content]])
::
++  item-json
  |=  it=item:h
  ^-  json
  ?-  -.it
      %user  (msg-json 'user' body.it)
  ::
      %assistant
    =/  base=(list [@t json])
      :~  ['role' %s 'assistant']
          ['content' %s body.it]
      ==
    =?  base  !=(~ calls.it)
      %+  snoc  base
      :-  'tool_calls'
      :-  %a
      %+  turn  calls.it
      |=  c=tool-call:h
      %-  pairs:enjs:format
      :~  ['id' %s id.c]
          ['type' %s 'function']
          :-  'function'
          (pairs:enjs:format ~[['name' %s name.c] ['arguments' %s args.c]])
      ==
    (pairs:enjs:format base)
  ::
      %tool
    %-  pairs:enjs:format
    :~  ['role' %s 'tool']
        ['tool_call_id' %s call-id.it]
        ['content' %s body.it]
    ==
  ==
::  +stream-text: project displayable text from an accumulated SSE body.
::  This is transient UI data; the terminal parser below still produces the
::  single semantic event committed to the conversation.
::
++  stream-text
  |=  [body=@t responses=?]
  ^-  @t
  %+  rap  3
  %+  murn  (text-lines body)
  |=  line=tape
  ^-  (unit @t)
  ?.  =("data: " (scag 6 line))  ~
  =/  jon  (de:json:html (crip (slag 6 line)))
  ?~  jon  ~
  ?.  ?=(%o -.u.jon)  ~
  ?:  responses
    =/  typ  (~(get by p.u.jon) 'type')
    ?.  ?=([~ %s *] typ)  ~
    ?.  =('response.output_text.delta' p.u.typ)  ~
    =/  delta  (~(get by p.u.jon) 'delta')
    ?:(?=([~ %s *] delta) `p.u.delta ~)
  =/  choices  (~(get by p.u.jon) 'choices')
  ?.  ?=([~ %a *] choices)  ~
  ?~  p.u.choices  ~
  ?.  ?=(%o -.i.p.u.choices)  ~
  =/  delta  (~(get by p.i.p.u.choices) 'delta')
  ?.  ?=([~ %o *] delta)  ~
  =/  content  (~(get by p.u.delta) 'content')
  ?:(?=([~ %s *] content) `p.u.content ~)
::
::  +parse-chat-sse: digest a completed Chat Completions event stream,
::  including content, fragmented tool calls, stop reason, and usage.
::
+$  stream-call  [id=@t name=@t args=@t]
++  parse-chat-sse
  |=  body=@t
  ^-  (each [stop=stop-reason:h u=usage:h it=item:h] @t)
  =/  events=(list json)
    %+  murn  (text-lines body)
    |=  line=tape
    ^-  (unit json)
    ?.  =("data: " (scag 6 line))  ~
    (de:json:html (crip (slag 6 line)))
  =/  acc
    %+  roll  events
    |=  [ev=json acc=[text=@t calls=(map @ud stream-call) finish=(unit @t) u=usage:h]]
    ^+  acc
    ?.  ?=(%o -.ev)  acc
    =/  next-u=usage:h
      =/  usage  (~(get by p.ev) 'usage')
      ?.  ?=([~ %o *] usage)  u.acc
      =/  prompt  (~(get by p.u.usage) 'prompt_tokens')
      =/  completion  (~(get by p.u.usage) 'completion_tokens')
      :-  ?:(?=([~ %n *] prompt) (fall (rush p.u.prompt dem) prompt.u.acc) prompt.u.acc)
      ?:(?=([~ %n *] completion) (fall (rush p.u.completion dem) completion.u.acc) completion.u.acc)
    =/  choices  (~(get by p.ev) 'choices')
    ?.  ?=([~ %a *] choices)  acc(u next-u)
    ?~  p.u.choices  acc(u next-u)
    =/  choice  i.p.u.choices
    ?.  ?=(%o -.choice)  acc(u next-u)
    =/  finish  (~(get by p.choice) 'finish_reason')
    =/  next-finish=(unit @t)
      ?:(?=([~ %s *] finish) `p.u.finish finish.acc)
    =/  delta  (~(get by p.choice) 'delta')
    ?.  ?=([~ %o *] delta)  acc(finish next-finish, u next-u)
    =/  content  (~(get by p.u.delta) 'content')
    =/  next-text=@t
      ?:(?=([~ %s *] content) (cat 3 text.acc p.u.content) text.acc)
    =/  tool-calls  (~(get by p.u.delta) 'tool_calls')
    ?.  ?=([~ %a *] tool-calls)
      acc(text next-text, finish next-finish, u next-u)
    =/  next-calls=(map @ud stream-call)
      %+  roll  p.u.tool-calls
      |=  [part=json calls=_calls.acc]
      ?.  ?=(%o -.part)  calls
      =/  index  (~(get by p.part) 'index')
      ?.  ?=([~ %n *] index)  calls
      =/  at  (rush p.u.index dem)
      ?~  at  calls
      =/  prior=stream-call  (fall (~(get by calls) u.at) ['' '' ''])
      =/  id  (~(get by p.part) 'id')
      =/  fun  (~(get by p.part) 'function')
      =/  name=(unit @t)
        ?.  ?=([~ %o *] fun)  ~
        =/  value  (~(get by p.u.fun) 'name')
        ?:(?=([~ %s *] value) `p.u.value ~)
      =/  args=(unit @t)
        ?.  ?=([~ %o *] fun)  ~
        =/  value  (~(get by p.u.fun) 'arguments')
        ?:(?=([~ %s *] value) `p.u.value ~)
      =/  next=stream-call
        :*  ?:(?=([~ %s *] id) p.u.id id.prior)
            (cat 3 name.prior (fall name ''))
            (cat 3 args.prior (fall args ''))
        ==
      (~(put by calls) u.at next)
    acc(text next-text, calls next-calls, finish next-finish, u next-u)
  =/  calls=(list tool-call:h)
    %+  turn  ~(val by calls.acc)
    |=  call=stream-call
    [id.call name.call args.call]
  ?~  finish.acc  [%| 'provider stream ended before completion']
  ?:  (lien calls |=([id=@t name=@t args=@t] |(=(id '') =(name '') =(~ (de:json:html args)))))
    [%| 'incomplete tool call in provider stream']
  ?:  ?&  =(0 text.acc)
          ?=(~ calls)
      ==
    [%| 'no completed output in response stream']
  =/  stop=stop-reason:h
    ?:  !=(~ calls)  %tool-calls
    ?:  =('length' u.finish.acc)  %length
    %stop
  [%& stop u.acc [%assistant text.acc calls]]
::  +parse-response: digest a chat-completions response into branch fields
::
++  parse-response
  |=  jon=json
  ^-  (each [stop=stop-reason:h u=usage:h it=item:h] @t)
  ?.  ?=([%o *] jon)  [%| 'unexpected response shape']
  =/  err  (wire-error:failure jon)
  ?^  err  [%| u.err]
  =/  choices  (~(get by p.jon) 'choices')
  ?.  ?=([~ %a ^] choices)  [%| 'no choices in response']
  =/  choice  i.p.u.choices
  ?.  ?=([%o *] choice)  [%| 'malformed choice']
  =/  stop=stop-reason:h
    =/  fin  (~(get by p.choice) 'finish_reason')
    ?.  ?=([~ %s *] fin)  %stop
    ?+  p.u.fin  %stop
      %'tool_calls'  %tool-calls
      %length        %length
    ==
  =/  msg  (~(get by p.choice) 'message')
  ?.  ?=([~ %o *] msg)  [%| 'no message in choice']
  =/  content=@t
    =/  c  (~(get by p.u.msg) 'content')
    ?:(?=([~ %s *] c) p.u.c '')
  =/  calls=(list tool-call:h)
    =/  tc  (~(get by p.u.msg) 'tool_calls')
    ?.  ?=([~ %a *] tc)  ~
    %+  murn  p.u.tc
    |=  j=json
    ^-  (unit tool-call:h)
    ?.  ?=([%o *] j)  ~
    =/  id  (~(get by p.j) 'id')
    =/  fun  (~(get by p.j) 'function')
    ?.  &(?=([~ %s *] id) ?=([~ %o *] fun))  ~
    =/  nam  (~(get by p.u.fun) 'name')
    =/  arg  (~(get by p.u.fun) 'arguments')
    ?.  &(?=([~ %s *] nam) ?=([~ %s *] arg))  ~
    `[p.u.id p.u.nam p.u.arg]
  =/  u=usage:h
    =/  us  (~(get by p.jon) 'usage')
    ?.  ?=([~ %o *] us)  [0 0]
    =/  pt  (~(get by p.u.us) 'prompt_tokens')
    =/  ct  (~(get by p.u.us) 'completion_tokens')
    :-  ?:(?=([~ %n *] pt) (fall (rush p.u.pt dem) 0) 0)
    ?:(?=([~ %n *] ct) (fall (rush p.u.ct dem) 0) 0)
  [%& stop u [%assistant content calls]]
::  +parse-responses-sse: collect completed output items from a Responses
::  event stream. The terminal response currently omits its output array on
::  the Codex route, so output_item.done is the durable wire boundary.
::
++  parse-responses-sse
  |=  body=@t
  ^-  (each [stop=stop-reason:h u=usage:h it=item:h] @t)
  =/  lines=wall  (text-lines body)
  =/  events=(list json)
    %+  murn  lines
    |=  line=tape
    ^-  (unit json)
    ?.  =("data: " (scag 6 line))  ~
    (de:json:html (crip (slag 6 line)))
  =|  text=@t
  =|  calls=(list tool-call:h)
  =/  acc
    %+  roll  events
    |=  [ev=json acc=[text=@t calls=(list tool-call:h)]]
    ?.  ?=(%o -.ev)  acc
    =/  typ  (~(get by p.ev) 'type')
    ?.  ?=([~ %s *] typ)  acc
    ?.  =('response.output_item.done' p.u.typ)  acc
    =/  item  (~(get by p.ev) 'item')
    ?.  ?=([~ %o *] item)  acc
    =/  kind  (~(get by p.u.item) 'type')
    ?.  ?=([~ %s *] kind)  acc
    ?:  =('message' p.u.kind)
      =/  content  (~(get by p.u.item) 'content')
      ?.  ?=([~ %a *] content)  acc
      =/  pieces=(list @t)
        %+  murn  p.u.content
        |=  part=json
        ^-  (unit @t)
        ?.  ?=(%o -.part)  ~
        =/  txt  (~(get by p.part) 'text')
        ?:(?=([~ %s *] txt) `p.u.txt ~)
      acc(text (rap 3 pieces))
    ?.  =('function_call' p.u.kind)  acc
    =/  id  (~(get by p.u.item) 'call_id')
    =/  name  (~(get by p.u.item) 'name')
    =/  args  (~(get by p.u.item) 'arguments')
    ?.  &(?=([~ %s *] id) ?=([~ %s *] name) ?=([~ %s *] args))  acc
    acc(calls (snoc calls.acc [p.u.id p.u.name p.u.args]))
  ?:  ?&  =(0 text.acc)
          ?=(~ calls.acc)
      ==
    [%| 'no completed output in response stream']
  [%& ?:(?=(^ calls.acc) %tool-calls %stop) [0 0] [%assistant text.acc calls.acc]]
::
++  text-lines
  |=  text=@t
  =/  chars=tape  (trip text)
  =|  out=wall
  =|  line=tape
  |-  ^-  wall
  ?~  chars  (flop [(flop line) out])
  ?:  =('\0a' i.chars)
    $(chars t.chars, out [(flop line) out], line ~)
  $(chars t.chars, line [i.chars line])
::
++  model-info-json
  |=  model=model-info
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' %s id.model]
      ['contextWindow' ?~(context.model ~ (numb:enjs:format u.context.model))]
  ==
::
++  parse-model-list
  |=  jon=json
  ^-  (list model-info)
  ?>  ?=([%o *] jon)
  =/  data  (~(get by p.jon) 'data')
  =/  models  (~(get by p.jon) 'models')
  =/  rows=(list json)
    ?:  ?=([~ %a *] data)  p.u.data
    ?:  ?=([~ %a *] models)  p.u.models
    ~
  ?>  ?=(^ rows)
  %+  murn  rows
  |=  item=json
  ^-  (unit model-info)
  ?.  ?=([%o *] item)  ~
  =/  id  (~(get by p.item) 'id')
  =/  slug  (~(get by p.item) 'slug')
  =/  name=(unit @t)
    ?:  ?=([~ %s *] id)  `p.u.id
    ?:(?=([~ %s *] slug) `p.u.slug ~)
  ?~  name  ~
  `[u.name (model-context p.item)]
::
++  model-context
  |=  row=(map @t json)
  ^-  (unit @ud)
  =/  direct
    %+  first-json  row
    :~  'context_length'  'context_window'  'contextWindow'
        'max_input_tokens'  'max_context_length'  'max_context_tokens'
    ==
  =/  parsed  (json-ud direct)
  ?^  parsed  parsed
  =/  top  (~(get by row) 'top_provider')
  ?.  ?=([~ %o *] top)  ~
  (json-ud (first-json p.u.top ~['context_length' 'context_window']))
::
++  first-json
  |=  [row=(map @t json) names=(list @t)]
  ^-  (unit json)
  |-
  ?~  names  ~
  =/  value  (~(get by row) i.names)
  ?^(value value $(names t.names))
::
++  json-ud
  |=  value=(unit json)
  ^-  (unit @ud)
  ?~  value  ~
  ?:  ?=(%n -.u.value)  (rush p.u.value dem)
  ?:  ?=(%s -.u.value)  (rush p.u.value dem)
  ~
::
++  provider-for-url
  |=  url=@t
  ^-  @t
  ?:  =('https://openrouter.ai/api/v1/chat/completions' url)  'openrouter'
  ?:  =('https://api.openai.com/v1/chat/completions' url)     'openai'
  ?:  =('https://chatgpt.com/backend-api/codex/responses' url)  'openai'
  ?:  =('https://api.anthropic.com/v1/chat/completions' url)  'anthropic'
  'custom'
--
