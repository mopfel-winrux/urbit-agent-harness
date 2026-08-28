::  This is hawk-500 script, meant to be pasted into a %hawk page
::  Imports are fixed by the environment, so we build thread-builder
::  dynamically. When this runs for the first time it may take up to ~m1
::  to build the whole stack (urwasm, groups API, thread builder).
::  Successive invocations will be much faster
::
!:
:-  %shed
=/  m  (strand ,vase)
^-  form:m
|^
=/  desk-name=desk  %threads
;<  bol=bowl:rand  bind:m  get-bowl
=/  builder-beam=beam
  :-  [our.bol desk-name da+now.bol]
  /lib/thread-builder-js/hoon
::
;<  builder-vax=vase  bind:m  (build-file-hard builder-beam)
=/  cod=tape  get-code
?~  cod  (pure:m !>(`manx`(render ~)))
=/  shed-vax=vase  (slam builder-vax !>((crip cod)))
=+  !<(=shed:khan shed-vax)
;<  res=thread-result  bind:m  (await-shed desk-name shed)
%-  pure:m  !>
^-  manx
(render `res)
::
+$  thread-result
  (each vase (pair term tang))
::  defined in thread-builder-js.hoon
::
+$  shed-result
  [%0 p=(each cord (pair cord cord))]
::
++  await-shed
  |=  [=desk =shed:khan]
  =/  m  (strand thread-result)
  ;<  =bowl:spider  bind:m  get-bowl
  =/  tid  (scot %ta (cat 3 'strand_js_' (scot %uv (cut 7 [0 1] eny.bowl))))
  =/  poke-vase
    !>  ^-  inline-args:spider
    [`tid.bowl `tid [our.bowl desk da+now.bowl] shed]
  ::
  =/  wir=wire  /awaiting/[tid]
  ;<  ~      bind:m  (watch-our wir %spider /thread-result/[tid])
  ;<  ~      bind:m  (poke-our %spider %spider-inline poke-vase)
  ;<  =cage  bind:m  (take-fact wir)
  ;<  ~      bind:m  (take-kick wir)
  ?+  p.cage  ~|([%strange-thread-result p.cage file tid] !!)
    %thread-done  (pure:m %& q.cage)
    %thread-fail  (pure:m %| !<([term tang] q.cage))
  ==
::
++  render
  |=  result=(unit thread-result)
  ^-  manx
  =/  output=tape
    ?~  result  ""
    ?:  ?=(%| -.u.result)
      """
      JS script failed

      Thread error:
      {(of-wall:format (zing (turn q.p.u.result (cury wash [0 80]))))}
      """
    =+  !<(=shed-result p.u.result)
    =/  js-result  p.shed-result
    ?:  ?=(%& -.js-result)
      """
      JS script ran succesfully:

      {(trip p.js-result)}
      """
    """
    JS script failed

    JS eval error:
    {(trip p.p.js-result)}
    {(trip q.p.js-result)}
    """
  ::
  ;div.wf.hf.fc
    ;form.fc.grow
      =method  "post"
      =hx-swap  "none"
      =style  "flex:0 0 50%;min-height:0"
      ;textarea#code-val-el.b0.grow.p2.mono
        =name  "/code-val"
        =placeholder  "Paste JavaScript code here"
        ;-  get-code
      ==
      ;button.p2.hover.b1.bd1.loader
        ;span.loaded: submit
        ;span.loading.o5: loading
      ==
    ==
    ::
    ;div#output.b0.grow.p2.pre.mono
      =style  """
              flex: 0 0 50%;
              min-height: 0;
              overflow-y: auto;
              white-space: pre-wrap;
              word-break: break-word;
              """
      ::
      ;+  refresher
      ;-  output
    ==
  ==
++  get-code
  ^-  tape
  ?^  x=(peb:c /code-val)  u.x
  =,  mq
  %-  zing
  %-  text-content
  (get-id "code-val-el" dat:f)
  ::
++  refresher
  ;div.hidden
    =hx-get  "?data"
    =hx-target  "#output"
    =hx-select  "#output"
    =hx-swap  "outerHTML"
    =hx-trigger  "load delay:3s"
    ;div.loader.mono.tc.wfc.pre.hidden
      ;span.loaded:       
      ;div.loading: loading
    ==
  ==
--