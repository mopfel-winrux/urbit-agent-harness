::  The HTTP lifetime covers admission and a sanitized reply, never a login.
/-  spider, hosted=harness-hosted
/+  io=strandio, j=harness-workspace-json
=,  strand=strand:spider
|%
++  call
  |=  [action=@t arg=vase]
  (call-to %harness action arg)
++  call-to
  |=  [agent=@tas action=@t arg=vase]
  =/  m  (strand ,vase)
  ^-  form:m
  =/  input  !<((unit json) arg)
  =/  args=json  (fall input [%o ~])
  ?>  ?=(%o -.args)
  ?>  (lte (met 3 (en:json:html args)) 16.384)
  ;<  our=@p  bind:m  get-our:io
  ;<  now=@da  bind:m  get-time:io
  ;<  entropy=@uvJ  bind:m  get-entropy:io
  =/  id  (scot %uv (sham [our now entropy action]))
  =?  p.args  &(!(~(has in (silt ~['settings' 'permissions' 'channels'])) action) ?~((optional:j args 'requestId') & |))
    (~(put by p.args) 'requestId' [%s id])
  ;<  ~  bind:m  (watch:io /response [our agent] /hosted/[id])
  ;<  ~  bind:m  (poke:io [our agent] %harness-hosted !>(`request:hosted`[id action args]))
  ;<  result=cage  bind:m  (take-fact:io /response)
  ?>  =(%json p.result)
  (pure:m !>(!<(json q.result)))
--
