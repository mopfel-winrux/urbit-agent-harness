# Hosting boundary, version 1

This contract describes how a hosting service connects to Harness; the hosting
control plane is not included. The host operates the ship. Harness keeps
conversations and owner settings.

## One authority per field

| Field | Authority | Acknowledgement and observation |
| --- | --- | --- |
| Ship identity | Ship identity system | Read the actual ship, never a display name |
| Installed release | Clay plus the assembled release artifact | Host records artifact digest, dependency pins and state versions; installation is acknowledged only after agents load |
| Desired release and rollout phase | Hosting control plane | Separate requested, installed, healthy and rolled-back states |
| Provider/default configuration | Harness durable state | Use the authenticated configure/read APIs; a submitted request is not acknowledgement |
| Conversation overrides, grants and scoped notes | Harness and its Tlon policy adapter | Preserve across upgrades; changing hosting defaults does not rewrite them |
| Provider credentials | Harness credential state | Provision through explicit credential operations; status exposes presence/validity, never secret values |
| Tlon storage credentials and selection | Native Tlon storage | Harness consumes that selection; no duplicate host or Harness storage form |
| Subscription, invoices and spending entitlement | Billing service | Keep billing facts out of conversation memory; supply an explicit service policy, not forged tool receipts |
| Conversations, accepted work and publication evidence | Harness head and hand ledger | Read durable identities and receipts; never infer completion from HTTP success |
| Infrastructure health and resource limits | Host | Report observations with timestamps and release identity |

A version-1 host record identifies `contractVersion`, `ship`, `desiredRelease`,
`installedRelease`, `rolloutPhase`, and timestamped health observations. Release
identity includes the complete artifact digest, not only a Git revision: the
assembly includes pinned dependencies and generated assets. Credentials are
references/presence flags in that record, not plaintext. Unknown contract
versions require explicit negotiation; they must not be silently normalized.

Write configuration through its owning service and read back the result.
After a timeout, inspect state before retrying. Host defaults are suggestions;
replacing owner settings requires an explicit operation.

## Health and failure

Report head availability, Tlon Activity/head/publication subscriptions,
admission backlog, uncertain publications, resource pressure and optional
executor availability separately. A single green HTTP check is insufficient.
`delivered` means the concrete adapter's documented receipt, not that a human
read a message. A provider or executor outage must not erase accepted work or
make unrelated native commands unavailable. Billing suspension must have an
explicit admission policy; it must not invent successful or failed external
delivery evidence.

Harness does not enforce private-network isolation. Iris does not validate DNS
answers against pinned public-IP connections; hostname checks are insufficient.
Hosts that require egress restrictions must supply them.

## Release acceptance

A pilot must cover fresh installation, migration of saved defaults and scoped
grants, accepted work across restart, missing optional executors, provider
outage, using disposable fake ships or newly provisioned moons. Do not copy or
restore piers. Code rollback is not state rollback: once a migration changes
persisted nouns, only a compatible release may load them. Harness deployment
changes only the Harness desk; native integrations use existing interfaces.

## Verification and operational measurements

Continuous verification maintains session/check grubs and the browser's
verification view. It checks reconstruction using the head's reducer, not an
independent model of correctness or proof of external actions.

Measure admission acknowledgement and stop acknowledgement separately from
provider latency and destination delivery. For empty, active and long-lived
conversations, collect replay time, mirror update time/bytes, idle events,
allocated/live loom, durable state growth and incremental per-conversation
cost. Record release identity, workload size and host resource allocation with
the measurements. Medians alone hide interruption and long-history tails;
include distributions and failure cases.
