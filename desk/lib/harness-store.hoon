::  Gall persistence accepts the current tagged envelope.
/-  *harness-store
/-  h=harness, c=harness-corpus
|%
++  load
  |=  saved=vase
  ^-  state-0
  =/  state  (envelope saved)
  =/  sessions
    %-  ~(run by sessions.state)
    |=  ses=session:h
    ses(log (turn log.ses migrate-event))
  ::  Scope IDs are authority references: preserve them and their index while
  ::  updating the cached copies of configuration events and projected routes.
  =.  scopes.corpus.state  (~(run by scopes.corpus.state) migrate-conversation)
  %=  state
    sessions  sessions
    defaults  (migrate-config defaults.state)
    peer-base  (bind peer-base.state migrate-config)
    summary-models  [(bind compaction.summary-models.state migrate-config) (bind lcm.summary-models.state migrate-config)]
  ==
++  migrate-conversation
  |=  old=conversation:c
  =/  view  view.old
  =/  route  route.view
  =?  route  ?=(^ route)  `[req.u.route (migrate-config config.u.route)]
  %=  old
    seen  (turn seen.old migrate-event)
    reverse  (turn reverse.old migrate-event)
    forward  (turn forward.old migrate-event)
    incoming  (turn incoming.old migrate-event)
    view  view(config (migrate-config config.view), route route)
  ==
++  migrate-config
  |=  cfg=config:h
  ?:  =('https://api.openai.com/v1/chat/completions' url.cfg)
    cfg(url 'https://api.openai.com/v1/responses')
  ?:  =('https://api.anthropic.com/v1/chat/completions' url.cfg)
    cfg(url 'https://api.anthropic.com/v1/messages')
  cfg
++  migrate-event
  |=  e=event:h
  ^-  event:h
  ?:  ?=(%config-replaced -.e)  e(config (migrate-config config.e))
  ?:  ?=(%llm-routed -.e)  e(config (migrate-config config.e))
  e
++  envelope
  |=  saved=vase
  ^-  state-0
  ::  new shape loads directly (fresh install or re-load).
  =/  cur  (mole |.(!<(state-0 saved)))
  ?^  cur  u.cur
  ::  migrate pre-js-timeouts state: carry every field, default the new map.
  =/  o  !<(state-le saved)
  :*  %0
      model-defaults-set.o  xai-auth.o  hosted.o  workspace.o  work-controls.o
      project-clients.o  workspace-search.o  workspace-notes.o  schedules.o  schedule-wake.o
      local-mcp-seen.o  local-mcp.o  peer-receipts.o  peer-active.o  remote-access.o
      announced-access.o  welcome-seen.o  peer-budget-resets.o  peer-limits.o  summary-models.o
      corpus.o  corpus-wake.o  modified.o  sessions.o  timers.o  subs.o  skills.o  staged.o
      rehearsals.o  peers.o  peer-base.o  asks.o  serving.o  jobs.o  api-key.o  acp-prompts.o
      acp-through.o  provider-keys.o  model-requests.o  next-model-request.o  defaults.o
      mcp-servers.o  streams.o  hands.o  openai-auth.o  search-config.o  search-requests.o
      ~
  ==
--
