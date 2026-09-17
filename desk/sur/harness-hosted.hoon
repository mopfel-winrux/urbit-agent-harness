::  Login work belongs to the ship, not an HTTP request or a conversation.
|%
+$  flow  [token-expires=(unit @da) flow-0]
+$  flow-0
  $:  provider=@t
      phase=?(%code %poll %exchange %verify %token %done %error)
      expires=@da
      base=@uvH
      serial=@ud
      pending=?
      deadline=@da
      interval=@ud
      device=@t
      user-code=@t
      verification=@t
      token=@t
      refresh=@t
      account=@t
      error=@t
  ==
+$  catalog  [identity=@uvH models=json]
+$  state
  [flows=(map @t flow) catalogs=(map @t catalog)]
+$  state-0
  [flows=(map @t flow-0) catalogs=(map @t catalog)]
+$  request  [id=@t action=@t args=json]
--
