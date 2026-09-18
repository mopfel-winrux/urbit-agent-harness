::  Clear provider credentials and pending subscription work. This does not
::  erase conversations or other owner data; disown removes the bot pier.
/-  *harness-store, renew=harness-oauth, hosted=harness-hosted
|%
++  clear
  |=  saved=state-30
  ^-  state-30
  =/  openai=state:renew  *state:renew
  =.  serial.openai  +(serial.openai-auth.saved)
  =/  xai=state:renew  *state:renew
  =.  serial.xai  +(serial.xai-auth.saved)
  saved(provider-keys ~, api-key '', hosted *state:hosted, openai-auth openai, xai-auth xai)
--
