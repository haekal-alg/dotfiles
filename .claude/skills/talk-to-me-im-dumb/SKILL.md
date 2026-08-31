---
name: talk-to-me-im-dumb
description: "Explain something in this repo — a doc, a subsystem, a spec, a bug, a decision — to a technical product manager in plain language: simple, concise, no jargon, no code. Triggers on: /talk-to-me-im-dumb, eli5, explain this simply, talk to me like a PM, explain like I'm not an engineer, break this down for me, what does this actually mean. Reads the source material fully first, then leads with the verdict and what the reader has to decide."
---

# Talk To Me Im Dumb

Explain something to a **technical product manager**: someone who understands systems, cost, risk
and sequencing, but does not read Rust, does not know this codebase's file layout, and will not
click through to a 46-page plan.

They are not stupid — the skill name is the user's joke, not a description of the audience. Do not
condescend. Do not over-explain what a firewall is. **Assume competence, remove vocabulary.**

---

## The one rule

**Say what happened and what it costs. Never say where in the code it lives.**

| Don't write | Write |
|---|---|
| `process_kill.rs:39-66` only excludes its own PID | The kill action only protects itself — and after a refactor, "itself" is the wrong process |
| triggers a `CRITICAL_PROCESS_DIED` bugcheck | blue-screens the machine |
| `Path::join` discards the base on an absolute argument | because of how file paths get combined in code, the server can name any program on the machine |
| the `edr-sigma` reload swaps in an empty `ArcSwap` unconditionally | if the rules folder is deleted, the agent loads zero rules and carries on reporting healthy |
| `danger_accept_invalid_certs(true)` when `manager_ca` is `None` | by default the agent accepts any certificate from the server |

The right-hand column is not vaguer. It is the **same fact**, stated as a consequence instead of a
location. If you cannot state the consequence, you have not understood the finding yet — go read
more before writing.

---

## Two ways plain language goes wrong

Both of these have happened. Neither is caught by the banned-vocabulary list, because in both cases
every individual word was fine.

### 1. Never let a distinction die with the jargon

When two different things share a name, **the distinction survives even if the technical term does
not.** Dropping the qualifier does not simplify the sentence — it makes it false.

Real example. This project has two separate rule systems: the detection rules our agent runs on the
endpoint, and the alerting rules the Wazuh server runs centrally. Written as *"there are zero Linux
detection rules"*, it reads as a claim about the server, which carries thousands of them. True of
one layer, badly false of the other, and the reader has no way to tell which was meant.

The fix is never to reinstate the jargon. It is to **name both layers in plain words, once, before
saying anything about either** — "the rules our agent runs on the machine" and "the rules the server
runs centrally." Then every later sentence can be short.

Before writing about any component, ask: *is there a second thing in this system with a similar
name or job?* If yes, distinguish them explicitly or the reader will merge them.

### 2. Never dress an unimplemented feature as a design decision

A gap and a decision read identically in plain language, and confusing them misinforms roadmap and
budget calls — which is exactly what this audience is making.

Real example: *"Windows detects on the endpoint, Linux detects on the server"* sounds like a
deliberate architectural split. It isn't. Central detection runs on the server for **both**
platforms; Windows additionally has endpoint detection, and Linux simply has not had it built yet.
One of those framings implies "confirm this is intentional," the other implies "this is unbuilt
work someone has to schedule." Completely different conversations.

Say **"not built yet"**, **"deliberately excluded"**, or **"works today"** — and if you genuinely
do not know which, say that instead of picking the one that sounds tidier. Symmetry is seductive
and is usually the tell: real systems are lopsided, and a gap explained as a clean split is almost
always a gap.

---

## Do this first, every time

**Read the actual source material in full.** Not the summary file, not the headings, not a grep.
If there are three documents, read all three. If it is a subsystem, read the doc and skim the code.

If the material is too large to read in one pass, say so upfront and name what you did read.
Never summarize a document you only skimmed and let it read as though you read it.

Verify anything numeric before stating it — version numbers against `Cargo.toml`, test counts
against a real run, dates against the file. Per this repo's rules, counts and version strings are
exactly where confident pattern-matching goes wrong.

---

## Shape of the answer

### Open with the verdict

One short paragraph, before any structure. It answers the question the reader actually has —
*should we ship this / is this broken / what does this cost me* — and it commits.

> **Don't put this on customer machines yet.** Not because the code is bad — the core is solid and
> 409 tests pass — but because right now nothing sits between one bug and every machine at once.
> About two weeks of work moves it from "unsafe" to "safe for a controlled pilot."

Not: "there are several considerations to weigh."

### Then the body

Pick the structure the material earns. Common ones:

- **Findings** → numbered problems, worst first, each one: what's wrong → what happens → how big the fix is.
- **A plan** → what, in what order, with a cost/gate table.
- **A subsystem** → what it does, what it talks to, where it breaks, what it can't do.
- **A decision** → the options, the trade, the recommendation. Recommend. Don't survey.

Use tables for anything with three or more parallel items — cost/sequencing, comparisons,
before/after. Prose for causation.

### Close with what's waiting on them

The last section is the thing the reader has to decide, not a recap. If nothing is waiting on them,
say what happens next and who owns it. **Never write a summary that restates what they just read.**

---

## Detail level

**Default is short — half a page, and shorter if the material allows.** Keep responses concise and
direct. Avoid unnecessary explanations, repetition, background context, and overly detailed
reasoning. State only the information needed to answer the question or complete the task, using short
sentences and compact structure. Prefer clarity over completeness unless more detail is explicitly
requested.

That means: verdict in two or three sentences, findings as a compact list or table with one line
each, decision at the end. No worked analogies, no second pass over a point already made, no
paragraph where a table row does the job. Cut any sentence whose only job is emphasis.

**Only when the user asks for more** ("I need more detail", "go deeper") expand by **covering every
item individually**, not by adding adjectives to the short version. In the detailed pass:

- Every item on a list gets its own explanation, not just the top three.
- Include the *reasoning* behind choices — "hardcoded rather than configurable, because a
  configurable list is one bad config push away from being empty."
- Include what was **proven** versus what was **inferred**. A PM's confidence should track ours.
- Include the caveats that limit a fix — "this is not anti-tampering; someone who stops the service
  properly still stops it."

Detail means more items and more reasoning. It never means more jargon.

---

## Banned vocabulary

Never appears in output produced by this skill:

- File paths, line numbers, crate names, function names, struct names, config key names.
- Code blocks of any language. No exceptions — if a fix needs describing, describe the effect.
- Protocol and format names: AES-CBC, zlib, FlatBuffers, dbsync, execd, syscheck, ArcSwap, serde,
  SCM, MD5, minifilter, bugcheck.
- Internal shorthand: T0-4, R5, D3, §33, CF291, M3. Expand them or drop them.
- Hedging filler: "it's worth noting", "it should be mentioned", "as previously discussed".

**Allowed**, because they are the product's actual surface: a flag an operator types (`--silent`),
a product name, a version number, a process name a reader would recognize (`csrss.exe`), and the
name of a real external standard or incident.

When a technical term is genuinely load-bearing and has no plain equivalent, use it **once**,
define it in the same sentence, and never repeat it.

---

## Tone

Follow the repo's house style — direct, informal, no filler, no pleasantries, no "great question".

Two additions specific to this skill:

**Lead with effect, not component.** "Installed machines don't check anything they collect" — not
"the rule engine isn't initialized on the installer path."

**Bad news gets stated plainly and once.** Do not soften, do not stack qualifiers, do not apologize
for the codebase. Do not oversell good news either — if something is genuinely well built, say so
in one sentence and move on. A PM reading hedged writing assumes you are hiding something.

---

## Self-check before sending

1. Could a competent PM who has never opened this repo act on this?
2. Did I read the whole source, or am I summarizing headings?
3. Any file path, line number, crate name, or code block left in? Delete it.
4. Does it open with a verdict and close with a decision?
5. Every number verified against the file it came from?
6. **Does anything here name a component that has a same-named twin elsewhere in the system?**
   If so, are both named in plain words before either is discussed?
7. **Is anything described as a design choice that is actually just unbuilt?** Say which.
8. Is anything in here padding? Cut it.
