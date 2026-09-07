::  Admission budgets, not pruning rules. Existing queues survive upgrades
::  even above these limits; acknowledgements and explicit close release them.
/-  ac=acp
|%
++  usage
  |=  queue=(map @ud message:v1:ac)
  ^-  [count=@ud bytes=@ud]
  %+  roll  ~(val by queue)
  |=  [message=message:v1:ac out=[count=@ud bytes=@ud]]
  [+(count.out) (add bytes.out (met 3 payload.message))]
++  room
  |=  [connections=(map connection-id:v1:ac connection:v1:ac) id=connection-id:v1:ac target=peer:v1:ac payload=@t]
  ^-  ?
  =/  con  (~(got by connections) id)
  =/  local  (usage ?:(=(target %client) to-client.con to-agent.con))
  =/  size  (met 3 payload)
  ?.  ?&((lth count.local 1.024) (lte (add size bytes.local) 4.194.304))  |
  =/  total
    %+  roll  ~(val by connections)
    |=  [con=connection:v1:ac out=[count=@ud bytes=@ud]]
    =/  client  (usage to-client.con)
    =/  agent  (usage to-agent.con)
    [:(add count.out count.client count.agent) :(add bytes.out bytes.client bytes.agent)]
  ?&((lth count.total 8.192) (lte (add size bytes.total) 16.777.216))
--
