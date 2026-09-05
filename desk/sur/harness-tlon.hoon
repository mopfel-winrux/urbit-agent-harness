::  Tlon-specific state belongs to a hand, never to the semantic head.
/-  c=tlon-channels, a=tlon-activity-ver
|%
+$  policy
  $:  enabled=?
      owner=(unit @p)
      trusted=(map @p (list term))
      mentions=?
  ==
+$  destination
  $%  [%dm who=@p parent=(unit message-id:a)]
      [%channel nest=nest:c parent=(unit @da)]
  ==
+$  input  [actor=@p event=@t to=destination text=@t]
+$  lane  [actor=@p to=destination epoch=@ud tools=(list term)]
+$  job  [input=input sid=@t stage=?(%create %bind %observe %error) error=@t]
+$  delivery  [attempt=@ud stage=?(%claim %send %receipt) status=?(%delivered %failed %uncertain) external=@t]
+$  notice  [sequence=@ud at=@da kind=@t actor=@p address=@t event=@t]
+$  presence-lease  [at=@da tools=?]
+$  state-0  [%0 data]
+$  state  [%1 computing=(map path presence-lease) data]
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
