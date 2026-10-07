/-  *harness-store, h=harness, m=harness-memory
/+  *test, storage=harness-store, policy=harness-defaults, memory=harness-memory
|%
++  fixture
  ^-  state-m0
  =/  s  *state-m0
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(system memory-migration-system:storage)
  %=  s
    defaults  cfg
    provider-keys  (my ~[['openrouter' 'fixture-key']])
    sessions
      %-  my
      :~  :-  'first'
          [~[[%memory-set 'project' `'Provisioning requires privacy.'] [%config-replaced cfg]] 7]
          :-  'second'
          [~[[%memory-set 'project' `'Delivery requires retry.'] [%config-replaced cfg]] 3]
          ['forgotten' [~[[%memory-set 'secret' ~] [%memory-set 'secret' `'Forgotten text.']] 0]]
      ==
  ==
++  test-memory-migration-preserves-all-fields-and-distinct-live-notes
  =/  old  fixture
  =/  migrated  (envelope:storage !>(old))
  =/  db  knowledge.migrated
  ;:  weld
      (expect-eq !>(+.old) !>(+>.migrated))
      (expect-eq !>(2) !>(~(wyt by records.db)))
      (expect-eq !>(1) !>((lent (choose:memory db 'provisioning' 'operator'))))
      (expect-eq !>(1) !>((lent (choose:memory db 'delivery' 'operator'))))
      (expect-eq !>(~) !>((choose:memory db 'forgotten' 'operator')))
      (expect-eq !>(migrated) !>((envelope:storage !>(migrated))))
  ==
++  test-load-migrates-only-the-builtin-prompt-and-keeps-cursors-aligned
  =/  old  fixture
  =/  migrated  (load:storage !>(old))
  =/  db  knowledge.migrated
  =/  log  log:(~(got by sessions.migrated) 'first')
  =/  custom  (load:storage !>(old(defaults defaults.old(system 'My own instructions.'))))
  ;:  weld
      (expect-eq !>(default-system:policy) !>(system.defaults.migrated))
      (expect-eq !>('My own instructions.') !>(system.defaults.custom))
      (expect-eq !>(log) !>((~(got by cursors.db) 'first')))
      (expect-eq !>(migrated) !>((load:storage !>(migrated))))
  ==
++  test-imported-notes-retain-human-attribution-and-searchable-names
  =/  old  fixture
  =/  log=(list event:h)
    :~  [%memory-set 'favorite-color' `'Amber.']
        :-  %input-received
        [0v7 [%poke ~nec] `~nec ~ ~2026.10.7 [%user '/remember favorite-color Amber.']]
    ==
  =.  old  old(sessions (my ~[['first' [log 0]]]))
  =/  migrated  (envelope:storage !>(old))
  =/  db  knowledge.migrated
  =/  names  (choose:memory db 'favorite-color' '~nec')
  ?>  ?=(^ names)
  =/  record  (~(got by records.db) i.names)
  ;:  weld
      (expect-eq !>('~nec') !>(actor.source.value.record))
      (expect-eq !>(0v7) !>(input.source.value.record))
      (expect-eq !>(2) !>(event.source.value.record))
      (expect-eq !>(~2026.10.7) !>(at.source.value.record))
      (expect-eq !>(`'Amber.') !>(body.value.record))
  ==
--
