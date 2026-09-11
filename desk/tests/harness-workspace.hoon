/-  w=harness-workspace
/+  *test, work=harness-workspace, document=harness-document, codec=harness-workspace-json
|%
++  owner  `authority:w`[& [0v0 'Owner'] 0v0]
++  agent  `authority:w`[| [0v1 'researcher'] 0v1]
++  other  `authority:w`[| [0v2 'writer'] 0v2]
++  value  `content:w`['Community plan' 'A durable document.' ~]
++  step
  |=  [db=state:w who=authority:w act=action:w]
  ^-  state:w
  =/  out  (apply:work db who act ~2026.9.11)
  ?>  ?=(%& -.out)
  p.out
++  project
  ^-  state:w
  =/  db  (step *state:w owner [%project-create 'project' 'Community' 'Shared research'])
  (step db owner [%member 'project' 1 0v1 `%contributor])
++  fixture
  (step project owner [%artifact-create 'document' `'project' value])
++  test-agent-draft-needs-owner-review
  =/  db  (step project agent [%artifact-create 'draft' `'project' value])
  =/  art  (~(got by artifacts.db) 'draft')
  =/  proposal  (~(got by proposals.db) 'draft')
  =/  refused  (apply:work db agent [%review 'draft' & 'Approve myself'] ~2026.9.11)
  =/  accepted  (step db owner [%review 'draft' & 'Reviewed'])
  ;:  weld
    (expect-eq !>(0) !>(head.art))
    (expect-eq !>(%pending) !>(status.proposal))
    (expect !>(?=(%| -.refused)))
    (expect-eq !>(1) !>(head:(~(got by artifacts.accepted) 'draft')))
  ==
++  test-project-membership-does-not-leak-to-other-conversations
  =/  db  fixture
  =/  art  (~(got by artifacts.db) 'document')
  ;:  weld
    (expect !>((can-read:work db agent art)))
    (expect !>(!(can-read:work db other art)))
    (expect !>(!(can-read:work db [| [0v3 'researcher'] 0v3] art)))
  ==
++  test-concurrent-edits-reject-stale-proposals
  =/  db  (step fixture agent [%propose 'proposal' 'document' 1 value 'Improve it'])
  =/  updated  (step db owner [%artifact-save 'document' 1 `'project' ['New title' 'New body' ~]])
  =/  refused  (apply:work updated owner [%review 'proposal' & 'Accept'] ~2026.9.11)
  ;:  weld
    (expect !>(?=(%| -.refused)))
    (expect-eq !>(%pending) !>(status:(~(got by proposals.updated) 'proposal')))
    (expect-eq !>(2) !>(head:(~(got by artifacts.updated) 'document')))
  ==
++  test-revoked-contributors-cannot-propose-or-have-old-work-auto-accepted
  =/  db  (step fixture agent [%propose 'proposal' 'document' 1 value 'Improve it'])
  =/  db  (step db owner [%member 'project' 2 0v1 ~])
  =/  refused  (apply:work db owner [%review 'proposal' & 'Accept'] ~2026.9.11)
  =/  write  (apply:work db agent [%propose 'second' 'document' 1 value 'Again'] ~2026.9.11)
  (expect !>(&(?=(%| -.refused) ?=(%| -.write))))
++  test-publication-stays-on-explicit-revision
  =/  db  (step fixture owner [%publish 'document' 1 1 0 'community' '<p>Approved</p>'])
  =/  db  (step db owner [%artifact-save 'document' 1 `'project' ['Private draft' 'Do not publish' ~]])
  =/  art  (~(got by artifacts.db) 'document')
  =/  unpublished  (step db owner [%unpublish 'document' 1])
  ?>  ?=(^ publication.art)
  ;:  weld
    (expect-eq !>(1) !>(revision.u.publication.art))
    (expect-eq !>('<p>Approved</p>') !>(html.u.publication.art))
    (expect-eq !>(`(map @t id:w)`~) !>(slugs.unpublished))
  ==
++  test-two-agents-cannot-claim-one-task
  =/  db  (step project owner [%member 'project' 2 0v2 `%contributor])
  =/  db  (step db owner [%task-create 'task' 'project' 'Research costs' 'Return evidence'])
  =/  claimed  (step db agent [%task-claim 'task' 1])
  =/  refused  (apply:work claimed other [%task-claim 'task' 1] ~2026.9.11)
  =/  forged  (apply:work claimed other [%task-update 'task' 2 %done 'I did it' ~] ~2026.9.11)
  (expect !>(&(?=(%| -.refused) ?=(%| -.forged))))
++  test-public-renderer-keeps-markup-inert
  =/  html  (page:document '<script>title</script>' '# Heading\0a\0a**Bold** and [friend](https://example.com).\0a\0a<script>alert(1)</script>\0a\0a```\0a<private>\0a```')
  ;:  weld
    (expect !>(?=(^ (split:document "&lt;script&gt;title" (trip html)))))
    (expect !>(?=(^ (split:document "<strong>Bold</strong>" (trip html)))))
    (expect !>(?=(~ (split:document "<script>" (trip html)))))
    (expect !>(!(safe-url:document 'javascript:alert(1)')))
  ==
++  test-project-scope-cannot-expose-private-history
  =/  db  (step project owner [%artifact-create 'private' ~ value])
  =/  refused  (apply:work db owner [%artifact-save 'private' 1 `'project' value] ~2026.9.11)
  (expect !>(?=(%| -.refused)))
++  test-new-artifact-cannot-overwrite-existing-proposal
  =/  db  (step fixture agent [%propose 'collision' 'document' 1 value 'Original'])
  =/  refused  (apply:work db agent [%artifact-create 'collision' `'project' value] ~2026.9.11)
  (expect !>(?=(%| -.refused)))
++  test-owner-task-update-retains-an-explicit-claimant
  =/  db  (step project owner [%task-create 'task' 'project' 'Write' ''])
  =/  db  (step db owner [%task-update 'task' 1 %claimed '' ~])
  (expect-eq !>(`(unit actor:w)`[~ [0v0 'Owner']]) !>(claimant:(~(got by tasks.db) 'task')))
++  test-json-offsets-use-ungrouped-decimal
  =/  args=json  [%o (my ~[['offset' [%n '8000']]])]
  =/  invalid=json  [%o (my ~[['offset' [%n '8.000']]])]
  =/  refused  (mule |.((number:codec invalid 'offset' 0)))
  ;:  weld
    (expect-eq !>(8.000) !>((number:codec args 'offset' 0)))
    (expect !>(?=(%| -.refused)))
  ==
++  test-empty-directory-first-page
  =/  args=json  [%o (my ~[['offset' [%n '0']] ['limit' [%n '24']]])]
  =/  result  (page:codec ~ args &)
  ;:  weld
    (expect-eq !>(0) !>((number:codec args 'offset' 99)))
    (expect-eq !>(`json`[%a ~]) !>((need (get:codec result 'items'))))
    (expect-eq !>(`json`~) !>((need (get:codec result 'nextOffset'))))
  ==
--
