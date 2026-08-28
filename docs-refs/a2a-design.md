# Agent-to-agent over Ames — settled design (2026-08-28)

Decided with the user; build after skills-in-state lands.

## Model
Peer-as-tool: `ask_peer(ship, prompt)` on the asking side reuses the
run_subagent machinery (`%tool-requested` → wire → result re-enters as
`%tool-completed`), with an Ames poke instead of a self-poke. The answer
crosses; the data doesn't.

## Serving side
- Asks land in a **durable per-peer sandboxed session** `peer--~ship`
  (user: "private into its own session"). Never a session the owner's
  surfaces use — peer text is untrusted model input; sandboxing bounds
  injection blast radius to the peer's own grant.
- **Identity-based permissions** (user: "someones agent can access more"):
  ```hoon
  +$  peer-grant
    $:  tools=(list term)     ::  ~ for strangers
        model=(unit @t)       ::  cheap model for low-trust
        budget=@ud            ::  answerer pays tokens; cap them
        inflows=(set @t)      ::  published skills/docs their session sees
    ==
  peers=(map ship peer-grant)   ::  absent ship = refused
  ```
  Moons ≈ full grant (unifies remote subagents with A2A). Grant changes
  reach the durable session via the existing %config path.
- **Curated inflows**: peer sessions know nothing by default; they see only
  explicitly published skills/profile docs. When cross-session memory is
  ever built, peer sessions are excluded by default.

## Protocol
Versioned mark `%harness-a2a-0`, typed and growable (user wants typed asks):
```hoon
+$  ask-id  @uv                 ::  path-safe now, so answers can later be
+$  a2a                         ::  published at /answers/[id] and remote-scried
  $%  [%ask id=ask-id kind=%text prompt=@t]
      [%answer id=ask-id result=(each @t @t)]
  ==
```
Behn timeout on the asking side → error tool result. Later phase: published
surface (`/public/skills`, profile) read by remote scry — scry for data,
ask for cognition.

## Test plan
Boot fakebus (~bus) on another port, install the desk, tiered-grant demo:
~bus asks ~zod.
