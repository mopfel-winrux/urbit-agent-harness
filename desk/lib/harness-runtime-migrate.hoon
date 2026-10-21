::  Preserve the runtime's HTTP registry while migrating Eyre bindings.
/+  nexus, tarball
|%
+$  binding-0  [site=(unit @t) path=path]
+$  server-state-0
  $:  %0
      bindings=(map binding-0 rail:tarball)
      conns=(map @ta binding-0)
  ==
++  server-state
  |=  old=*
  ^-  server-state:nexus
  =/  saved  ;;($%(server-state-0 server-state:nexus) old)
  ?:  ?=(%1 -.saved)  saved
  ::  A domain-specific binding cannot be flattened without changing its
  ::  meaning. Refuse that migration and retain the saved registry.
  =/  convert
    |=  binding=binding-0
    ^-  binding:eyre
    ~|  [%domain-binding-needs-resolution site.binding path.binding]
    ?>  ?=(~ site.binding)
    path.binding
  :*  %1
      %-  malt
      %+  turn  ~(tap by bindings.saved)
      |=  [binding=binding-0 handler=rail:tarball]
      [(convert binding) handler]
      (~(run by conns.saved) convert)
  ==
--
