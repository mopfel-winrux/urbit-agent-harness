::  Thin local client for the Harness Grubbery runtime.
::
/-  grub
|%
++  watch
  |=  [=ship chan=@ta]
  ^-  card:agent:gall
  [%pass /harness-grub/[chan] %agent [ship %harness-grub] %watch /client/[chan]]
::
++  send
  |=  [=ship chan=@ta =op:grub]
  ^-  card:agent:gall
  :*  %pass  /harness-grub-cmd/[chan]
      %agent  [ship %harness-grub]  %poke  %grub-cmd
      !>(`cmd:grub`[chan op])
  ==
::
++  take-fact
  |=  =sign:agent:gall
  ^-  (unit fact:grub)
  ?.  ?=(%fact -.sign)  ~
  ?.  =(%grub-fact p.cage.sign)  ~
  `!<(fact:grub q.cage.sign)
--
