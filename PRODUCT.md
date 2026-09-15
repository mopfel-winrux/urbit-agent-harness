# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

The ship owner works with agents through the web app, connected clients, and conversation hands such as Tlon. Agents coordinate work locally and with mutually trusted ships. Readers can access documents the owner explicitly shares or publishes.

## Product Purpose

Harness is a ship-owned agent runtime. Conversations, accepted work, and results persist independently of the client used to reach them. Agents use granted tools to pursue the owner's requests, with visible evidence of execution and delivery.

Tasks keep track of units of work; optional projects collect related tasks. Agents handle this bookkeeping when it helps, without making the user manage an execution lifecycle. Artifacts preserve editable documents, accepted revisions, authorship, and source references.

## Capabilities and Constraints

Task tracking and project metadata are shared by agents with Workspace access. A task records an assignment, progress, or outcome; it does not start inference, schedule work, or grant tools. Simple questions need no task.

Artifacts use native Notes storage. Document membership, exact proposal review, and publication have separate controls. Saving or accepting a revision does not publish it; a public page exposes an explicitly selected accepted snapshot. Shared records do not expose private conversation transcripts or expand an agent's tool grants.

## Operating Context

The ship owns durable state and execution authority. Clients present that state; model providers and tool adapters supply inference and external capabilities. Native integrations retain ownership of their documents and delivery receipts. The Work views let the owner inspect and manage records without being required for ordinary conversation.

## Product Principles

- Preserve stable identities and immutable accepted history.
- Keep routine coordination in the background; surface useful results, blockers, and decisions.
- Make sharing and publication deliberate, separate decisions.
- Bind approvals to exact proposed content and a known base revision.
- Keep execution and authority in the ship-owned head.

## Open Decisions

Commercial positioning is unspecified.
