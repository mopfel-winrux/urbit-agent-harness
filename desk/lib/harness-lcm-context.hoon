::  Pure, source-addressed planning. The head supplies provider estimates and
::  resolved model policy; this module cannot dispatch or obtain credentials.
/-  h=harness
/+  context=harness-context, lcm=harness-lcm
|%
++  plan
  |=  $:  v=view:h
          through=@ud
          command=(unit input-id:h)
          leaf=config:h
          branch=config:h
          estimate=$-(view:h @ud)
      ==
  ^-  (each lcm-plan:h @t)
  ?:  |(?=(^ pending.v) !=(~ wait.v))
    [%| 'Compaction waits for inference and tools to settle.']
  ?:  (gte compact-attempts.v 4)
    [%| 'Compaction attempt limit reached; change the model or reduce the request.']
  =/  children  (group:lcm lcm.v)
  ?:  !=(~ children)
    |-  ^-  (each lcm-plan:h @t)
    =/  source  (text:lcm lcm.v children)
    =/  candidate  v(config branch, summary ~, items ~[[%user source]])
    =/  input  (estimate candidate)
    ?:  (gth input (input-budget:context max-context.branch))
      ?:  (lte (lent children) 2)
        [%| 'Summary nodes exceed the LCM model input budget; choose a larger LCM model.']
      $(children (scag 2 `(list @ud)`children))
    [%& [through 0 (lent items.v) (source-hash:context v 0) input (output-budget:context max-context.branch) url.branch model.branch command] ~ children]
  =/  selected
    (plan-for:context v(config leaf, summary ~) through command max-context.config.v estimate)
  ?:  ?=(%| -.selected)  selected
  =/  p  p.selected
  =/  sources  (scag count.p positions.v)
  ?.  =(count.p (lent sources))
    [%| 'Compaction source addresses are unavailable; the previous context was retained.']
  [%& p(source (source-hash:context v count.p)) sources ~]
::  Reconstruct exactly the selected request, using the frozen sources. The
::  existing provider codec labels it as reference material and removes tools.
++  request
  |=  [v=view:h p=lcm-plan:h cfg=config:h]
  ^-  view:h
  =/  items
    ?~  children.p  (scag count.checkpoint.p items.v)
    `(list item:h)`~[[%user (text:lcm lcm.v children.p)]]
  v(config cfg, summary ~, items items, memory ~)
++  validate
  |=  [v=view:h p=lcm-plan:h stop=stop-reason:h it=item:h]
  ^-  (unit @t)
  ?.  =(source.checkpoint.p (source-hash:context v count.checkpoint.p))
    `'Compaction source coverage changed; the previous context was retained.'
  ?.  =(sources.p (scag count.checkpoint.p positions.v))
    `'Compaction source addresses changed; the previous context was retained.'
  =/  source  (request v p config.v)
  =/  count  (lent items.source)
  ::  Validate reduction against the selected source only, not unrelated
  ::  summaries that happen to share the conversation's active context.
  (validate:context source checkpoint.p(count count, source (source-hash:context source count)) stop it)
--
