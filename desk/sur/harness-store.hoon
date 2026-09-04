::  Gall persistence envelope. Keep its noun layout stable: on-save writes this
::  directly, and harness-store loads each supported version without dropping
::  sessions or credentials. Runtime bookkeeping is not session semantics.
/-  h=harness, hh=harness-hand, ac=acp
|%
+$  stream-progress  [body=@t sent=@ud]
+$  state-0
  $:  %0
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h json)
      acp-through=@ud
  ==
+$  state-1
  $:  %1
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [request-id=json cursor=@ud])
      acp-through=@ud
  ==
+$  state-2
  $:  %2
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
  ==
+$  state-3
  $:  %3
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
  ==
+$  state-4
  $:  %4
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
  ==
+$  state-5
  $:  %5
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config:h
      mcp-servers=(map mcp-server-id:h mcp-server:h)
  ==
+$  state-6
  $:  %6
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config:h
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
  ==
+$  state-7
  $:  %7
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config:h
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state-0:hh
  ==
+$  state-8
  $:  %8
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config:h
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
  ==
--
