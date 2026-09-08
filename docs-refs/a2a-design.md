# Agent-to-agent over Ames

Remote agent work uses typed Gall pokes over Ames. The receiver uses Gall's
authenticated source ship, never an identity supplied inside the payload.
Agent requests and direct tool calls have separate versioned marks.

## Asking side

`ask_peer(ship, prompt)` behaves like a child-agent tool. It creates a durable
request id, sends typed cargo to the peer's `%harness` agent, waits with
a Behn deadline, and materializes the answer or error as a tool result. The
calling chat never treats an Ames poke as trusted instructions.

The request id is path-safe. Replies must come from the addressed ship.

## Serving side

Configure incoming access in **Settings → Peers**. Add an explicit peer, edit
its resource grants, optional model and shared skills, or revoke it. This is
permission to ask **your** agent; the other ship must grant you access separately
for calls in the opposite direction.

The owner and **Tlon → Trusted ships** automatically have incoming peer
access with **0 = unlimited** tokens by default. Each ordinary trusted-ship row
has a **Peer token limit** field, the recorded token count, and **Reset count**.
The count starts with lifetime prompt + response usage, then tracks usage since
the last reset. Reset applies immediately and persists across restarts without
changing the limit, grants, or conversation history. In-flight usage is charged
when recorded. The limit is checked before admitting another request; it is not a model context
window or a hard cutoff within a running response. Editing only this limit
keeps access inherited: resource permissions still follow Tlon trust, and
removing trust removes inherited access. A separately created explicit peer
grant remains until revoked in Peers. Existing explicit limits are preserved.

Peer requests use the current global provider/model defaults unless a
**Serving model** override is saved in Peers. Existing `%peer-config` values
remain overrides. Provider credentials are managed in Settings → Providers;
peer grants do not include keys. Older releases require `%peer-config`
explicitly and report `peer serving not configured` when it is absent.

Each allowed peer lands in a private child-agent subtree. Peer text is
untrusted model input and never enters an owner's interactive chat. A grant
selects the child's model, token budget, visible context, and tools:

```hoon
+$  peer-grant
  $:  tools=(list term)
      model=(unit @t)
      budget=@ud
      inflows=(set @t)
  ==
```

An explicit map or live Tlon trust maps ships to grants. An unlisted non-owner
is refused. Empty tools and inflows are the low-trust default.

Grant changes apply to new requests. Tool dispatch and asynchronous results
also intersect saved grants with live authority, so revocation cannot leave
queued effects authorized and an existing turn cannot gain newly added tools.

## Full-admin ownership

**Settings → Peers → Owner · full admin** edits the single owner identity shared
with Tlon, even when Tlon replies are disabled. Owners can use `harness_admin`
for Harness configuration, credentials, skills, permissions, and conversations.
The tool routes through the existing ACP administrative handlers. It does not
grant administration of the Earth host operating system.

Only authenticated direct owner peer requests and live owner DM lanes gain
remote administrative provenance. Channel posts, schedules, rehearsal work,
and delegated model turns do not inherit it. Both dispatch and callbacks check
current identity and request generation. Owners get default resource tools,
all shared skills, and no peer token cap; an ordinary explicit grant cannot
restrict ownership. Demotion does not delete a separately stored peer grant.

On first initialization, a moon with no explicit owner selects its actual
sponsor. Detection uses `(clan:title our) == %earl` and sponsorship uses
`(sein:title our now our)`, not address bit layout. A durable marker preserves
later replacement or clearing. **Make sibling moons full admins** is off by
default; when enabled, both ships must be moons and their current `sein:title`
sponsors must match. Future sponsorship changes affect this live check.

Owner saves compare both the previous owner and sibling-owner flag; stale
edits fail. Clearing all owners disables Tlon replies.

## Remote permission awareness

`list_peer_access` lists dated permission reports received from remote ships;
`check_peer(ship)` refreshes one without inference. **Access on other ships**
in Peers exposes the same reports separately from incoming policy. A grant
change announces only that recipient's own grant, never the whole allowlist.
Reports are bounded to 256 ships and persisted across reloads. They are not a
network directory or an authorization cache. Unknown, offline, and older
peers are not inferred to have denied access.

The `%harness-access-0` mark carries `%query` and `%status`. The reported grant
describes the sender's permission for the recipient; it never modifies the
recipient's incoming grants. Receivers enforce current access on every call.

## Direct tool RPC

`list_peer_tools(ship)` discovers a permitted ship's tool schema and
`call_peer_tool(ship, name, arguments)` invokes one granted tool. `arguments`
is a JSON-object string. There is no serving-model turn around the invocation;
an explicitly requested cognitive tool such as a subagent may itself use a
model. The same resource-specific checks and executors serve local and remote
calls, including per-server MCP grants and per-desk Clay grants.

The `%harness-rpc-0` mark carries:

```hoon
[%tools id=@uv]
[%invoke id=@uv issued=@da name=@t args=@t]
[%result id=@uv result=(each @t @t)]
```

Calls use a separate `peer-tool--<ship>` audit conversation. At most one is
active per peer. Durable receipts keyed by `[ship id]` prevent re-execution;
matching duplicates return the existing result, while mismatched payloads
are rejected. A ten-minute validity window (30 seconds allowed future skew)
makes eviction of completed receipts replay-safe. Pending receipts survive
eviction; the receiver rejects at its 256-receipt bound. Calls have a two-minute
deadline. A timeout cannot undo external work already accepted, so callers
must not automatically retry an uncertain operation under a new ID.

## Local MCP discovery

When the local `%mcp-server` agent is running, Harness registers it once as
`<@p>-mcp` at `urbit://<@p>/mcp-server`. Existing entries, disabled entries, and
subsequent deletion are respected. Registration does not add a tool grant.
The native connection uses the MCP desk's local Gall HTTP-request interface,
not a guessed HTTP port or a stored login cookie. Normal MCP server grants,
configuration fingerprints, generation fences, response limits, and deadlines
still apply.

## Agent-request contract

The port payload is versioned and typed. Its first useful shape is:

```hoon
+$  ask-id  @uv
+$  request  [%ask id=ask-id kind=%text prompt=@t]
+$  response  [%answer id=ask-id result=(each @t @t)]
```

The receiving agent keeps the source ship supplied by Ames and authorizes it
before creating a child. It does not accept a ship name from inside the
payload as identity. Replies are correlated to the pending request and
must come from the addressed peer.

The discovery and direct-tool marks leave this older ask/answer mark unchanged.

## Published surface

Private cross-chat memory is excluded from ordinary peer work. `inflows`
names shared skills, not arbitrary conversations. Owners have explicit
administrative authority; ordinary grants never become owner identities.

## Test plan

Run two fake ships and prove:

1. an unlisted ship is refused without creating a child;
2. a listed ship receives only its configured model, budget, tools, and files;
3. duplicate request ids do not run twice;
4. timeout and cancellation terminate the child and return a typed error;
5. a completed answer survives restarts and can be correlated by request id;
6. neither ship exposes private context through scry or error output.
