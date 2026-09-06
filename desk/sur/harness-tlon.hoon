::  Tlon-specific state belongs to a hand, never to the semantic head.
/-  c=tlon-channels, a=tlon-activity-ver, h=harness, ad=harness-adapter, cron=harness-cron
|%
+$  policy
  $:  enabled=?
      owner=(unit @p)
      trusted=(map @p (list tool-grant:h))
      mentions=?
  ==
+$  destination
  $%  [%dm who=@p parent=(unit message-id:a)]
      [%channel nest=nest:c parent=(unit @da)]
  ==
+$  input  [actor=@p event=@t to=destination text=@t]
+$  lane  [actor=@p to=destination epoch=@ud tools=(list tool-grant:h)]
+$  job  [input=input sid=@t stage=?(%create %bind %observe %error) error=@t]
+$  delivery  [attempt=@ud stage=?(%claim %send %receipt) status=?(%delivered %failed %uncertain) external=@t]
+$  publication-proof  [to=destination sent=@da id=@da]
+$  notice  [sequence=@ud at=@da kind=@t actor=@p address=@t event=@t]
+$  presence-lease-0  [at=@da tools=?]
+$  presence-lease  [at=@da tools=(set @t)]
+$  state-0  [%0 data]
+$  state-1  [%1 computing=(map path presence-lease-0) data]
+$  state-2  [%2 computing=(map path presence-lease-0) data]
+$  state-3  [%3 computing=(map path presence-lease-0) data]
+$  tool-receipt
  [request=tool-request:ad stage=?(%sending %done %uncertain) body=@t at=@da]
+$  state-4
  [%4 tool-receipts=(map @uv tool-receipt) cron=(map @uv job:cron) computing=(map path presence-lease-0) data]
+$  state-5
  [%5 tool-receipts=(map @uv tool-receipt) cron=(map @uv job:cron) computing=(map path presence-lease) data]
+$  state
  [%6 last-sent=@da tool-receipts=(map @uv tool-receipt) cron=(map @uv job:cron) computing=(map path presence-lease) data]
+$  data
  $:  policy=policy
      epoch=@ud
      after=@da
      lanes=(map @t lane)  ::  current permission epoch only; head keeps history
      jobs=(map @uv job)
      deliveries=(map @uv delivery)
      notices=(list notice)
      next-notice=@ud
      listeners=(set @t)
      watching=?
      wake=(unit @da)
      error=@t
  ==
--
