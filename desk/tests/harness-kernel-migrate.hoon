/+  *test, migration=harness-kernel-migrate
|%
++  bowl
  =/  bowl  *bowl:gall
  bowl(now ~2026.1.1, dap %harness)
++  test-current-gifts-keep-their-payload
  =/  gift=gift-user-v1:gall  [%behn %wake ~2026.1.2]
  (expect-eq !>(gift) !>((gift:migration bowl /timer gift)))
++  test-outstanding-timer-migrates
  %+  expect-eq
    !>([%behn %wake ~2026.1.1])
  !>((gift:migration bowl /timer [%syscall 408 [%behn %wake ~]]))
++  test-outstanding-clay-read-migrates
  =/  =riot:clay  `[[%z da+~2026.1.1 %harness] /web %noun !>(~)]
  %+  expect-eq
    !>([%clay %read ~ riot])
  !>((gift:migration bowl /clay/next/web [%syscall 408 [%clay %writ riot]]))
++  test-outstanding-http-response-keeps-body
  =/  gift=gift-user-v1:gall
    [%iris %http-response %finished [200 ~] `['text/plain' [5 'hello']]]
  %+  expect-eq  !>(gift)
  !>((gift:migration bowl /request [%syscall 408 gift]))
++  test-failed-timer-does-not-become-success
  =/  error=(unit tang)  `~[leaf+"timer failed"]
  =/  result  (mule |.((gift:migration bowl /timer [%syscall 408 [%behn %wake error]])))
  (expect !>(?=(%| -.result)))
--
