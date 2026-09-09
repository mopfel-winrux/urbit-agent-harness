::  Explicit ship-wide destinations; callers must hold the broad Tlon grant.
/-  t=harness-tlon
/+  spec=harness-tlon-tool, hp=harness-tlon-history-page, reader=harness-tlon-history-read
|_  bowl=bowl:gall
++  available
  |=  to=destination:t
  ^-  ?
  ?-  -.to
      %dm
    ?.  .^(? %gu /(scot %p our.bowl)/chat/(scot %da now.bowl)/$)  |
    .^(? %gu /(scot %p our.bowl)/chat/(scot %da now.bowl)/dm/(scot %p who.to))
      %channel
    ?.  .^(? %gu /(scot %p our.bowl)/channels/(scot %da now.bowl)/$)  |
    .^(? %gu /(scot %p our.bowl)/channels/(scot %da now.bowl)/v4/[kind.nest.to]/(scot %p ship.nest.to)/[name.nest.to])
  ==
++  history
  |=  [args=json search=?]
  ^-  json
  =/  to  (destination:spec args)
  ?>  (available to)
  =/  needle  ?:(search (query:hp args) '')
  =/  scope  (sham [%tlon our.bowl to needle])
  =/  before  (position:hp scope (string:spec args 'cursor' '' 256))
  =/  snapshot  (load:~(. reader bowl) to before ?:(search 65 21))
  (encode:hp scope (scan:hp rows.snapshot needle) parent.snapshot needle)
++  dms
  ^-  json
  ?>  .^(? %gu /(scot %p our.bowl)/chat/(scot %da now.bowl)/$)
  =/  accepted=(set @p)
    .^((set @p) %gx /(scot %p our.bowl)/chat/(scot %da now.bowl)/dm/ships)
  =/  invited=(set @p)
    .^((set @p) %gx /(scot %p our.bowl)/chat/(scot %da now.bowl)/dm/invited/ships)
  =/  rows  ~(tap in (~(uni in accepted) invited))
  =/  items
    %+  turn  (scag 100 rows)
    |=  who=@p
    (pairs:enjs:format ~[['ship' %s (scot %p who)] ['invited' %b (~(has in invited) who)]])
  (pairs:enjs:format ~[['items' %a items] ['has_more' %b (gth (lent rows) 100)]])
--
