::  Ephemeral presentation, not a work queue. Many actors and threads share
::  one Tlon context, so aggregate first and clear only when all are settled.
::  A short lease expires on crashes; renewal carries no prompts or tool args.
/-  t=harness-tlon, pr=tlon-presence, h=harness
/+  ht=harness-tools
|%
++  names
  |=  view=view:h
  ^-  (set @t)
  ?:  =(~ wait.view)  ~
  =/  items  (flop items.view)
  |-  ^-  (set @t)
  ?~  items  (silt ~['tools'])
  ?.  ?=(%assistant -.i.items)  $(items t.items)
  ::  Only the latest tool batch can own the current wait IDs. Never export
  ::  arbitrary model-supplied names, arguments, server IDs or result bodies.
  %+  roll  calls.i.items
  |=  [call=tool-call:h acc=(set @t)]
  ^-  (set @t)
  ?.  (~(has in wait.view) id.call)  acc
  (~(put in acc) ?~((tool-family:ht name.call) 'tools' name.call))
++  label
  |=  name=@t
  ^-  @t
  ?+  name  (cat 3 'Using ' name)
    %tools               'Using tools...'
    %'http_fetch'         'Fetching a page'
    %'curl'               'Making an HTTP request'
    %'web_search'         'Searching the web'
    %'read_desk_file'     'Reading a file'
    %'list_desk_files'    'Listing files'
    %'list_desk_scopes'   'Checking file access'
    %'current_time'       'Checking the time'
    %'tlon_read_history'  'Reading chat history'
    %'tlon_history_page'  'Reading older messages'
    %'tlon_search_history'  'Searching chat history'
    %'tlon_react'         'Adding a reaction'
    %'tlon_unreact'       'Removing a reaction'
    %'tlon_upload_image'  'Uploading an image'
    %'cron_add'           'Scheduling a task'
    %'reminder_add'       'Setting a reminder'
    %'cron_list'          'Checking schedules'
    %'cron_remove'        'Cancelling a schedule'
    %'call_mcp_tool'      'Using a connected service'
  ==
++  display
  |=  tools=(set @t)
  ^-  display:pr
  =/  names  ~(tap in tools)
  =/  text=@t  ?~(names 'Thinking...' ?~(t.names (label i.names) 'Using tools...'))
  =/  blob=json
    %-  pairs:enjs:format
    :~  ['protocol' %s 'tlon.computing-status.v1']
        ['thinking' %b =(~ tools)]
        :-  'toolCalls'
        :-  %a
        %+  turn  names
        |=  name=@t
        (pairs:enjs:format ~[['toolName' %s name] ['label' %s (label name)]])
    ==
  [~ `text `(en:json:html blob)]
++  context
  |=  to=destination:t
  ^-  path
  ?-  -.to
    %dm       /dm/(scot %p who.to)
    %channel  /channel/[kind.nest.to]/(scot %p ship.nest.to)/[name.nest.to]
  ==
++  merge
  |=  [active=(map path (set @t)) to=destination:t tools=(set @t)]
  ^+  active
  =/  ctx  (context to)
  (~(put by active) ctx (~(uni in tools) (~(gut by active) ctx ~)))
++  sync
  |=  [our=@p now=@da old=(map path presence-lease:t) active=(map path (set @t))]
  ^-  (quip card:agent:gall (map path presence-lease:t))
  =/  cards=(list card:agent:gall)  ~
  =/  next=(map path presence-lease:t)  ~
  =^  cards  next
    %+  roll  ~(tap by old)
    |=  [[ctx=path lease=presence-lease:t] acc=[cards=(list card:agent:gall) next=(map path presence-lease:t)]]
    ?:  (~(has by active) ctx)  acc
    :_  next.acc
    [[%pass /presence %agent [our %presence] %poke %presence-action-1 !>(`action-1:pr`[%clear ctx our %computing])] cards.acc]
  =/  seed=[cards=(list card:agent:gall) next=(map path presence-lease:t)]  [cards next]
  %+  roll  ~(tap by active)
  |=  [[ctx=path tools=(set @t)] acc=_seed]
  =/  previous  (~(get by old) ctx)
  ?:  ?&(?=(^ previous) =(tools tools.u.previous) (lth now (add at.u.previous ~s10)))
    [cards.acc (~(put by next.acc) ctx u.previous)]
  =/  status  (display tools)
  :_  (~(put by next.acc) ctx [now tools])
  [[%pass /presence %agent [our %presence] %poke %presence-action-1 !>(`action-1:pr`[%set ~ [ctx our %computing] `~s30 status])] cards.acc]
--
