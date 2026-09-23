::  Gall persistence accepts the current tagged envelope.
/-  *harness-store
|%
++  load
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
