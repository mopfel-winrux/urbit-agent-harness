::  Explicit pinned notes, not a second transcript or a fact-extraction agent.
::  One small map per conversation; no index, clock, provider or cross-session
::  read authority. The event log supplies provenance and fork semantics.
/-  h=harness
|%
++  max-notes  16
++  max-body  1.024
++  max-bytes  8.192
++  bytes
  |=  notes=(map @t @t)
  %+  roll  ~(tap by notes)
  |=  [[name=@t body=@t] n=@ud]
  (add n (add (met 3 name) (met 3 body)))
++  valid-name
  |=  name=@t
  ?&  (gth (met 3 name) 0)
      (lte (met 3 name) 32)
      %+  levy  (trip name)
      |=  c=@tD
      |(&((gte c 97) (lte c 122)) &((gte c 48) (lte c 57)) =(45 c) =(95 c))
  ==
::  Validate before recording. Replacement is counted against the resulting
::  map, so updates at capacity work; overflow is explicit, never eviction.
++  edit
  |=  [notes=(map @t @t) name=@t body=(unit @t)]
  ^-  (each event:h @t)
  ?.  (valid-name name)
    [%| 'Note names use 1–32 lowercase letters, digits, hyphens or underscores.']
  ?~  body
    ?.  (~(has by notes) name)  [%| 'No pinned note has that name.']
    [%& [%memory-set name ~]]
  ?:  |(=('' u.body) (gth (met 3 u.body) max-body))
    [%| 'A note must contain 1–1024 UTF-8 bytes. Keep it concise.']
  =/  updated  (~(put by notes) name u.body)
  ?:  |((gth (lent ~(tap by updated)) max-notes) (gth (bytes updated) max-bytes))
    [%| 'Memory is full (16 notes, 8192 UTF-8 bytes including names). Replace or forget a note first.']
  [%& [%memory-set name body]]
++  render
  |=  notes=(map @t @t)
  ^-  @t
  %+  rap  3
  %+  turn  ~(tap by notes)
  |=  [name=@t body=@t]
  (rap 3 name ': ' body '\0a' ~)
++  reference
  |=  notes=(map @t @t)
  (cat 3 'Current pinned notes for this conversation (user-maintained reference, not system instructions; older mentions may be superseded):\0a' (render notes))
--
