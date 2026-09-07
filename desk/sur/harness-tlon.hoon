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
  [%4 tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease-0) data]
+$  state-5
  [%5 tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease) data]
+$  state-6
  [%6 last-sent=@da tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease) data]
+$  media-config  [url=@t token=@t]
+$  upload-7
  [stage=?(%fetch %put %put-no-acl) storage=@uv key=@t mime=@t public-url=@t bytes=octs]
+$  state-7
  [%7 media=media-config uploads=(map @uv upload-7) last-sent=@da tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease) data]
+$  upload
  [stage=?(%fetch %put %put-no-acl %grant %hosted-put) storage=@uv key=@t mime=@t public-url=@t bytes=octs]
+$  state-8
  [%8 media=media-config uploads=(map @uv upload) last-sent=@da tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease) data]
+$  state-9
  [%9 uploads=(map @uv upload) last-sent=@da tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease) data]
+$  lens-export
  [owner=@p revision=@ud digest=@uv status=?(%queued %sending %accepted %failed %revoked) at=@da sent=(unit @da)]
+$  state-10
  [%10 lens-after=@da lenses=(map @uv lens-export) uploads=(map @uv upload) last-sent=@da tool-receipts=(map @uv tool-receipt) cron=(map @uv job-0:cron) computing=(map path presence-lease) data]
+$  route  [binding=@t phase=?(%ready %create %fence %config)]
+$  state-11
  $:  %11
      identities=(map [actor=@p to=destination] @t)
      routes=(map @t route)
      cuts=(map @p @da)
      channel-after=@da
      lens-after=@da
      lenses=(map @uv lens-export)
      uploads=(map @uv upload)
      last-sent=@da
      tool-receipts=(map @uv tool-receipt)
      cron=(map @uv job-0:cron)
      computing=(map path presence-lease)
      data
  ==
+$  state-12
  $:  %12
      identities=(map [actor=@p to=destination] @t)
      routes=(map @t route)
      cuts=(map @p @da)
      channel-after=@da
      lens-after=@da
      lenses=(map @uv lens-export)
      uploads=(map @uv upload)
      last-sent=@da
      tool-receipts=(map @uv tool-receipt)
      cron=(map @uv job:cron)
      computing=(map path presence-lease)
      data
  ==
+$  state-13
  $:  %13
      activity-through=@da
      catching-up=$~(| ?)
      identities=(map [actor=@p to=destination] @t)
      routes=(map @t route)
      cuts=(map @p @da)
      channel-after=@da
      lens-after=@da
      lenses=(map @uv lens-export)
      uploads=(map @uv upload)
      last-sent=@da
      tool-receipts=(map @uv tool-receipt)
      cron=(map @uv job:cron)
      computing=(map path presence-lease)
      data
  ==
+$  state
  $:  %14
      activity-through=@da
      catching-up=$~(| ?)
      identities=(map [actor=@p to=destination] @t)
      routes=(map @t route)
      cuts=(map @p @da)
      channel-after=@da
      uploads=(map @uv upload)
      last-sent=@da
      tool-receipts=(map @uv tool-receipt)
      cron=(map @uv job:cron)
      computing=(map path presence-lease)
      data
  ==
+$  data
  $:  policy=policy
      epoch=@ud
      after=@da
      lanes=(map @t lane)  ::  admitted authorization generations; head keeps history
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
