::  Client-facing JSON projections and command decoding, shared by native
::  JSON marks, ACP and snapshots. These are views of nouns, not stored state.
::  Provider wire messages live separately in harness-provider.
/-  h=harness
/+  hl=harness
|%
++  transcript-json
  |=  log=(list event:h)
  ^-  json
  :-  %a
  %+  turn  (transcript:hl log)
  |=  [at=@ud input-id=(unit input-id:h) =item:h]
  =/  row  (item-ui-json item)
  ?>  ?=(%o -.row)
  :-  %o
  %-  ~(gas by p.row)
  :~  ['eventCount' (numb:enjs:format at)]
      ['id' %s ?:(?&(?=(%tool -.item) (is-cancelled:hl body.item)) (rap 3 (scot %ud at) ':' call-id.item ~) (scot %ud at))]
      ['inputId' ?~(input-id ~ [%s (scot %uv u.input-id)])]
      ['cancelled' %b ?:(?=(%tool -.item) (is-cancelled:hl body.item) %.n)]
  ==
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
::  json for configuration surfaces (key withheld)
::
++  config-json
  |=  cfg=config:h
  ^-  json
  %-  pairs:enjs:format
  :~  ['url' %s url.cfg]
      ['model' %s model.cfg]
      :-  'headers'
      :-  %a
      %+  turn  headers.cfg
      |=  [name=@t value=@t]
      (pairs:enjs:format ~[['name' %s name] ['value' %s value]])
      ['system' %s system.cfg]
      ['max-context' (numb:enjs:format max-context.cfg)]
      ['tools' %a (turn tools.cfg |=(t=term `json`[%s t]))]
  ==
::  json for the ui: full session view (key withheld)
::
++  view-json
  |=  v=view:h
  ^-  json
  ::  Configuration has one projection, including its credential redaction.
  =/  base  (config-json config.v)
  ?>  ?=(%o -.base)
  :-  %o
  %-  ~(gas by p.base)
  :~  ['summary' ?~(summary.v ~ [%s u.summary.v])]
      ['items' %a (turn items.v item-ui-json)]
      ['pending' %b !=(~ pending.v)]
      ['wait' %a (turn ~(tap in wait.v) |=(id=@t `json`[%s id]))]
      ['err' ?~(err.v ~ [%s u.err.v])]
      :-  'origin'
      ?~  origin.v  ~
      %-  pairs:enjs:format
      :~  ['sessionId' %s from.u.origin.v]
          ['eventCount' (numb:enjs:format at.u.origin.v)]
      ==
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
      (pairs:enjs:format ~[['id' %s id.c] ['name' %s name.c] ['args' %s args.c]])
    ==
  ::
      %tool
    %-  pairs:enjs:format
    :~  ['role' %s 'tool']
        ['callId' %s call-id.it]
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
      %input-received
    %-  pairs:enjs:format
    :~  ['type' %s 'input']
        ['id' %s (scot %uv id.input.e)]
        ['source' (input-source-json source.input.e)]
        ['item' (item-ui-json item.input.e)]
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
      %cancelled
    %-  pairs:enjs:format
    :~  ['type' %s 'cancelled']
        ['reason' %s reason.e]
    ==
  ::
      %forked
    %-  pairs:enjs:format
    :~  ['type' %s 'forked']
        ['from' %s from.e]
        ['eventCount' (numb:enjs:format at.e)]
    ==
  ::
      %retried
    (pairs:enjs:format ~[['type' %s 'retried']])
  ::
      %halted
    %-  pairs:enjs:format
    :~  ['type' %s 'halted']
        ['reason' %s reason.e]
    ==
  ==
::  A deliberately compact JSON projection. Native clients can consume the
::  typed event and retain every face without this projection.
::
++  input-source-json
  |=  source=input-source:h
  ^-  json
  ?-  -.source
      %hand
    (pairs:enjs:format ~[['kind' %s 'hand'] ['binding' %s binding.source] ['hand' %s hand.source] ['address' %s address.source] ['event' %s event.source] ['actor' %s actor.source]])
  ::
      %acp
    (pairs:enjs:format ~[['kind' %s 'acp'] ['client' %s client.source]])
  ::
      %poke
    (pairs:enjs:format ~[['kind' %s 'poke'] ['ship' %s (scot %p ship.source)]])
  ::
      %timer
    (pairs:enjs:format ~[['kind' %s 'timer'] ['name' %s name.source]])
  ::
      %webhook
    (pairs:enjs:format ~[['kind' %s 'webhook'] ['path' %s path.source]])
  ::
      %peer
    (pairs:enjs:format ~[['kind' %s 'peer'] ['ship' %s (scot %p ship.source)]])
  ::
      %subagent
    (pairs:enjs:format ~[['kind' %s 'subagent'] ['parent' %s parent.source]])
  ::
      %rehearsal
    (pairs:enjs:format ~[['kind' %s 'rehearsal'] ['parent' %s parent.source] ['skill' %s skill.source]])
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
      fork-at+(ot ~[from+so to+so at+ni])
      compact+(ot ~[sid+so])
      cancel+(ot ~[sid+so])
      delete+(ot ~[sid+so])
      retry+(ot ~[sid+so])
      config+(ot ~[sid+so config+json-config])
      timer-set+(ot ~[sid+so name+(su sym) in+secs every+(mu secs) prompt+so])
      timer-cancel+(ot ~[sid+so name+(su sym)])
      skill-add+(ot ~[name+so desc+so body+so])
      skill-del+(ot ~[name+so])
      set-key+(ot ~[key+so])
      commit-skill+(ot ~[name+so])
      discard-skill+(ot ~[name+so])
  ==
::
++  json-config
  =,  dejs:format
  ^-  $-(json config:h)
  %-  ot
  :~  url+so
      model+so
      key+so
      headers+(ar (ot ~[name+so value+so]))
      system+so
      max-context+ni
      tools+(ar (su sym))
  ==
++  mcp-server-json
  |=  [id=mcp-server-id:h server=mcp-server:h]
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' %s id]
      ['name' %s name.server]
      ['url' %s url.server]
      :-  'headers'
      :-  %a
      %+  turn  headers.server
      |=  [name=@t value=@t]
      (pairs:enjs:format ~[['name' %s name] ['value' %s value]])
      ['enabled' %b enabled.server]
  ==
++  json-mcp-servers
  =,  dejs:format
  ^-  $-(json (list [id=mcp-server-id:h server=mcp-server:h]))
  (ar (ot ~[id+so name+so url+so headers+(ar (ot ~[name+so value+so])) enabled+bo]))
--
