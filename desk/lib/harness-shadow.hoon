::  Independent replay/decision comparison. No I/O or provider authority.
/-  h=harness, sh=harness-shadow
/+  hs=harness-session
|%
++  digest
  |=  [session=session:h skills=(map @t skill:h)]
  ^-  @uvH
  (shas %harness-head (jam (inspect:hs session skills)))
++  check
  |=  input=input:sh
  ^-  json
  =/  actual  (digest session.input skills.input)
  (pairs:enjs:format ~[['version' (numb:enjs:format 1)] ['revision' (numb:enjs:format (lent log.session.input))] ['matched' %b =(expected.input actual)] ['expected' %s (scot %uv expected.input)] ['actual' %s (scot %uv actual)] ['input' %s (scot %uv (shas %shadow-input (jam input)))]])
--
