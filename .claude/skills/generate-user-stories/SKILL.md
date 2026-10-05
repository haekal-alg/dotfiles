---
name: generate-user-stories
description: Scan the whole project — git history on every local branch, docs, and the files commits touched — and write user-stories.md, grouping the work into user stories that each carry a short explanation plus proof (commit hash and web link). For logging work into a time/project tracker. Use when the user asks to generate, refresh or regenerate user stories, or to list the work done for tracking.
argument-hint: "[author-regex] [--since YYYY-MM-DD]"
---

# Generate user stories

Turn the repository's history into a list of user stories the user can paste into a time or
project tracking app. Each story is one unit of work someone would log, backed by the commits
that prove it happened.

## Gotchas first

- **Unpushed commits have dead links.** A commit URL only resolves once the remote has it. The
  collector marks each commit `pushed: yes|no`; keep that flag in the output. Never drop the link
  or pretend it works — the user may push later, and the link will then be right.
- **One person, several identities.** Check `git shortlog -sne --all` before collecting. If other
  identities look like the same person (a personal email, a handle), include them via the regex
  argument. If it's unclear whether an identity is the user, ask.
- **Every local branch counts, not just the current one.** Work on side branches is still work.
  Note the branch when a story lives only off the main line.
- **Never invent.** Hashes and URLs are copied from the collector output verbatim, never retyped
  from memory. Don't estimate hours — the tracker entry is the user's to fill; give dates only.
- **Regenerating overwrites `user-stories.md`.** Read the existing file first. If the user has
  hand-edited it (notes, tracker IDs, changed titles), keep those edits and tell them what you kept.

## Steps

1. **Collect.** Run the collector from the repo root and save the output to the scratchpad:
   ```
   .claude/skills/generate-user-stories/collect-commits.sh '<author-regex>' > <scratchpad>/commits.txt
   ```
   It prints one record per commit, oldest first: full hash, date, pushed flag, URL, branches,
   subject, diffstat, files touched, and the first lines of the body. If `--since` was given,
   drop earlier commits when grouping. If the output is too large to read in one pass, say so and
   read it in chunks — read all of it before grouping.

2. **Get context.** Read the project's top-level docs (README, CLAUDE.md, any handoff/design
   notes) so stories are named in the project's own vocabulary, not in terms of file names. Open
   a file a commit touched only when its subject and body don't explain what the work was.

3. **Group commits into stories.** A story is a coherent piece of user-facing or project value:
   a feature, a rework, a piece of infrastructure, a round of fixes to one area. Rules:
   - Group by what the work achieved, not by date or by file. Commits days apart on the same
     feature belong together.
   - Every commit lands in exactly one story. Housekeeping (gitignore, lockfiles, typo fixes)
     goes into the story it served, or one "Project housekeeping" story — never dropped.
   - Aim for stories that are loggable: roughly 2–8 commits each. A single large commit can be
     its own story.

4. **Write each story** with:
   - **Title** — short, outcome-first.
   - **User story line** — "As a <role>, I want <capability>, so that <benefit>." Pick the real
     role from context (presenter, audience, maintainer, reviewer…).
   - **Description** — 2–4 plain sentences: what was built or changed and why it mattered.
   - **Dates** — first and last commit date (YYYY-MM-DD).
   - **Proof** — a table of every commit: short hash, date, subject, link, pushed flag.
     Link text is the short hash; target is the full-hash URL from the collector.

5. **Write `user-stories.md`** at the repo root in this shape:

   ```markdown
   # User stories — <repo>

   Generated <today> from <N> commits on <branches> by <identities>.
   Commits marked ⚠ unpushed are not on the remote yet; their links will 404 until pushed.

   ## Summary
   | # | Story | Dates | Commits |
   |---|---|---|---|

   ## 1. <Title>
   **As a** …, **I want** …, **so that** ….

   <description>

   **Dates:** 2026-01-02 → 2026-01-05 · **Branch:** <only if not on the main line>

   | Commit | Date | Change | Pushed |
   |---|---|---|---|
   | [`abc1234`](<full url>) | 2026-01-02 | <subject> | ✅ / ⚠ unpushed |
   ```

   Stories in chronological order of their first commit.

6. **Verify before reporting.** Check mechanically, not by eye:
   - every hash in the collector output appears in the file exactly once;
   - no hash in the file is absent from the collector output;
   - the summary table's commit counts sum to the total.
   A short script against `commits.txt` and `user-stories.md` does this. Fix and re-check if any
   fail.

7. **Report** in a few lines: how many stories, how many commits, how many unpushed, and any
   identity or grouping call the user may want to revisit. Don't paste the file back.
