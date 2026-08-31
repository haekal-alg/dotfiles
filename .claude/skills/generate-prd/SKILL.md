---
name: generate-prd
description: "Turns written specs, a codebase, or a feature idea into a single decision-ready PRD published as a styled Artifact web page for product managers and executives. Triggers on: /generate-prd, generate a PRD, write a product requirements doc, turn these specs into something my PM can read, make a one-pager for leadership, prd artifact. Produces a self-contained HTML page (summary, flow diagrams, per-feature sections, phases, have/don't-have requirements, acceptance tests, owner questions, risks, glossary) and publishes it with the Artifact tool."
---

# Generate PRD

Produces **one** deliverable: a self-contained HTML page, published with the Artifact tool, that a
product manager or executive can read end to end and then make decisions from.

This is not a spec. Specs are for engineers and live in the repo. **This page is for the person who
decides whether to fund, sequence, or ship the thing** — and, critically, for the person who has to
answer the questions only they can answer. If the reader finishes the page and still does not know
what you need from them, the page failed.

---

## The one rule everything else serves

> **Every claim carries its provenance, and every limit is stated before the reader finds it
> themselves.**

A PRD that only sells is worth nothing, because the reader discounts all of it. The credibility of
the optimistic parts comes entirely from the presence of the pessimistic ones. When you are tempted
to soften a limitation, sharpen it instead.

Concretely: no number appears without saying where it came from, and no capability is called "have"
unless a check was actually run.

---

## Before writing a single line

Ground the document. **Never invent content for a PRD** — a fabricated figure in a document that goes
to leadership is worse than no document.

1. **Read the source material fully.** Specs, task lists, changelogs, the code if that is what
   exists. Read whole files, not greps. If there is too much to read in one pass, say so up front and
   name what you skipped.
2. **Separate what is verified from what is assumed.** Build this list before drafting. It becomes
   §"Requirements" almost verbatim, and it determines every pill colour on the page.
3. **Run the cheap checks you are able to run.** If credentials, a live endpoint, a test host, or a
   build are available, *measure* rather than asking. One query that answers an open question is
   worth more than a paragraph explaining that the question is open. Read-only checks: just run them.
   Anything that writes, deploys, or is hard to reverse: ask first, then run.
4. **Look for external precedent** — a published paper, an open-source implementation, a competitor's
   documented approach. Search rather than recalling. If you find one, §Precedent applies (below) and
   so does its trap.
5. **Establish the version number from the single source of truth** (`Cargo.toml`, `package.json`,
   `pyproject.toml`, whatever the project uses). Never from memory, never from another document.

If asked to produce a PRD for something with no source material and no way to check anything, say
that plainly and offer to run `/generate-specs` first. A PRD is a synthesis; there has to be
something to synthesise.

---

## Register: how the page talks

The reader is technically literate and does **not** want to read code.

**Banned from the prose** — not softened, banned: crate/module/package names, file paths, function
names, wire formats, protocol names, acronyms the reader would have to look up, and internal
codenames. If a concept genuinely needs one, it goes in `<code>` inside a table cell or the glossary,
never in a sentence the reader must parse to follow the argument.

**Required instead:**

| Instead of | Write |
|---|---|
| "the `edr-fim` crate emits syscheck events" | "the agent reports file changes" |
| "AES-CBC secure channel" | "the encrypted link to the server" |
| "`4688` process-creation telemetry" | "records of programs starting" |
| "the anomaly-detection plugin" | "the platform's own statistical baselining feature" |

Two more register rules:

- **Lead with the effect, not the component.** "Fixed a crash that stopped the agent starting after a
  rejected enrolment" beats "fixed a panic in the enrolment handler".
- **Sizing is complexity, never calendar.** `trivial` / `moderate` / `substantial` /
  `needs-research`. Day estimates in a PRD get quoted back as commitments.

If the project has its own release-notes or plain-language rules (check `CLAUDE.md` or equivalent),
those win over this section.

---

## Structure

A fixed spine with a variable middle. Number the sections; the table of contents is generated from
them and every internal reference uses `§N`.

| # | Section | Include when | Purpose |
|---|---|---|---|
| 1 | **Executive summary** | Always | Feature cards, a one-line-per-part table, and the blocker box if one is live |
| 2 | **How the information flows** | Two or more moving parts | One mermaid diagram per feature. Where the work happens, and where it ends up |
| 3…N | **One section per feature** | Always | Problem → precedent → the concrete list of what it detects/does → limits → measured facts → decisions taken |
| N+1 | **Implementation phases** | Always | Ordered, complexity-tagged, with explicit gates, and each phase's traceability line (below) |
| N+2 | **Requirements: have and don't-have** | Always | The section to read if you only read one |
| N+3 | **End-to-end acceptance tests** | Anything being built | What "done" means, in given/when/then |
| N+4 | **Questions for you to answer** | Always | The point of the document |
| N+5 | **Risks** | Always | Including the ones you cannot fix |
| N+6 | **Glossary** | Any unavoidable term | Plain definitions |

Collapse §2 into §1 for a single-feature page. Never drop §N+2 or §N+4 — those two are the document.

### §1 Executive summary

One card per feature, each with a readiness pill and a `dl` of Catches / Where / Order. Then a table
with one row per implementable part, one line each. A reader who stops here should know what is being
proposed, in what order, and what is standing in the way.

### §3…N Per-feature sections

**Problem first, in the reader's terms.** What is invisible or broken today. Follow with an
`alert note` titled "In plain terms" containing the single analogy that makes it land — that box is
often the only thing a busy reader remembers.

**Then precedent, if any — and mind the trap.** If someone has published this, their production
figures are your strongest evidence. But:

> **When you quote someone else's results, state what produced them.** If their system works
> differently from yours — different mechanism, more infrastructure, a cost you are not paying — say
> so *in the same breath*, next to the numbers. Otherwise the quoted figures read as a claim about
> your design, which is a lie by placement even when every sentence is true.

The canonical failure: quoting an AI-based system's benchmark results beside your own rule-based
design without saying theirs needs two model vendors and yours has none. Pair every precedent table
with a take-and-leave table — their parts down one column, `taken`/`left` pills, and *why* for each.

**Then the concrete list** — the rules, detections, checks, whatever the unit is — with an "honest
reach" column stating what each one cannot do. Not a caveats section at the end. Per row.

**Give every row a stable ID** (`R1`, `D2`, …) taken from the source spec's own numbering, not
invented for the page. Reuse that exact ID everywhere the row is touched again: the phase that ships
it (§N+1), the acceptance test that exercises it (§N+3), any risk or requirement row about it. A rule
named "R1" in the table and "Rule 1" in the test is two names for a reader to reconcile themselves —
that reconciliation is your job, not theirs. If a row is a designated scope cut, say what happens to
the count and to every downstream reference if it goes (a rule table of six that becomes five, not a
silent renumbering of R6 to R5).

**Then the limits**, as `alert warning` boxes, one per real limitation. If you can only think of one,
you have not thought hard enough; three is typical for anything detection-shaped. Cover at minimum:
what the evidence cannot prove, what the mechanism structurally cannot see, and who it fails against.

**Then measured facts**, in a table, each labelled with when and where it was measured — and a
caption drawing the design consequence. A number without a consequence is trivia.

### §N+2 Requirements — the load-bearing section

Two tables. **Have — verified, not assumed**, and **Don't have**. Every row in "have" needs a "how we
know" cell naming an actual check on an actual date. If you cannot fill that cell, the row belongs in
"don't have" as `unknown`.

The verdict pill is doing real work — get it right:

- `have` — a check was run and passed. Not "it should work".
- `not needed` — genuinely out of scope. Say why here, because this is where readers assume you
  forgot something.
- `partial` — works in some conditions. **Name the conditions.**
- `unknown` — nobody has checked. Say what checking costs.
- `don't have` — checked, absent. Say what it blocks.

### §N+4 Questions — the reason the page exists

A table: number, question, **why it is yours** (not ours), and where it stands. A question belongs
here only if it needs a decision or an action the reader owns — money, risk appetite, access,
priority, a customer commitment. Anything you can determine yourself, go determine.

Follow it with an **"Already decided"** table so settled matters do not get relitigated.

---

## The six rules that keep the document honest across revisions

These are what make a PRD trustworthy on its third revision rather than a set of stale assertions.

**1. Close questions by striking them, never by deleting them.**
A question that got answered stays in the table wrapped in `<s>`, with a `closed` pill and *what*
closed it. A reader who saw revision 2 must be able to see what happened to the thing that was
blocking. Silently shrinking a list makes every future list untrustworthy.

**2. When a blocker clears, replace its box with what you found — do not remove it.**
The `alert caution` at the top of §1 becomes an `alert tip` titled "Resolved on DATE", saying what
cleared it and, more importantly, **what the answer changed**. Blockers rarely clear cleanly; usually
you learn something that moves the plan.

**3. Every revision carries a "What changed" note box.**
Bump the revision number in the eyebrow. In an `alert note`, say what is different and what is
merely restructured. If nothing was re-checked since last time, say that too — a reader must never
have to guess whether a figure is fresh.

**4. A measured number can invalidate the conclusion you were about to draw. Let it.**
If you measure something to support a claim and the measurement undercuts it, the finding *is* the
contribution. Report it prominently rather than burying it. Volume that turns out to come from
infrastructure the customer will not have; a platform that has the data but not the right data; a
retention window too short for the plan — these are the highest-value paragraphs on the page.

**5. Raise what you found outside your scope.**
Running checks surfaces things that are not yours: an exposed credential, misconfigured storage, a
silent data-loss path. Put them in their own box marked clearly as not-ours-and-not-blocking. Finding
them and saying nothing is the wrong call. Do not fix them silently either.

**6. Every phase and every rule must be checkable against its source, not just plausible.**
A phase description that says "wire up the manager side" tells a reader nothing they can go verify.
Name what it actually touches: the crate or index, the config key or object, the target host with its
address when a live system is involved, the file paths, the verify command if one exists, and the
exact commit message — taken line for line from the source spec's own task list, in the `.pm` metadata
line under the phase (`references/skeleton.html` demonstrates it). This document and that file must
never be able to drift apart silently. Pair it with rule-ID consistency above: if someone can trace a
claim in this page back to a specific line in the repo, the page is evidence; if they can't, it's
prose.

---

## Producing the page

1. **Start from `references/skeleton.html`** in this skill directory. It carries the full stylesheet
   and one worked example of every component (cards, alerts in all five tones, an ID-tagged rule
   table, tables, phase list with its `.pm` traceability line, mermaid figure, checklist, score chart,
   pills). Copy it, replace the demo content, delete unused components. Do not re-derive the CSS.
2. **Write to a file** in the scratchpad directory (or wherever the user asked), then call `Artifact`
   with that path. No `<!doctype>`, `<html>`, `<head>` or `<body>` tags — the harness wraps it.
   Include a `<title>`.
3. **Load the `artifact-design` skill first**, as the Artifact tool requires.
4. **Self-contained only.** Strict CSP: no CDN, no external fonts, no remote images. Mermaid renders
   natively from `<pre class="mermaid">` — do not import a library.
5. **Republish to the same URL** when revising: pass the artifact's `url`, or just re-publish the
   same file path within the same conversation. A new path mints a new link and orphans the old one.
6. Pass a `favicon` and keep it stable across revisions — readers find the tab by its icon.

### Design decisions already made — keep them

- **Prose runs the full page width.** Do **not** put a `max-width` measure cap on `p`/`li`. It is
  good typography in isolation and looks broken here, because tables, diagrams and cards are
  full-bleed — capped prose leaves a ragged 25% gutter beside every one of them. The page is 960px;
  that *is* the measure.
- **Single-theme, light, GitHub-README styled**, with the dark-mode override deliberately neutralised
  and a comment saying why: this is a print-and-share document, and a viewer's dark toggle must not
  repaint it mid-presentation.
- **Every table wrapped in `.tw`** so wide content scrolls in its own box and the page body never
  scrolls horizontally.
- **Alert tones carry meaning**, so use them consistently: `note` = context or analogy · `tip` = good
  news, resolved · `important` = a decision the reader must not inherit silently · `warning` = an
  honest limitation · `caution` = a blocker or a danger.
- **Pills:** `ok` green, `no` red, `unk` amber, `dec` purple (a decision taken), `flat` grey
  (neutral, e.g. complexity), `brand` teal.
- **Phase `.pm` lines are structured data, not prose.** Bolded labels, `code` for identifiers,
  `·` between clauses — copied from the spec's `tasks.md`, never composed fresh. If a phase's
  tasks.md entry has nothing concrete to name (rare — usually means the phase description itself is
  too vague), that is a signal to sharpen the phase, not to write a vaguer `.pm` line to match.
- Responsive rules for narrow screens are already in the stylesheet. Leave them.

---

## Finishing

Report to the user in the chat: the link, what changed in this revision, and — separately, because
they will act on it — **the questions from §N+4 that are still open**, with the single highest-value
one named. Do not paste the document's content back into the chat; they are about to read it.

If producing the PRD revealed findings that belong in the repo (measured facts, resolved blockers,
corrected assumptions), offer to write them back into the source specs. A PRD that knows something
the specs do not is a trap for the next engineer.
