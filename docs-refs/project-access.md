# Project delegation and client access

Project **Sharing** separates document roles from credentials for external
readers. Neither starts inference, grants tools, or shares conversation history.
This is bounded delegated project authority, not a general
multi-user account system or a client execution API.

## Document roles and task coordination

Agents with the Workspace tool share task tracking and project metadata without
project membership. They can create projects and create, assign, update, or
delete tasks. These operations track work; they do not dispatch or cancel it.
Task mutations check the current record version, and linking a result document
requires access to that document. An assignment is not an exclusive edit right.

Project roles govern shared documents and delegated project editing:

| Operation through Workspace | Reader | Contributor | Maintainer | Owner |
| --- | --- | --- | --- | --- |
| Read project documents, accepted history and proposals | Yes | Yes | Yes | Yes |
| Propose document changes | No | Yes | Yes | Yes |
| Edit project title and description | No | No | Yes | Yes |
| Change membership, archive/restore project, manage client keys | No | No | No | Yes |
| Accept/reject proposals, directly save accepted bodies, publish | No | No | No | Yes |

Enable the Workspace tool separately in each participating conversation. Tool
grants are independent of project roles. Document authority is checked against
current project membership, not the conversation's displayed name. A live
delegated child uses its parent's current project scope and retains its own
authorship; stale children do not acquire that authority. Scheduled work can
inherit Workspace; rehearsal runs do not receive it.

Maintainer project edits use the current project version and permit title and
description changes, not access or archival changes. Downgrading or removing a
maintainer takes effect on subsequent document and project-edit operations.
Archiving suspends document membership, not task coordination. Information
already copied cannot be recalled.

## Read-only project keys

Open a project from **Work → Projects**. In **Sharing → Read-only client access**,
choose **Create read-only key…**, label it, choose an expiry, and confirm the
sharing scope. Save the key
before closing its confirmation. Reveal and Copy are explicit actions; the key
is never stored in browser local/session storage or placed in a URL by Harness.
The browser needs a secure random generator; unavailable randomness fails closed.

A key permits reads of its one project's current and future non-archived
documents, accepted body history, proposals, source references, and task records.
It does not expose private artifacts, other projects, membership lists,
conversation transcripts, the owner inbox, unified search, credentials, or audit
history. Metadata may include authors' retained labels and identifiers. Source
URLs are shared project content; they do not grant access to their destinations.

Keys never become conversation members or maintainers. They cannot create tasks,
claim work, edit records, execute tools, manage credentials, approve proposals,
or publish. The only external endpoint is:

```http
POST /harness-project/read
Authorization: Bearer <project-key>
Content-Type: application/json

{"action":"project","args":{"id":"your-project-id"}}
```

Supported actions: `help`, `projects`, `project`, `artifacts`, `artifact`,
`revisions`, `revision`, `proposals`, `proposal`, `tasks`, and `task`. `help`
describes this restricted interface. Lists accept `offset` and `limit` (1–4).
Bodies are limited to 8,000 UTF-8 bytes per page; follow `nextOffset` with the
fixed revision number. Owner list limits and model Workspace read conventions
are described in [workspaces](workspaces.md#interfaces-and-bounds).

The route accepts only POST and the exact path, with no query string. The JSON
request body is limited to 8,192 bytes. An owner cookie alone is not a project
key; the endpoint does not promote cookie authentication into owner authority.
Missing, expired, revoked or suspended credentials receive 401; forbidden
actions receive 403; unavailable records/invalid read parameters receive 404.
Malformed JSON/args receive 400, oversized bodies 413, other methods 405.
Document reads refresh native Notes content and return 503 if Notes is
unavailable; they do not substitute cached bodies. Metadata lists read Harness
records without fetching Notes bodies. Reads issue no mutation cards and change
no Harness durable state.

## Expiry, recovery and storage

Keys use 32 cryptographically random bytes, formatted as `hpr_` plus 64 lowercase
hex digits. The durable credential registry retains a SHA-256 digest, project,
label, creation/expiry times and optional revocation time—not a retrievable key.
Protect the ship's event logs and backups: inbound credential creation and read
events may contain the original secret even though the registry stores a digest.

The UI offers 1, 7 or 30 days; the owner API accepts 1–30 days. Expiry is fixed
at creation and checked on every request. Archiving suspends a key; restoring
the project reactivates it only if still unexpired and unrevoked. Revocation is
permanent for that credential identity. A repeated revoke preserves its original
revocation time. Previously accepted reads and copies cannot be undone.

If creation loses its confirmation, **Retry same key** repeats the original
identity and secret. An identical active request can recover the result without
extending expiry, even if the project version has since changed. It cannot
change scope, replace the secret, or revive an expired/revoked key. If the dialog
is closed before confirmation, inspect the credential list and revoke any key
whose local copy was lost. No automatic write retry is performed.

The owner ACP interface uses `harness/workspace` actions `clients`,
`client-create`, and `client-revoke`. Creation requires
`{id, project, version, label, key, days}`; revocation requires `{id, project}`.
Creation fences the current project version. Labels are limited to 128 UTF-8
bytes. There are at most 256 retained credentials across the ship, including
expired and revoked tombstones; revocation does not reclaim capacity. Metadata
lists are paginated, with no secret or digest returned. There is no
credential deletion, rotation-in-place, or automatic expiry-maintenance loop.

## Equivalent effects and deployment boundary

These restrictions describe authority added by Workspace roles and project
keys. They are not a sandbox over independently granted ship-wide authority.

| Independent interface | Relationship to project authority |
| --- | --- |
| Workspace model tool | Shares task tracking under the tool grant; checks document roles and record versions where required. Owner actions remain denied. |
| Model administration tool | Cannot call owner Workspace methods to issue keys, change membership, accept or publish. |
| Native owner Workspace poke and authenticated owner ACP | Intentionally retain owner powers; never distribute the ship login to project clients. |
| Native Notes / Tlon tools | Independently granted native access can edit or publish outside the Workspace proposal workflow. Membership neither adds nor revokes that access. |
| General HTTP, code execution, other independently granted resources | Not restricted by project roles. They may have equivalent effects if separately given credentials/authority. Review these grants before delegating to external participants. |
| Webhooks and other ship endpoints | Not protected by a project key. Each has independent deployment/authentication requirements. |

Use HTTPS remotely and configure the public proxy to expose only
`/harness-project/read` for a project client. The separate `/harness-project`
binding does not require exposing `/harness-api` or owner ACP. Harness accepts
secure Eyre requests or loopback connections; a TLS-terminating proxy on loopback
must itself enforce HTTPS and its intended public route. No CORS permission is
added. Responses use `Cache-Control: no-store`, `Referrer-Policy: no-referrer`
and `X-Content-Type-Options: nosniff`. Configure proxy logs not to record bearer
headers; rate limiting and perimeter configuration remain operator duties.

Notes reads use a disposable project-only projection and exact selected native
note identities, not a notebook-wide body listing. Native publication status
metadata is inspected separately. There is no public document cache or owner
conversation passed into this route. This feature changes no proxy, DNS, TLS,
native Notes permissions or independent tool grants.

## Verification

Pure native tests: `/tests/harness-workspace-maintainer`,
`/tests/harness-project-client`, `/tests/harness-boundaries`. Full-agent isolated
tests: `/tests-integration/harness-project-client`. These inspect cards and
state without executing the emitted effects. Browser behaviors:
`fe/tests/project-access.spec.js`; opt-in synthetic captures:
`PROJECT_ACCESS_CAPTURE=1 PLAYWRIGHT_CHANNEL=chrome npx playwright test project-access.visual.spec.js`
from `fe`.

Run the installed loopback endpoint check with:

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie \
SOAK_EXPECT_SHIP='~your-local-ship' node scripts/project-client-conformance.mjs
```

The check verifies local ship identity before writes. It creates two uniquely
named projects, one task and one one-day key; it finally revokes that key, closes
the synthetic task, and archives only those projects. Test-owned records and credential tombstones stay
as evidence. It creates no Notes documents, calls no models, publishes nothing,
and performs no external sends. Native Notes body-source isolation is checked
by the isolated fixture, not this metadata-only live smoke test.
