::  Sparse operational events through the ship's existing Groups log sink.
::  No transcript scans, retained telemetry state, or exporter in Harness.
/-  h=harness, l=tlon-logs
/+  logs=tlon-logs, failure=harness-failure
|%
++  summary
  |=  e=event:h
  ^-  (unit [level=volume:l name=@t data=log-data:l])
  ?+  -.e  ~
    %llm-completed
      ?.  =(%stop stop.e)  ~
      ::  Usage belongs to this final request, not the preceding tool rounds.
      `[%info 'harness.turn.completed' ~[['request' (numb:enjs:format req.e)] ['prompt_tokens' (numb:enjs:format prompt.usage.e)] ['completion_tokens' (numb:enjs:format completion.usage.e)]]]
    %llm-failed
      `[%error 'harness.inference.failed' ~[['request' (numb:enjs:format req.e)] ['kind' %s kind:(describe:failure err.e)]]]
    %compaction-failed
      `[%error 'harness.compaction.failed' ~[['request' (numb:enjs:format req.e)] ['kind' %s kind:(describe:failure err.e)]]]
    %halted
      `[%warn 'harness.turn.halted' ~[['kind' %s kind:(describe:failure reason.e)]]]
    %cancelled
      `[%info 'harness.turn.cancelled' ~]
  ==
++  tell
  |=  [=bowl:gall sid=@t level=volume:l name=@t data=log-data:l]
  ^-  card:agent:gall
  ::  Session names can contain user text; only a correlation hash leaves.
  =.  data  [['session' %s (scot %uv (sham sid))] data]
  (~(tell logs bowl /telemetry) level ~[leaf+(trip name)] data)
++  event
  |=  [=bowl:gall sid=@t e=event:h]
  ^-  (list card:agent:gall)
  =/  entry  (summary e)
  ?~  entry  ~
  ~[(tell bowl sid level.u.entry name.u.entry data.u.entry)]
++  crash
  |=  [=bowl:gall hook=term trace=tang]
  ^-  card:agent:gall
  ::  Stack traces may contain credentials or user input. Keep them local;
  ::  export only the Gall hook and a hash to correlate repeated failures.
  (~(tell logs bowl /telemetry) %error ~[leaf+"harness.agent.failed"] ~[['hook' %s hook] ['failure' %s (scot %uv (sham trace))]])
--
