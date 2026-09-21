::  Full head projection with synthetic Tlon authority; no cards execute.
/-  h=harness, wc=harness-work-control, *harness-store
/+  *test, policy=harness-defaults, control=harness-work-control, corpus=harness-corpus, view=harness-work-view, j=harness-workspace-json
/=  head  /app/harness
|%
++  read
  |=  [saved=state-0 allowed=?]
  ^-  (unit @t)
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.13)
  =/  attempt
    |.
    =/  loaded  (~(on-load head bowl) !>(saved))
    =/  peek  (~(on-peek +.loaded bowl) /x/work-card/0v4)
    ?>  ?=(^ peek)
    ?>  ?=(^ u.peek)
    q.u.u.peek
  =/  checked
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  (lien path |=(part=@ta =(%peer-trust part)))  ``[[& `~zod ~ &] |]
    ?:  (lien path |=(part=@ta =(%authority part)))  ``[allowed ~]
    ?:  (lien path |=(part=@ta =(%admin part)))  ``allowed
    ?:  =(%$ (rear path))  ``&
    ``%.n
  ?>  ?=(%0 -.checked)
  ;;((unit @t) +.product.checked)
++  test-card-needs-current-owner-binding-and-receipt
  =/  saved=state-0  *state-0
  =.  saved  saved(welcome-seen 1, defaults builtin-config:policy)
  =/  source=input-source:h  [%hand 'binding' 'tlon' 'dm/~zod' 'event' '~zod']
  =/  args  (pairs:enjs:format ~[['id' %s 'meeting'] ['title' %s 'Meeting']])
  =/  request=request:wc
    ['social' 0v1 source ~ 'project-create' args (snapshot:control workspace.saved 'project-create' args) ~2026.9.13..00.15.00 %pending ~]
  =/  text  (receipt:view (encode:control 0v3 request))
  =/  input=admitted-input:h  [0v4 source ~ `[%hand 'binding'] ~2026.9.13 [%user '/work project-create']]
  =.  sessions.saved  (my ~[['social' [~[[%command-completed 0v4 'work' text] [%input-received input] [%config-replaced defaults.saved]] 0]]])
  =.  corpus.saved  (sync:corpus corpus.saved sessions.saved)
  =.  requests.work-controls.saved  (my ~[[0v3 request]])
  =.  bindings.hands.saved  (my ~[['binding' ['tlon' 'dm/~zod' 'social' ~['~zod'] &]]])
  =.  observations.hands.saved  (my ~[[0v4 ['binding' 'event' '~zod' '/work project-create' ~2026.9.13 %completed]]])
  =.  outbox.hands.saved  (my ~[[0v4 [0v4 'binding' 'tlon' 'dm/~zod' 'social' %reply text %pending '' '' ~]]])
  ;:  weld
    (expect !>(?=(^ (read saved &))))
    (expect-eq !>(~) !>((read saved |)))
    (expect-eq !>(~) !>((read saved(bindings.hands ~) &)))
    (expect-eq !>(~) !>((read saved(requests.work-controls ~) &)))
    (expect-eq !>(~) !>((read saved(observations.hands ~) &)))
  ==
++  test-navigation-card-needs-no-approval-request
  =/  saved=state-0  *state-0
  =.  saved  saved(welcome-seen 1, defaults builtin-config:policy)
  =/  source=input-source:h  [%hand 'binding' 'tlon' 'dm/~zod' 'event' '~zod']
  =/  args  (need (arguments:view 'projects' ''))
  =/  text  (render:view 'projects' args (read:j workspace.saved [& [0v0 'Owner'] 0v0] 'projects' args))
  =/  input=admitted-input:h  [0v4 source ~ `[%hand 'binding'] ~2026.9.13 [%user '/work projects']]
  =.  sessions.saved  (my ~[['social' [~[[%command-completed 0v4 'work' text] [%input-received input] [%config-replaced defaults.saved]] 0]]])
  =.  corpus.saved  (sync:corpus corpus.saved sessions.saved)
  =.  bindings.hands.saved  (my ~[['binding' ['tlon' 'dm/~zod' 'social' ~['~zod'] &]]])
  =.  observations.hands.saved  (my ~[[0v4 ['binding' 'event' '~zod' '/work projects' ~2026.9.13 %completed]]])
  =.  outbox.hands.saved  (my ~[[0v4 [0v4 'binding' 'tlon' 'dm/~zod' 'social' %reply text %pending '' '' ~]]])
  ;:  weld
    (expect !>(?=(^ (read saved &))))
    (expect-eq !>(~) !>((read saved |)))
    (expect-eq !>(~) !>((read saved(bindings.hands ~) &)))
    (expect-eq !>(~) !>((read saved(observations.hands ~) &)))
    (expect-eq !>(~) !>((read saved(sessions (~(put by sessions.saved) 'social' [~[[%input-received input] [%config-replaced defaults.saved]] 0])) &)))
  ==
--
