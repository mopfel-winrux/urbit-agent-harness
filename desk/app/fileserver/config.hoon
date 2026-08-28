::  configuration for the %harness-fileserver agent
::
|%
::  serve under /harness
::
++  web-root  ^-  (list @t)  /harness
::  extensionless urls fall back to the index file,
::  so both /harness and /harness/ serve /web/index.html
::
++  extension  %fall
--
