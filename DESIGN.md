---
name: Harness
description: The incumbent neutral light and dark interface for conversations and settings.
colors:
  bg: "#f6f8fa"
  panel: "#ffffff"
  sidebar: "#ffffff"
  text: "#171917"
  muted: "#626862"
  line: "#d0d7de"
  soft: "#f1f3f1"
  accent: "#0969da"
  accent-soft: "#e6effd"
  danger: "#c9362b"
  success: "#1a7f37"
  warning: "#9a6700"
  code: "#f2f4f2"
  bg-dark: "#111310"
  panel-dark: "#191c18"
  sidebar-dark: "#151714"
  text-dark: "#eef0eb"
  muted-dark: "#9ba198"
  line-dark: "#2c302a"
  soft-dark: "#20231f"
  accent-dark: "#6ea4ff"
  accent-soft-dark: "#1d2d48"
  danger-dark: "#ff7b72"
  success-dark: "#56d364"
  warning-dark: "#e3b341"
  code-dark: "#131612"
typography:
  body:
    fontFamily: 'Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
    fontSize: "14px"
    lineHeight: 1.5
  headline:
    fontSize: "24px"
    lineHeight: 1.25
    letterSpacing: "-.025em"
  title:
    fontSize: "15px"
    letterSpacing: "-.015em"
  label:
    fontSize: "13px"
    fontWeight: 600
  small:
    fontSize: "12px"
    lineHeight: 1.5
  mono:
    fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"
rounded:
  control: "7px"
  panel: "8px"
  dialog: "12px"
spacing:
  "8": "8px"
  "12": "12px"
  "16": "16px"
  "20": "20px"
  "24": "24px"
components:
  button:
    backgroundColor: "{colors.soft}"
    textColor: "{colors.text}"
    rounded: "{rounded.control}"
    padding: "7px 14px"
  button-primary:
    backgroundColor: "{colors.text}"
    textColor: "{colors.bg}"
    rounded: "{rounded.control}"
    padding: "7px 14px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.text}"
    rounded: "{rounded.control}"
    padding: "7px 14px"
  input:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.text}"
    rounded: "{rounded.control}"
    padding: "0 11px"
  panel:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.panel}"
  status:
    rounded: "{rounded.control}"
    padding: "3px 7px"
  navigation-active:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.text}"
    rounded: "{rounded.panel}"
---

# Design System: Harness

## Overview

Harness uses neutral surfaces, compact interface typography, restrained borders, and blue selection and focus treatments. This document records the existing implementation; it does not establish a new visual identity or an unconfirmed brand metaphor. The existing Harness logo remains the identity asset.

Evidence for the Harness frontend is the current source in `fe/src/style.css`, sampled against `Sidebar.jsx`, `Settings.jsx`, `GlobalSettings.jsx`, `MemorySettings.jsx`, and `CorpusSearch.jsx`. These are source observations without rendered visual approval. Search-specific composition remains in `.impeccable/surfaces/fe-src-components-corpussearch-jsx.md`.

Optional Tlon work-message controls are a native host exception. Their visual authority is the merged `tlon-apps/develop` A2UI renderer, which owns their palette, typography, spacing, shapes, and interaction states. The Harness frontend tokens in this document do not style that surface. Its component contract is recorded below; its composition and rendered review evidence remain in `.impeccable/surfaces/desk-lib-harness-tlon-work-hoon.md` and `.impeccable/review/task-notes-verification.md`.

Key characteristics:

- Neutral light and dark themes with shared semantic color roles.
- Compact labels and headings within bordered settings panels.
- Blue selection and focus, with foreground-colored primary buttons.
- Persistent desktop navigation and a dialog drawer on mobile.

## Colors

The palette separates background, panels, navigation, text, borders, and interaction state through semantic CSS custom properties.

### Primary

`accent` is the blue used for links, text actions, caret, focus, and active indicators. `accent-soft` supplies selected navigation and result backgrounds, as well as text selection. Primary filled buttons use `text` over `bg`; they do not use the blue accent as their fill.

### Neutral

`bg` is the workspace and field surface; `panel` is the settings and dialog surface; `sidebar` is navigation. `soft` marks hover and checked-option surfaces. `text` and `muted` separate primary content from help and metadata. `line` defines borders and dividers; `code` supplies code surfaces.

`danger`, `success`, and `warning` communicate error, healthy, and running/loading states. Existing status and error treatments mix these roles with the neutral surface and border using `color-mix()`.

**The Semantic Theme Rule.** Use the existing CSS custom property for each role so theme overrides apply to the whole component.

The frontmatter names the default light values and their dark counterparts with a `-dark` suffix for portability. Runtime CSS keeps one role name, such as `--bg`, and overrides its value. System dark mode applies unless `data-theme="light"` is set; `data-theme="dark"` explicitly selects dark mode. The frontmatter component examples describe the light mapping; their runtime custom properties select the matching dark roles.

## Typography

The body font stack begins with Inter and falls back through system UI sans-serif faces. This records the CSS stack without asserting that Inter was downloaded or rendered. Code and preformatted content use the separate monospace stack.

The hierarchy is compact: page headings use `headline`, section headings use `title`, body copy uses `body`, field labels use `label`, and most field help uses `small`. Labels and common button text are semibold. Page and section headings retain native heading weight because the shared rules do not explicitly assign it. There is no separate marketing display type system.

**The Interface Hierarchy Rule.** Reuse the page-heading, section-heading, label, and help-text roles already shared by settings and search.

Some incumbent metadata is smaller than the shared small-text token. Those isolated sizes are not a recommended extension of the type scale. Long prose and field descriptions wrap; source and descriptive text commonly use measures around 72–75 characters where explicitly constrained.

## Layout

The desktop shell uses a fixed navigation column (240px) and a flexible workspace with a zero minimum width. Navigation is sticky and fills the viewport height. Workspace top bars are sticky (58px high).

Settings content is centered with a maximum width (810px), viewport gutters (24px on each side), and vertically stacked groups. Repeated gaps use the spacing steps in the frontmatter, alongside local values rather than a single enforced mathematical scale. Settings panels use padding (20px 22px 22px); the shared two-field layout collapses on mobile.

At the mobile breakpoint (760px), the shell becomes one column, navigation moves into a dialog drawer, and a sticky mobile header occupies 48px. Settings gutters become 16px. Common action targets increase to at least 44px high, and text inputs use 16px text. Tabs scroll horizontally when needed. At 470px, settings panels use padding (17px 16px) and save bars stack their status and full-width button.

These are observed breakpoints, not claims that every component has been tested at those widths. Individual routes may add their own composition breakpoint; those decisions belong in their surface briefs.

## Elevation & Depth

Ordinary panels rely on a neutral surface and a single border, without a shadow. Floating controls and banners share `--shadow`, a low diffuse shadow in light mode and `none` in dark mode. Dialogs, suggestions, and selected segmented controls have separate local shadows; the app is not universally shadowless. The sidecar records the shared shadow and input focus ring rather than promoting every local effect to a token.

**The Panel Boundary Rule.** Reuse the shared panel's border and surface treatment for ordinary settings sections.

## Shapes

Controls use the `control` radius, panels and navigation rows use `panel`, and dialogs use `dialog`. Boundaries are generally one-pixel strokes in `line`. Native checkboxes retain their native form and use the accent color. Circular status marks and a pill-shaped floating conversation control also exist; they are not a general card shape.

## Components

### Buttons

Common buttons have a compact semibold label, one-pixel border, and a minimum height (38px desktop; 44px mobile). The default fill is `soft`; primary uses `text` with `bg` lettering; ghost is transparent with the ordinary border. Hover lowers opacity to .84 unless disabled. Disabled buttons use opacity .45 and a default cursor. Keyboard focus uses the shared outline (2px accent, offset 3px). Text actions use the accent color and a transparent background.

### Inputs / Fields

Labels sit above full-width controls. Fields use the workspace background, neutral border, and control radius. A focused input changes its border to an accent mix and receives a soft accent ring; the input-specific `outline: 0` makes this ring its focus treatment. Textareas resize vertically. Placeholders use muted text at full opacity, and the caret uses the accent. Native disabled fieldsets are used while settings are unavailable or saving.

### Cards / Containers

Settings sections share the panel surface and radius, with a wrapping title/action row, optional muted description, and field groups. Save bars use the same boundary and pair a textual state with the save action. Their layout stacks at the narrow breakpoint. Status badges use a small border and radius; the healthy variant tints its foreground, border, and surface from `success`.

### Navigation

Sidebar navigation is Work, Tlon, Search, then Settings. Work opens the inbox and stays selected across Inbox, Tasks, Artifacts, and Projects; those sections use the workspace top-right navigation. Sidebar rows use a transparent default surface, `soft` hover, and `accent-soft` active background. Conversation rows expose rename and delete controls on hover or keyboard focus; touch and mobile layouts keep these actions visible. Settings tabs use muted text and an accent underline on the current section. Segmented controls place the selected item on the panel surface with a small local shadow. Active navigation also carries semantic current/pressed state in the components.

### Feedback and motion

Settings and search include textual loading, saving, empty, and error states, with status or alert semantics where present. Existing retry controls use ordinary text or ghost actions. Animation is localized to running/thinking indicators; there is no general transition token. The reduced-motion media rule shortens animations to .01ms, runs them once, and restores automatic scrolling.

Icons generally come from authored SVG components. The existing raster Harness logo is retained. The incumbent Unicode close glyph is not documented as an icon pattern for new surfaces.

### Tasks and optional projects

The task is the unit of work; a project is an optional collection. Agents maintain tracking and assignment as part of their work, while helper and empty-state text directs human requests and updates to the conversation. `#/tasks` and `#/tasks/:id` open the global task list and detail; a project's Tasks tab filters the same component in `fe/src/components/ProjectWorkspace.jsx`. Each task shows its title, a textual status (Open, Assigned, Needs attention, or Complete), description, updated time, outcome, and a result link when present. New task and Update task provide optional human forms using existing field, button, and dialog styling. The editor exposes title, brief, optional project, status, outcome, and an optional result document. It saves the changes atomically with the current version. Delete task opens an explicit warning that deletion removes the tracking record permanently without cancelling an agent or deleting documents. Raw task IDs, versions, and a claim button are not displayed. Completion records an outcome and does not verify an external action. The Sharing tab contains document access controls and does not gate task tracking. The global task list hides tasks in archived projects and includes standalone tasks.

### Native Tlon work-message controls

The optional owner-DM attachment uses only the merged Tlon catalog's `Text`, `Column`, `Row`, `Divider`, `Choice`, and `Button` components. `desk/lib/harness-tlon-work-card.hoon`, `desk/lib/harness-work-copy.hoon`, and `desk/lib/harness-work-view.hoon` supply content and actions. Tlon owns visual tokens and interaction states; the work surface adds no custom styles, renderer extensions, or raster assets.

**The Native Host Rule.** Use the merged Tlon message catalog and host theme for optional Tlon work controls; keep Harness frontend tokens scoped to the Harness frontend.

Native `h2` titles and human context precede controls. A task presents its title, status, description, and outcome, followed by Refresh task or Read result and More actions. Refresh task uses a wrapping single-option `Choice` because it opens a task record. Task lists offer Add task; `/work task-new` treats the supplied text as a standalone task's title. A task without a project has no Open project action. Agents with the Workspace tool share task tracking and project metadata. Creating projects and creating, assigning, or updating tasks are immediate bookkeeping with current-version checks on task mutations. Assignment records an existing agent with Workspace access; it does not change task status, grant tools, or dispatch execution. Work runs through the agent runtime and granted delegation, and delegated work returns to its caller. A task's status does not establish worker activity, document acceptance, or delivery.

Operation-specific summaries explain protected changes and their results. Exact previews retain meaningful content: draft and reply bodies, sources, reply destination and recipient, and proposed access changes. Technical canonical JSON is available through explicit Details. Document acceptance, document access changes, publication, and explicitly selected delivery retain their approval controls. Project editing and archival retain their protected management path because projects also contain shared documents. Ordinary answers, project creation, and task bookkeeping do not require this approval ceremony. The agent's current tool grants govern execution; document membership remains separate, and delegation does not grant additional access.

Current, inspected pending protected requests offer an operation-specific confirmation, Cancel, and Details. Uninspected model prose stays visible alongside a Review-only card that opens the head-authored preview. Expired or changed inspected approvals offer Tasks and Projects recovery navigation. Settled receipts offer an appropriate next action, such as View task after task creation or Check delivery after queuing a reply. Buttons send literal work commands into the same DM. Approval tokens retain the full digest of the exact request; navigation uses short record references. The head enforces current authority and exact approval content. Presentation and client selection never approve or send work automatically.

Ordinary work help, project/task lists and details, draft review, and saved documents require a matching head command response and current owner authority. Record selection, pagination, creation entry points, and work previews send literal work commands. Changed read content offers refreshing. Record names and longer actions use wrapping single-option `Choice` rows. Short utility buttons occupy a wrapping row, with a divider when record choices precede them. The native button label does not wrap; Saved copy is the bounded label for the Read saved document text action, with the same command. Names are entered in chat through project/task naming commands.

Complete head-authored cards carry `storyMode: fallback`: supporting clients show the card's human content and controls without duplicating the ordinary story. Text-only and unsupported clients retain the human text and commands. The ordinary story remains part of the post. Posts and attachments persist as snapshots; querying work obtains current state, and a saved post does not update itself as a task, approval, worker, or delivery changes.

Rendered task navigation evidence and fixture provenance are indexed by `.impeccable/review/task-notes-verification.md`. This source-derived component contract does not certify rendered results or whole-surface accessibility. The native web `Button.Frame` lacks a button role and keyboard tab stop. This host limitation is not a Harness component convention; text commands remain available for keyboard work management.

## Do's and Don'ts

- Do use the existing semantic CSS colors so light, dark, and system themes remain connected.
- Do reuse shared panels, labels, buttons, and field groups for additional settings.
- Do retain keyboard focus, explicit state text, and native control semantics when extending components.
- Do follow the existing mobile target sizing and stacked field layouts.
- Don't infer a new brand identity, display face, or page composition from this source inventory.
- Don't treat source inspection as rendered visual approval.
- Don't propagate isolated tiny metadata text or glyph-based icons as new system rules.
