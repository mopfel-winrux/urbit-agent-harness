::  The full head names its operating ship in each outbound turn, from the
::  bowl rather than session configuration. Inspect outbound cards only.
/-  h=harness, *harness-store, renew=harness-oauth
/+  *test, policy=harness-defaults, w=harness-provider-wire
/=  head  /app/harness
|%
++  planet  ~sampel-palnet
::  Jael answers the sponsor scry; every other scry is refused.
::
++  isolated
  |=  attempt=$-(* tang)
  =/  result
    %+  mink  [attempt %9 2 %0 1]
    |=([ref=* pax=*] ?:(?=([%j @ %sein *] pax) ``planet ``%.n))
  ?>  ?=(%0 -.result)
  ;;(tang product.result)
++  starts
  |=  [prefix=@t text=@t]
  ^-  ?
  =(prefix (end [3 (met 3 prefix)] text))
::  +instructions: system text of the first turn the head sends as .our
::
++  instructions
  |=  our=@p
  ^-  @t
  =/  =bowl:gall  *bowl:gall
  =.  bowl  bowl(our our, src our, now ~2026.10.5)
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(url 'https://openrouter.ai/api/v1/chat/completions', tools ~)
  =/  saved=state-0  *state-0
  =.  saved
    %=  saved  defaults  cfg  local-mcp-seen  1
      provider-keys  (my ~[['openrouter' 'fixture-key']])
      sessions  (my ~[['fixture' [~[[%config-replaced cfg]] 0]]])
    ==
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  sent
    %+  ~(on-poke +.loaded bowl)
      %harness-action
    !>(`action:h`[%send 'fixture' 'Which ship are you?'])
  =/  requests=(list http-card:renew)
    %+  murn  -.sent
    |=  c=card:agent:gall
    ^-((unit http-card:renew) ?:(?=([%pass [%llm *] %arvo %i %request *] c) `c ~))
  ?>  ?=([* ~] requests)
  =/  body  (need (de:json:html q:(need body.request.i.requests)))
  =/  messages  (need (get:w body 'messages'))
  ?>  ?=([%a ^] messages)
  ?>  =('system' (str:w i.p.messages 'role'))
  (str:w i.p.messages 'content')
::
++  test-a-planet-turn-names-the-ship
  %-  isolated
  |=  ignored=*
  =/  text  (instructions planet)
  ;:  weld
      %-  expect
      !>((starts 'Your Urbit ship is ~sampel-palnet. References to ~sampel-palnet ' text))
      (expect !>(?=(^ (find "You are Harness, an agent" (trip text)))))
  ==
++  test-a-moon-turn-names-the-ship-and-its-parent
  %-  isolated
  |=  ignored=*
  =/  moon=@p  (add planet (lsh 5 1))
  =/  lead  (rap 3 ~['Your Urbit ship is ' (scot %p moon) ', a moon of ~sampel-palnet. '])
  (expect !>((starts lead (instructions moon))))
--
