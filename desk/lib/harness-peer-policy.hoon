::  Pure incoming-peer policy and its owner-facing projection. Explicit
::  overrides win; inherited trust is a live input, never duplicated state.
/-  h=harness
/+  hj=harness-json, ht=harness-tools
|%
++  effective
  |=  [explicit=(map @p peer-grant:h) trusted=(map @p peer-grant:h) limits=(map @p @ud)]
  ^-  (map @p peer-grant:h)
  =.  trusted
    %-  malt
    %+  turn  ~(tap by trusted)
    |=  [ship=@p grant=peer-grant:h]
    [ship grant(budget (fall (~(get by limits) ship) budget.grant))]
  (~(gas by trusted) ~(tap by explicit))
++  revision
  |=  [explicit=(map @p peer-grant:h) trusted=(map @p peer-grant:h) config=(unit config:h) limits=(map @p @ud)]
  ^-  @t
  (scot %uv (sham [explicit trusted config limits]))
++  grant-json
  |=  [ship=@p grant=peer-grant:h]
  ^-  json
  %-  pairs:enjs:format
  :~  ['ship' %s (scot %p ship)]
      ['tools' %a (turn tools.grant grant-json:hj)]
      ['model' ?~(model.grant ~ [%s u.model.grant])]
      ['budget' (numb:enjs:format budget.grant)]
      ['inflows' %a (turn ~(tap in inflows.grant) |=(name=@t `json`[%s name]))]
  ==
++  settings-json
  |=  [our=@p explicit=(map @p peer-grant:h) trusted=(map @p peer-grant:h) config=(unit config:h) limits=(map @p @ud)]
  ^-  json
  %-  pairs:enjs:format
  :~  ['ship' %s (scot %p our)]
      ['revision' %s (revision explicit trusted config limits)]
      ['grants' %a (turn ~(tap by explicit) grant-json)]
      ['trusted' %a (turn ~(tap by trusted) grant-json)]
      ['config' ?~(config ~ (config-json:hj u.config))]
      ['limits' %a (turn ~(tap by limits) |=([ship=@p budget=@ud] (pairs:enjs:format ~[['ship' %s (scot %p ship)] ['budget' (numb:enjs:format budget)]])))]
  ==
++  json-grants
  |=  jon=json
  ^-  (map @p peer-grant:h)
  =,  dejs:format
  =/  rows=(list [p=@p q=peer-grant:h])
    ((ar (ot ~[ship+(se %p) tools+(ar json-grant:hj) model+(mu so) budget+ni inflows+(cu silt (ar so))])) jon)
  ?>  (lte (lent rows) 64)
  =/  out=(map @p peer-grant:h)  (malt rows)
  ?>  =(~(wyt by out) (lent rows))
  ?>  %+  levy  rows
      |=  [ship=@p g=peer-grant:h]
      ?&  (lte budget.g 9.007.199.254.740.991)
          ?~(model.g & &(!=('' u.model.g) (lte (met 3 u.model.g) 512)))
          (lte (lent tools.g) 64)
          (levy tools.g |=(g=tool-grant:h ?:(?=(^ g) & (lien configurable-tools:ht |=(known=term =(g known))))))
          (lte ~(wyt in inflows.g) 256)
          (levy ~(tap in inflows.g) |=(name=@t &(!=('' name) (lte (met 3 name) 128))))
      ==
  out
++  json-limits
  |=  jon=json
  ^-  (map @p @ud)
  =/  rows=(list [p=@p q=@ud])
    ((ar:dejs:format (ot:dejs:format ~[ship+(se:dejs:format %p) budget+ni:dejs:format])) jon)
  ?>  (lte (lent rows) 256)
  ?>  (levy rows |=([p=@p q=@ud] (lte q 9.007.199.254.740.991)))
  =/  out=(map @p @ud)  (malt rows)
  ?>  =(~(wyt by out) (lent rows))
  out
++  json-config
  |=  jon=json
  ^-  (unit config:h)
  ?~  jon  ~
  ?>  ?=(%o -.jon)
  =/  cfg  (json-config:hj [%o (~(put by p.jon) 'key' [%s ''])])
  ?>  &(!=('' model.cfg) (lte (met 3 model.cfg) 512) (gth max-context.cfg 0))
  ?>  |(=('http://' (end [3 7] url.cfg)) =('https://' (end [3 8] url.cfg)))
  `cfg(key '', tools ~)
--
