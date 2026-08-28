::  harness: the pure core of the head
::
::    replay (+play), decide (+decide), assemble the provider request
::    (+request-body), digest the provider response (+parse-response).
::    no i/o anywhere in this file.
::
/-  h=harness
|%
::  +play: fold the event log (newest first) into a view
::
++  play
  |=  log=(list event:h)
  ^-  view:h
  %+  roll  (flop log)
  |=  [e=event:h v=view:h]
  ^-  view:h
  ?-  -.e
    %config-replaced       v(config config.e, err ~)
    %input-admitted        v(items (snoc items.v item.e), err ~)
    %llm-requested         v(pending `[req.e kind.e])
    %llm-failed            v(pending ~, err `err.e)
    %tool-requested        v(wait (~(put in wait.v) call-id.e))
    %retried               v(err ~)
  ::
      %tool-completed
    %=  v
      wait   (~(del in wait.v) call-id.e)
      items  (snoc items.v [%tool call-id.e name.e body.e])
    ==
  ::
      %llm-completed
    %=  v
      pending  ~
      items    (snoc items.v item.e)
      total    :-  (add prompt.total.v prompt.usage.e)
               (add completion.total.v completion.usage.e)
    ==
  ::
      %compaction-completed
    %=  v
      pending  ~
      summary  `summary.e
      items    (retained items.v)
    ==
  ==
::  +unanswered: trailing items with no assistant response yet
::
++  unanswered
  |=  items=(list item:h)
  ^-  (list item:h)
  %-  flop
  =/  rev  (flop items)
  |-  ^-  (list item:h)
  ?~  rev  ~
  ?:  ?=(%assistant -.i.rev)  ~
  [i.rev $(rev t.rev)]
::  +retained: what compaction keeps verbatim: the unanswered tail,
::  plus up to +keep-tail recent items, never splitting a tool flow
::
++  keep-tail  6
++  retained
  |=  items=(list item:h)
  ^-  (list item:h)
  =/  n  (lent items)
  =/  keep  (max (lent (unanswered items)) (min keep-tail n))
  |-  ^-  (list item:h)
  ?:  (gte keep n)  items
  =/  sl  (slag (sub n keep) items)
  ?:  ?=([[%tool *] *] sl)  $(keep +(keep))
  sl
::  +last-calls: the last assistant item's tool calls,
::  and the items that came after it
::
++  last-calls
  |=  items=(list item:h)
  ^-  [calls=(list tool-call:h) after=(list item:h)]
  =/  rev  (flop items)
  =|  after=(list item:h)
  |-  ^-  [calls=(list tool-call:h) after=(list item:h)]
  ?~  rev  [~ after]
  ?:  ?=(%assistant -.i.rev)
    [calls.i.rev after]
  $(rev t.rev, after [i.rev after])
::  +decide: what happens next; ~ means idle.
::  skills come from agent state (they shape the request context,
::  hence the token estimate); the lib stays pure
::
++  decide
  |=  [v=view:h skills=(map @t skill:h)]
  ^-  (unit step:h)
  ?^  pending.v  ~
  ::  async tool results still in flight
  ::
  ?.  =(~ wait.v)  ~
  ::  a failure halts the loop; retry or new input clears it
  ::
  ?^  err.v  ~
  ?~  items.v  ~
  ::  outstanding tool calls from the last assistant turn
  ::
  =/  lc  (last-calls items.v)
  =/  todo=(list tool-call:h)
    =/  done=(set @t)
      %-  ~(gas in *(set @t))
      %+  murn  after.lc
      |=(it=item:h ?:(?=(%tool -.it) `call-id.it ~))
    (skip calls.lc |=(c=tool-call:h (~(has in done) id.c)))
  ?^  todo  `[%tools todo]
  =/  last=item:h  (rear items.v)
  ?:  ?=(%assistant -.last)  ~
  ?.  (gth (est-tokens v skills) max-context.config.v)
    `[%turn ~]
  ::  compact only when it would actually shed items; an over-budget
  ::  irreducible tail proceeds rather than compacting forever
  ::
  ?:  (lth (lent (retained items.v)) (lent items.v))
    `[%compact ~]
  `[%turn ~]
::  +clip: cap a cord's byte length, marking truncation
::
++  clip
  |=  [t=@t cap=@ud]
  ^-  @t
  ?:  (lte (met 3 t) cap)  t
  (cat 3 (end [3 cap] t) ' ...(truncated)')
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
        ['stream' %b %.n]
    ==
  =?  base  &(=(%turn kind) !=(~ tools.config.v))
    (snoc base ['tools' (tool-defs tools.config.v)])
  (pairs:enjs:format base)
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
::  +skills-json: the catalog for the ui (bodies withheld)
::
++  skills-json
  |=  skills=(map @t skill:h)
  ^-  json
  :-  %a
  %+  turn  ~(tap by skills)
  |=  [name=@t s=skill:h]
  ^-  json
  (pairs:enjs:format ~[['name' %s name] ['desc' %s desc.s]])
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
::  +tool-defs: schemas for granted tool families
::
++  tool-defs
  |=  tools=(list term)
  ^-  json
  :-  %a
  %-  zing
  %+  turn  tools
  |=  t=term
  ^-  (list json)
  ?+  t  ~
      %ship-time
    :_  ~
    %^    fun-json
        'get_ship_time'
      'Get the current time on the urbit ship hosting this agent'
    ~
  ::
      %clay
    :~  %^    fun-json
            'read_desk_file'
          %-  crip
          %+  weld
            "Read a file from the ship's filesystem (clay). "
          "Path is /desk/spur, e.g. /harness/lib/harness/hoon"
        ~[['path' 'the file path, as /desk/spur/file/ext']]
      ::
        %^    fun-json
            'list_desk_files'
          'List files under a clay directory. Path is /desk or /desk/spur'
        ~[['path' 'the directory path, as /desk/spur']]
    ==
  ::
      %web
    :_  ~
    %^    fun-json
        'http_fetch'
      %-  crip
      %+  weld
        "Fetch a url over http(s). Optional method (GET or POST) "
      "and body (sent as json when present)."
    :~  ['url' 'the url to fetch']
        ['method' 'GET or POST; defaults to GET']
        ['body' 'optional request body']
    ==
  ::
      %skills
    :_  ~
    %^    fun-json
        'read_skill'
      %-  crip
      %+  weld
        "Read the full body of a named skill from your skill library. "
      "The catalog of available skills is in your context."
    ~[['name' 'the skill name']]
  ::
      %skill-write
    :~  %^    fun-json
            'write_skill'
          %-  crip
          %+  weld
            "Create or update a named skill in your persistent skill "
          "library. Skills survive across sessions."
        :~  ['name' 'the skill name']
            ['description' 'one line shown in the skill catalog']
            ['body' 'the full skill text']
        ==
      ::
        %^    fun-json
            'delete_skill'
          'Delete a named skill from your skill library'
        ~[['name' 'the skill name']]
    ==
  ::
      %subagents
    :_  ~
    %^    fun-json
        'run_subagent'
      %-  crip
      %+  weld
        "Delegate a task to a fresh subagent session with no history. "
      "It runs until done and its final answer is returned to you."
    :~  ['prompt' 'the task for the subagent']
        ['system' 'optional system prompt for the subagent']
    ==
  ==
::  +fun-json: an openai function schema; first param is required
::
++  fun-json
  |=  [name=@t desc=@t params=(list [@t @t])]
  ^-  json
  %-  pairs:enjs:format
  :~  ['type' %s 'function']
      :-  'function'
      %-  pairs:enjs:format
      :~  ['name' %s name]
          ['description' %s desc]
          :-  'parameters'
          =/  props=json
            :-  %o
            %-  ~(gas by *(map @t json))
            %+  turn  params
            |=  [pn=@t pd=@t]
            ^-  [@t json]
            :-  pn
            (pairs:enjs:format ~[['type' %s 'string'] ['description' %s pd]])
          =/  req=json
            :-  %a
            ?~  params  ~
            ~[`json`[%s -.i.params]]
          %-  pairs:enjs:format
          :~  ['type' %s 'object']
              ['properties' props]
              ['required' req]
          ==
      ==
  ==
::  +parse-response: digest a chat-completions response into branch fields
::
++  parse-response
  |=  jon=json
  ^-  (each [stop=stop-reason:h u=usage:h it=item:h] @t)
  ?.  ?=([%o *] jon)  [%| 'unexpected response shape']
  =/  err  (~(get by p.jon) 'error')
  ?^  err
    ?.  ?=([%o *] u.err)  [%| 'provider error']
    =/  msg  (~(get by p.u.err) 'message')
    [%| ?:(?=([~ %s *] msg) p.u.msg 'provider error')]
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
::  json for the ui: full session view (key withheld)
::
++  view-json
  |=  v=view:h
  ^-  json
  %-  pairs:enjs:format
  :~  ['url' %s url.config.v]
      ['model' %s model.config.v]
      ['system' %s system.config.v]
      ['max-context' (numb:enjs:format max-context.config.v)]
      ['tools' %a (turn tools.config.v |=(t=term `json`[%s t]))]
      ['summary' ?~(summary.v ~ [%s u.summary.v])]
      ['items' %a (turn items.v item-ui-json)]
      ['pending' %b !=(~ pending.v)]
      ['wait' %a (turn ~(tap in wait.v) |=(id=@t `json`[%s id]))]
      ['err' ?~(err.v ~ [%s u.err.v])]
      :-  'usage'
      %-  pairs:enjs:format
      :~  ['prompt' (numb:enjs:format prompt.total.v)]
          ['completion' (numb:enjs:format completion.total.v)]
      ==
  ==
::
++  item-ui-json
  |=  it=item:h
  ^-  json
  ?-  -.it
      %user
    (pairs:enjs:format ~[['role' %s 'user'] ['body' %s body.it]])
  ::
      %assistant
    %-  pairs:enjs:format
    :~  ['role' %s 'assistant']
        ['body' %s body.it]
        :-  'calls'
        :-  %a
        %+  turn  calls.it
        |=  c=tool-call:h
        (pairs:enjs:format ~[['name' %s name.c] ['args' %s args.c]])
    ==
  ::
      %tool
    %-  pairs:enjs:format
    :~  ['role' %s 'tool']
        ['name' %s name.it]
        ['body' %s body.it]
    ==
  ==
::  json for the ui: one event
::
++  event-json
  |=  e=event:h
  ^-  json
  ?-  -.e
      %config-replaced
    %-  pairs:enjs:format
    :~  ['type' %s 'config']
        ['model' %s model.config.e]
    ==
  ::
      %input-admitted
    %-  pairs:enjs:format
    :~  ['type' %s 'input']
        ['item' (item-ui-json item.e)]
    ==
  ::
      %llm-requested
    %-  pairs:enjs:format
    :~  ['type' %s 'llm-requested']
        ['req' (numb:enjs:format req.e)]
        ['kind' %s kind.e]
    ==
  ::
      %llm-completed
    %-  pairs:enjs:format
    :~  ['type' %s 'llm-completed']
        ['stop' %s stop.e]
        ['item' (item-ui-json item.e)]
        :-  'usage'
        %-  pairs:enjs:format
        :~  ['prompt' (numb:enjs:format prompt.usage.e)]
            ['completion' (numb:enjs:format completion.usage.e)]
        ==
    ==
  ::
      %llm-failed
    %-  pairs:enjs:format
    :~  ['type' %s 'llm-failed']
        ['err' %s err.e]
    ==
  ::
      %tool-requested
    %-  pairs:enjs:format
    :~  ['type' %s 'tool-requested']
        ['name' %s name.e]
    ==
  ::
      %tool-completed
    %-  pairs:enjs:format
    :~  ['type' %s 'tool']
        ['name' %s name.e]
        ['body' %s body.e]
    ==
  ::
      %compaction-completed
    %-  pairs:enjs:format
    :~  ['type' %s 'compaction']
        ['summary' %s summary.e]
    ==
  ::
      %retried
    (pairs:enjs:format ~[['type' %s 'retried']])
  ==
::
++  update-json
  |=  upd=update:h
  ^-  json
  ?-  -.upd
      %event
    %-  pairs:enjs:format
    :~  ['sid' %s sid.upd]
        ['event' (event-json event.upd)]
    ==
  ==
::  pokes from json (eyre channel / ui)
::
++  json-action
  |=  jon=json
  ^-  action:h
  =,  dejs:format
  =/  secs  (cu |=(s=@ud `@dr`(mul s ~s1)) ni)
  %.  jon
  %-  of
  :~  new+(ot ~[sid+so config+json-config])
      send+(ot ~[sid+so text+so])
      fork+(ot ~[from+so to+so])
      compact+(ot ~[sid+so])
      cancel+(ot ~[sid+so])
      retry+(ot ~[sid+so])
      config+(ot ~[sid+so config+json-config])
      timer-set+(ot ~[sid+so name+(su sym) in+secs every+(mu secs) prompt+so])
      timer-cancel+(ot ~[sid+so name+(su sym)])
      skill-add+(ot ~[name+so desc+so body+so])
      skill-del+(ot ~[name+so])
  ==
::
++  json-config
  =,  dejs:format
  ^-  $-(json config:h)
  %-  ot
  :~  url+so
      model+so
      key+so
      system+so
      max-context+ni
      tools+(ar (su sym))
  ==
--
