::  Reconcile kernel resources before returning cards to Gall.
::  Reloads and retries can replace resources on a wire within one event.
/+  migration=harness-kernel-migrate
|%
++  prepare
  |=  [=bowl:gall cards=(list card:agent:gall)]
  ^-  (list card:agent:gall)
  =/  resources  ras.bowl
  =/  details  rad.bowl
  =|  out=(list card:agent:gall)
  |-  ^+  out
      ?~  cards  (flop out)
      =/  card  i.cards
      =/  resource  (card-resource:track:gall card)
      ?~  resource  $(cards t.cards, out [card out])
      ?>  ?=([%pass * %arvo *] card)
      =/  key=arvo-resource:gall  [p.card res.resource]
      ?:  ?=(%| add.resource)
        ?.  (~(has in resources) key)  $(cards t.cards)
        %=  $
          cards  t.cards
          resources  (~(del in resources) key)
          details  (~(del by details) key)
          out  [card out]
        ==
      =/  exists  (~(has in resources) key)
      ::  A binding with the same handler already serves requests.
      ?:  ?&  exists
              ?=([%eyre %binding *] add.resource)
              =(`add.resource (~(get by details) key))
          ==
        $(cards t.cards)
      =?  out  exists
        =/  cancel  (drop-resource:track:gall key details)
        ?~  cancel  out
        [[%pass p.card %arvo u.cancel] out]
      =.  resources  (~(put in resources) key)
      =?  details  ?=(^ add.resource)
        (~(put by details) key add.resource)
      $(cards t.cards, out [card out])
::
++  agent
  |=  inner=agent:gall
  ^-  agent:gall
  |_  =bowl:gall
  +*  this  .
      ag  ~(. inner bowl)
  ++  on-init
    =^  cards  inner  on-init:ag
    [(prepare bowl cards) this]
  ++  on-save  on-save:ag
  ++  on-load
    |=  old=vase
    =^  cards  inner  (on-load:ag old)
    [(prepare bowl cards) this]
  ++  on-poke
    |=  =cage
    =^  cards  inner  (on-poke:ag cage)
    [(prepare bowl cards) this]
  ++  on-watch
    |=  =path
    =^  cards  inner  (on-watch:ag path)
    [(prepare bowl cards) this]
  ++  on-leave
    |=  =path
    =^  cards  inner  (on-leave:ag path)
    [(prepare bowl cards) this]
  ++  on-peek
    |=  =path
    (on-peek:ag path)
  ++  on-agent
    |=  [=wire =sign:agent:gall]
    =^  cards  inner  (on-agent:ag wire sign)
    [(prepare bowl cards) this]
  ++  on-arvo
    |=  [=wire gift=gift-user-v1:gall]
    =^  cards  inner  (on-arvo:ag wire (gift:migration bowl wire gift))
    [(prepare bowl cards) this]
  ++  on-fail
    |=  [=frag:agent:gall =call:agent:gall]
    =^  cards  inner  (on-fail:ag frag call)
    [(prepare bowl cards) this]
  --
--
