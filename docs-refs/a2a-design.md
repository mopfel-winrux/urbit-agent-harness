# Agent-to-agent over Ames

Remote agent work uses Grubbery's typed `/port` ingress, Urbit identity, and a
sandboxed child process. The answer crosses the network; private source data
does not cross unless the owner explicitly publishes or sends it.

## Asking side

`ask_peer(ship, prompt)` behaves like a child-agent tool. It creates a durable
request id, sends typed cargo to the peer's advertised harness port, waits with
a Behn deadline, and materializes the answer or error as a tool result. The
calling chat never treats an Ames poke as trusted instructions.

The request id is path-safe so progress and terminal output can also be
published beneath an addressed request grub. Retries are idempotent by
`[source-ship request-id]`.

## Serving side

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

An explicit usergroup maps ships to grants. An absent ship is refused. Empty
tools and inflows are the useful low-trust default. Moons may receive broader
grants, which makes remote subagents and local delegated devices instances of
the same capability model.

Grant changes apply to new requests. In-flight children retain the grant they
were admitted with so replay cannot silently gain authority.

## Port contract

The port payload is versioned and typed. Its first useful shape is:

```hoon
+$  ask-id  @uv
+$  request  [%ask id=ask-id kind=%text prompt=@t]
+$  response  [%answer id=ask-id result=(each @t @t)]
```

The receiving port keeps the source ship supplied by Ames and authorizes it
before creating a child. It does not accept a ship name from inside the
payload as identity. Replies are correlated to the durable request grub and
must come from the addressed peer.

Later versions may add payload references, progress, cancellation, and
capability discovery without weakening those rules.

## Published surface

Remote scry is for data: public profile, advertised skills, schemas, and
completed answers chosen for publication. Port requests are for cognition.
Private context and cross-chat memory are excluded from peer children unless
named in `inflows`.

## Test plan

Run two fake ships and prove:

1. an unlisted ship is refused without creating a child;
2. a listed ship receives only its configured model, budget, tools, and files;
3. duplicate request ids do not run twice;
4. timeout and cancellation terminate the child and return a typed error;
5. a completed answer survives restarts and can be correlated by request id;
6. neither ship exposes private context through scry or error output.
