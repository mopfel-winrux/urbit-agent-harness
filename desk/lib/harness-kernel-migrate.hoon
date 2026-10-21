::  Migrate outstanding kernel replies across the Gall userspace boundary.
::  These resources belong to saved agent state; no new requests use syscalls.
|%
++  gift
  |=  [=bowl:gall =wire gift=gift-user-v1:gall]
  ^-  gift-user-v1:gall
  ?.  ?=(%syscall -.gift)  gift
  =/  old  sign-arvo.gift
  ?+  old  ~|([%unrecognized-kernel-reply wire] !!)
      [%behn %wake *]
    =/  error  ;;((unit tang) +>.old)
    ?^  error  (mean u.error)
    [%behn %wake now.bowl]
      [%clay %writ *]
    [%clay %read ~ ;;(riot:clay +>.old)]
      [%eyre %bound *]
    =/  binding  ;;([accepted=? site=(unit @t) path=path] +>.old)
    [%eyre %bound accepted.binding path.binding dap.bowl]
      [%dill %blit *]
    ?>  ?=([%dill %session @ ~] wire)
    [%dill %blit i.t.t.wire ;;((list blit:dill) +>.old)]
      $%  [%ames %sage *]
          [%iris %http-response *]
          [%jael ?(%private-keys %public-keys) *]
          [%lick %soak *]
          [%dill %logs *]
      ==
    ;;(gift-user-v1:gall old)
  ==
--
