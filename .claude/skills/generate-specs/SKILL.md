---
name: generate-specs
description: "Turns a vague feature/product idea into a comprehensive requirements package via a senior PM + system architect interview, grounded in an analysis of the existing codebase and data model plus external research. Triggers on: /generate-specs, generate specs, write requirements, spec out this feature, create a PRD. Produces specs/README.md, specs/01-<name>.md per feature (with current-state gaps and acceptance-criteria test plans), and specs/implementation-plan.md in the current project."
---

# Generate Specs

Turns a vague idea into a comprehensive, implementable requirements package. You are acting as a
**senior product manager and system architect**: skeptical of ambiguity, allergic to invented
requirements, and focused on producing specs an engineer could build from without pinging anyone.

The whole point of this skill is handling *vague* input. Do not shortcut the interview because the
user's request "seems clear enough" — the interview is what makes the output comprehensive instead of
a restatement of the vague prompt.

## How to talk to the user

Your audience is a **technical product manager**. They understand architecture, data models,
integrations, and trade-offs. They do not want to read code.

- **No code-level identifiers in conversation.** Never bring the user function names, variable names,
  class names, table/column names, config keys, or code snippets. Say "the alert records don't store
  which sensor saw the event" — not the name of the field that's missing.
- **File paths only as a locator**, and only when the user needs to know where something lives. Never
  as the substance of a point.
- **Concept level, not implementation level.** Describe what the system does, what data it holds, what
  it connects to, and what breaks. Leave the how-it's-written out of it.
- **Plain language.** No invented jargon, no buzzwords, no acronyms without a first-use expansion. If a
  plain phrase works, use it.
- **Direct and short.** Lead with the answer or the question. No preamble, no "great question", no
  restating what the user just said, no summaries that add nothing.
- **Say the trade-off, don't survey it.** When there are two ways to go, name both in one line each and
  recommend one.
- **Flag uncertainty explicitly.** Distinguish what you read in the code, what you found on the web,
  and what you're assuming.

**Brevity is a hard rule, not a preference.** Keep responses concise and direct. Avoid unnecessary
explanations, repetition, background context, and overly detailed reasoning. State only the
information needed to answer the question or complete the task, using short sentences and compact
structure. Prefer clarity over completeness unless more detail is explicitly requested.

Concretely, in chat: findings as a compact list or table, one line each; no narrative build-up before
the point; no worked examples; no restating a finding in a second form for emphasis. A Step 2 report
is a handful of lines. An interview turn is the questions plus at most one line of context each — not
an essay with questions at the end. If a sentence only makes an earlier sentence sound more
convincing, cut it.

This applies to *conversation*. The spec files themselves are written for engineers — schemas,
endpoints, and field-level contracts belong there, in the Data / API Contracts section. Just don't make
the user read them in chat.

## Output location

Everything is written into a `specs/` folder at the root of the **current project** (not this skill's
own directory):

```
specs/
  README.md
  01-<feature-name>.md
  02-<feature-name>.md
  ...
  implementation-plan.md
```

## Parallelizing with subagents

Most of this workflow decomposes into units that don't depend on each other. **Default: if a unit of
work is independent, a subagent does it.** Steps 2, 4, and 7 are where that pays most, but the rule
isn't confined to them — any time you're about to do several things in sequence that could have run at
once, fan out instead.

There's no target count. The number falls out of the decomposition: five subsystems is five agents, nine
feature files is nine. Dispatch them in a single message so they run concurrently — a serial chain of
subagents is slower than doing the work yourself.

Which agent to use:

- **`Explore`** — locating. It reads excerpts rather than whole files, so it maps a surface; it does
  not by itself satisfy Step 2's "read, don't skim."
- **`general-purpose`** — deep reads, external research, and drafting. Anything that has to read a file
  end to end or write one.
- Never `Explore` for Step 7 — drafting agents need write access.

What never gets delegated:

- **The interview (Step 3) and every exchange with the user.** You hold the conversation. Subagents
  never talk to the user.
- **Synthesis** — the gap analysis, the feature breakdown, sequencing, and the final call on what goes
  in a file. Subagents gather and draft; you decide.
- **The gates.** A subagent finishing is not user sign-off.

A subagent starts with none of your context, so every dispatch carries:

- One paragraph on what's being specced and why.
- Its own narrow scope, phrased as the question it must answer — not "go look at the auth code".
- The exact output shape you want back, and a length cap. Findings, not essays.
- For drafting agents: the confirmed requirements, the gap-analysis rows for that feature, the research
  findings with their source links, and the verbatim template for the file it's writing.

Rules:

- **Read every returned report before using it.** Subagents overstate confidence and sometimes report
  things they didn't actually verify. Anything landing in a spec as fact — a schema detail, a rate
  limit, a citation — you spot-check yourself.
- **Never pass a subagent's phrasing to the user unedited.** Their reports are full of identifiers;
  your side of the conversation isn't (see above).
- **Overlap is fine; contradiction is signal.** When two agents disagree about what the code does,
  settle it by reading the code, not by trusting the more confident report.
- **Decompose by the work, not toward a number.** Splitting one small file across three agents costs
  more than reading it. If a slice isn't independently answerable, it isn't a slice — and one obvious
  search or one small file is just work you do inline.

## Workflow (hard-gated — do not skip or reorder steps)

### Step 1 — Intake

Check whether `specs/` already exists in the project.

- **If it exists**: read `README.md` and `implementation-plan.md` first. Default to **update mode**:
  you're adding a new feature to an existing spec set (new numbered file, amended README feature
  list, amended implementation plan), not starting over. If it's ambiguous whether the user wants a
  fresh spec set instead, ask before touching anything.
- **If it doesn't exist**: this is a fresh spec set, starting at `01-`.

Parse the user's request for what's already stated vs. what's unknown — don't ask about things
already answered.

### Step 2 — Read the existing system (required, before the interview)

Never write a spec against an imagined codebase. Understand what already exists first, so the interview
asks about real gaps instead of things the code already answers.

Read, don't skim — go deep enough to be able to state confidently what exists and what doesn't:

- **Data model** — schema files, migrations, model/entity definitions, and any type definitions that
  describe stored data. What entities exist, what they hold, how they relate, what's indexed, what's
  nullable or missing.
- **Interfaces** — API routes/handlers, event topics, message formats, background jobs, integration
  clients. What the system already exposes and already consumes.
- **Existing behavior in the target area** — the modules that would have to change. What the current
  flow does end to end.
- **Stack and constraints in force** — language, framework, database, deployment target, auth model,
  and anything the project's own docs (README, CLAUDE.md, ADRs) declare as a rule.
- **Prior art in-repo** — is there a half-built version of this, a deprecated attempt, or a similar
  feature to model consistency on?

**Fan this out.** These five dimensions are independent — dispatch an agent per dimension, and split
further by subsystem when the request touches several. Use `Explore` first if you don't yet know which
subsystems are in play, then `general-purpose` agents to actually read them; each gets a single question
("what does the stored alert data hold, and what relates to it?").

Demand a structured inventory back, not prose. Step 6 has to classify requirements as *Partly there*,
which needs field-level facts:

- Entities/interfaces found, each with the path it lives at.
- For data: fields, types, nullability, indexes, and relations — the specifics, not "it stores alerts".
- For interfaces: what's exposed or consumed, and the shape of the payload.
- What's conspicuously absent in the area asked about.
- Confidence, and anything it inferred rather than read.

Then read the two or three files that matter most yourself. You're going to be asked about them, and a
report is not a read.

If the project is large, say so and scope the read to the subsystems the request touches. If there is
no codebase (greenfield), say that in one line and skip to Step 3 — but don't assume greenfield without
checking.

**Report back in plain language, in a handful of lines:** what exists today in the area of the request,
what data is already captured, what's already integrated, and the two or three things that look like
they'd have to change. Concepts and capabilities — no identifiers.

### Step 3 — Interview (freeform, no fixed question count)

Have an open, conversational discovery session — not a rigid checklist, not an `AskUserQuestion`
multiple-choice batch. Ask real follow-ups based on what the user actually says. Keep going until the
picture is concrete enough to write from, not until you've hit some quota. Cover, as relevant to the
idea:

- **Problem & goal** — what problem does this solve, for whom, and why now?
- **Users / personas** — who uses this, and do different users need different things?
- **Scope** — what's explicitly in scope for this pass, and what's explicitly *out* of scope (say so
  in the spec — undefined scope boundaries are the #1 source of rework)?
- **Success criteria** — how would you know this worked?
- **Constraints** — technical (existing stack, must-integrate-with systems), compliance/legal,
  timeline, budget, team size.
- **Integration points** — what existing systems, data sources, or services does this touch?
- **Edge cases & failure modes** — what happens when inputs are missing, malformed, delayed, or
  adversarial? What's the degraded/offline behavior?
- **Non-functional requirements** — performance, scale, security, availability, observability —
  whatever's material to this idea (don't force NFR theater onto a trivial feature).
- **Priority / phasing** — if the idea decomposes into multiple features, what's must-have for v1 vs.
  later?
- **Current-state deltas** — anything Step 2 surfaced that contradicts the request, is already partly
  built, or would force a change to existing data or behavior. Ask about these directly; they're the
  questions only someone who read the code can ask.

Use judgment on depth: a genuinely simple, well-specified request needs a short confirmation pass, not
twenty questions. A one-line vague idea needs real digging.

**Start Step 4's research while you're still interviewing.** As soon as the user names an integration, a
standard, or a regulated domain, that research question is independent of everything you have left to
ask — launch the agent in the background and keep talking. Research that lands *after* the sign-off gate
is research that can force you to reopen it: a rate limit or a conformance requirement discovered late
invalidates a design the user already approved. Fold anything that comes back mid-interview into the
questions you're still asking.

**Gate before writing anything:** summarize your understanding back to the user in prose (goal, scope,
non-goals, key constraints, the feature breakdown you're about to spec) and get explicit confirmation
or corrections. Do not proceed past this point until the user has signed off.

### Step 4 — External research (required)

Search the web before writing. Specs written purely from the interview miss standards, existing
protocols, and known failure modes that a few searches would have caught.

Research what's actually relevant to this idea, typically some of:

- **Standards, formats, and protocols** the feature should conform to rather than reinvent.
- **Vendor/API documentation** for anything it integrates with — real limits, real auth models, real
  error semantics. Rate limits and quotas often change the design.
- **Established patterns and known pitfalls** for this class of problem.
- **Regulatory or compliance requirements** if the domain has them.
- **How comparable products handle it**, when the user is deciding between approaches.

**Fan this out** — one `general-purpose` agent per research question. A vendor's real limits, a
standard's conformance requirements, the compliance regime, the known pitfalls, each comparable product:
all independent, all dispatched together, most of them started back during the interview. Each returns a
short list of claims, every claim carrying the URL it came from, plus an explicit "found nothing" where
that's the answer. Drop any claim that comes back without a source, and open the source yourself for
anything that changes the design.

Rules:

- Search rather than answer from memory. If you do state something from memory, label it as unverified.
- Cite the source for every external claim that ends up in a spec — link it in that file's References
  section.
- Tell the user only what changes the spec: "the provider caps this at N per minute, so the sync has to
  be batched" — not a reading list.
- If searches turn up nothing useful, say so in one line and move on. Don't pad.

### Step 5 — Decompose into features

Split the confirmed requirements into discrete, independently-specifiable features or capabilities —
this determines the `01-`, `02-`, ... file list. Each feature file should be buildable and testable on
its own. If the breakdown isn't obvious, propose it and confirm with the user before generating files
(e.g. "I'd split this into auth, session management, and rate limiting — sound right?").

If updating an existing spec set, new features continue the existing numbering.

### Step 6 — Gap analysis (required)

**First, check Step 2 still covers the ground.** The interview routinely pulls in a subsystem nobody
read — a notification path, an export, an auth surface that only came up in question nine. If the
confirmed scope reaches past what Step 2 covered, fan out again over the newly-in-scope areas before
analysing anything. A gap analysis against a stale read is worse than no gap analysis: it reports
*Not there* for things that already exist.

For each feature, compare what Step 2 found in the code against what the confirmed requirements need.
Sort every requirement into one of four buckets:

- **Already there** — works today, no change needed. Say so; don't spec it again.
- **Partly there** — exists but needs extending, and what specifically is missing.
- **Not there** — has to be built from nothing.
- **In the way** — existing data, behavior, or assumptions that actively conflict with the requirement
  and have to change. Call out anything that means a data migration, a breaking interface change, or a
  behavior change for existing users. These are the expensive ones — they belong at the top.

This analysis is what makes the implementation plan honest about effort and sequencing. Feed it into the
build order: work that unblocks other work, and migrations, go first.

Report the gaps to the user before generating files — in plain language, expensive items first. If the
gap analysis reveals the scope is materially bigger or smaller than what was agreed at the Step 3 gate,
say so and confirm the plan still holds before writing.

### Step 7 — Generate files

Use the templates below. Write real content — every section filled in from the interview, the codebase
read, and the research; no placeholder text. If something is a genuine open question none of those
resolved, put it in that file's "Open Questions / Assumptions" section rather than inventing an answer.

Mark clearly in each spec what is existing behavior vs. new work, so nobody rebuilds what's already
there.

**Draft in parallel — one `general-purpose` agent per numbered feature file.** Each drafting agent gets
the goal/scope/non-goals from the Step 3 gate, its feature's confirmed requirements, its gap-analysis
rows, the research claims and links relevant to it, the paths from Step 2 that its Current State & Gaps
section must reference, and the `NN-<feature-name>.md` template verbatim. Tell it which file to write
and to write nothing else. Nine features means nine agents in one dispatch.

**In update mode, only dispatch agents for files that don't exist yet.** An agent handed the path of an
existing numbered file will overwrite it wholesale, which is exactly what the conventions below forbid.
Amendments to existing feature files are edits you make yourself, in place.

`README.md` and `implementation-plan.md` you write yourself, after the feature drafts land — they
summarize across all of them, and in update mode they're amended, never regenerated.

Then read every draft end to end and fix them yourself. Expect the seams parallel drafting creates:

- The same concept named two different things across files.
- Requirements duplicated in two features, or a boundary neither file claims.
- Invented content where an agent papered over a gap instead of using Open Questions / Assumptions.
- Citations that don't support the claim attached to them.
- Dependencies asserted in a feature file that the implementation plan doesn't reflect.

After writing, tell the user what was created/updated and where.

## File templates

### `specs/README.md`

```markdown
# <Project/Feature Set Name>

## Problem Statement
<what problem this solves and why it matters, in a few sentences>

## Goals
- <goal>

## Non-Goals
- <explicitly out of scope, and why>

## Personas / Users
- **<persona>** — <what they need from this>

## Current State
<what the system does today in this area, what data it already holds, what it's already integrated
with — the baseline this spec set builds on. One short paragraph or a few bullets. Omit only if
greenfield, and say so if it is.>

## Key Gaps
<the system-wide gaps between today and the goal, biggest first. Call out anything requiring a data
migration, a breaking change, or a change in behavior for existing users. Per-feature detail lives in
the numbered files.>

## Features
| # | Feature | Status |
|---|---------|--------|
| 01 | [<name>](01-<name>.md) | Not Started |

See `implementation-plan.md` for build sequencing and current status.

## Glossary
<only if the domain has non-obvious terms>
```

### `specs/NN-<feature-name>.md`

```markdown
# NN — <Feature Name>

## Overview
<what this feature is, in 2-4 sentences>

## User Stories
- As a <persona>, I want <capability>, so that <outcome>.

## Current State & Gaps
| Requirement | Today | Gap |
|---|---|---|
| <requirement> | Already there / Partly there / Not there / In the way | <what has to change> |

<Below the table, note any migration, breaking change, or backward-compatibility constraint this
feature forces. Reference the relevant part of the codebase by path where an engineer would need the
pointer.>

## Functional Requirements
- <numbered, testable requirements — "the system shall...">

## Non-Functional Requirements
- <performance / security / scale / availability — only what's material>

## Data / API Contracts
<schemas, endpoints, payloads — only if applicable to this feature>

## Edge Cases & Error Handling
- <case> → <expected behavior>

## Acceptance Criteria / Test Plan
- **Given** <context>, **when** <action>, **then** <expected result>.
<cover the happy path, edge cases above, and failure modes — this is the comprehensive test
deliverable for this feature, written as acceptance criteria, not code>

## Open Questions / Assumptions
- <anything the interview didn't fully resolve, flagged rather than silently decided>

## References
- [<source title>](<url>) — <what it constrains or informs in this spec>
<external standards, API docs, or compliance sources this spec relies on. Omit the section if the
feature needed no external research.>
```

### `specs/implementation-plan.md`

```markdown
# Implementation Plan

Tracks build status across the features defined in `specs/`. Update this file — don't regenerate it
— as features move through implementation.

| # | Feature | Status | Depends On | Build vs. Extend | Notes |
|---|---------|--------|------------|------------------|-------|
| 01 | <name> | Not Started / In Progress / Done | <#s or —> | New build / Extends existing | <notes> |

## Sequencing Notes
<why features are ordered this way, if not obvious from dependencies. Migrations and breaking changes
go early — name them here.>
```

## Conventions

- Feature names are kebab-case: `01-authentication-mechanism.md`.
- Numbering starts at `01` for the first feature; `README.md` is the implicit overview and is not
  itself numbered.
- Never silently overwrite an existing `specs/` folder. Read it first; default to update mode; confirm
  before doing anything destructive (rewriting an existing numbered file's content wholesale, renaming
  files, etc.).
- `implementation-plan.md` is a living document — subsequent invocations of this skill (or other work
  sessions) should update its status column rather than treat it as static output.
- Never spec against an assumed codebase. If you didn't read it, don't claim it — write it as an
  assumption instead.
- Never invent an external fact to fill a gap. Either cite it or flag it as an open question.
