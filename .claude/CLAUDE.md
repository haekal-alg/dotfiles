# CLAUDE.md — general development guidelines

Applies to every project. Each project's own CLAUDE.md adds what only it knows (Part 2): its gate, stack, shared files, targets and lessons. Where the two conflict, the project file wins for that project.

---

## Part 1 — How to work

### Workflow
- Ambiguous request: state assumptions and surface the interpretations; don't silently pick one. Ask when the answer changes what you build. Never invent a name, file, or fact you can't verify — say you don't know it.
- Unclear approach or multi-file change: explore, write a plan, wait for approval before editing. If the diff fits in one sentence, skip the plan and do it.
- Design work (a new feature, a revamp of an existing screen, a new look being explored) needs the owner's visual confirmation before any code: show a board or mockup, wait for the go-ahead, then implement. Hotfixes, bug fixes, copy changes and other minor adjustments skip this and go straight to code.
- Follow patterns already in the codebase. Ask before adding a dependency.
- Before implementing code, invoke the `ponytail:ponytail` skill.
- Surgical edits: change only what the task needs. Flag adjacent problems in the report; don't fix them silently.
- Bugs found along the way hurt the user: fix every one that can be fixed, without asking first, as its own commit with its own failing-first test (not folded into the task's diff), and list it in the report. Product calls, redesigns and anything that changes a look still go to the owner first.
- Bugs: write a failing test that reproduces it, then fix the root cause. Never suppress the error, skip the test, or loosen an assertion to go green. State where the bug lived and whether the fix addresses symptom or cause.
- Wide codebase searches or research: use a subagent so the main context stays clean.
- Commit on your own after each large feature passes the gate: one commit per feature, with its plan tick and decisions-log entry (if the project keeps them), so any feature can be reverted and progress shows in `git log`.
- Record every decision in the project's decisions log in the same step as the change, not afterwards.
- When the owner asks you to remember something, write it into the project's CLAUDE.md (or a doc it points to), not only auto-memory, so a fresh context still has it.
- Lessons learned while working (a measuring method, a trap, a cause of jank, a tool quirk) go into the project's CLAUDE.md in the same session, under the part they belong to, without being asked. One line each, with the evidence and date. A lesson that holds for any project goes here instead.

### Parallel work (subagents, worktrees)
- Always parallelize research, review, and mechanical fan-out (same change across many files).
- Parallelize implementation only when tasks touch no shared files and their interfaces are fixed in the plan before they start. Otherwise run sequentially.
- Shared-file changes (Part 2) land first, sequentially, before parallel tasks branch off.
- Each implementing agent works in its own git worktree and must pass the project's gate on its own.
- The main session owns the plan, assigns tasks, and merges. No agent merges its own work.
- After merging, one review subagent checks the combined diff. Individually correct changes can still conflict in behavior.
- Watch running agents. Each brief states the expected run time, and agents commit after every finished task, so progress shows in `git log`. At every turn, check each running agent (age, last commit). One that runs past twice its expected time, or an hour with no new commit, is stopped, its work saved as a WIP commit, and the case logged (in the build plan's "Anomalies", if there is one) with what it was doing and the time lost.
- A new worktree can start behind main: compare `git log -1` with the brief's base and fast-forward before the first edit, or plan and decision-log ticks conflict at merge.
- Agents can share one scratchpad root: each keeps its scripts and screenshots in a subfolder named after itself, and never moves or overwrites a file there it didn't create. Same-named helper scripts from two agents silently run in each other's worktree.
- A worktree agent's sandboxed shell may refuse `source`, `cd … && …` chains, multi-command remote shells and variables it can't verify: put the chain in a small script in its scratchpad subfolder and run that script by path.
- Don't use agent teams (experimental). Use subagents + worktrees.

### Verification
- IMPORTANT: work is not done until the project's gate passes, and you show evidence (command and output, or a screenshot). "Should work" is not done. If the project defines no gate, say so and ask before declaring anything done.
- Before reporting a multi-file change as done, have a subagent review the diff against the plan in a fresh context. Act only on gaps in correctness or stated requirements, not style.
- A change to what the user sees isn't done until it has been driven in the real runtime (browser, emulator, device): every new path, screenshots in light and dark. Test renders skip the real keyboard, scrolling, sheets, dialogs and navigation.
- **QA pipeline before a build reaches a real user or device, in this order:**
  1. The gate.
  2. Repeat tests: every action that writes data (a save, an edit, anything that learns or keeps an Undo) has a test that does it 30 times in a row and checks that each run stays fast and what's stored grows by a constant per run. One run hides anything that grows with use.
  3. Drive it in the real runtime: every new path, then the main action at least five times in a row with different inputs, then the project's health check (logs, crash reports, storage size) shows 0 problems.
  4. Commit, build, install, and after the owner has used it, run the health check on their device.
- When the owner reports a crash, a freeze or "it hangs", collect the evidence first (crash/ANR reports, logs, storage size, memory) and read it before guessing at a cause.
- A test written for a fix must fail without it: run it once against the old code. Test data that happens to make both cases equal (same row counts, same lengths) passes either way.
- A stored snapshot for Undo leaves out the snapshot it replaces: kept in, each save nests every earlier one, and escaping makes the stored text double each time (seen: 21 saves, ~200 MB, out of memory).
- Something a save carries over from an earlier record is recorded as carried over, not learned: undoing the earlier save must take it back from the later ones too.
- Design boards and mockups are the source of truth the code is built from, so they must be pristine before the owner sees them. Render every board at its real size, light and dark, and look at each one: no text touching or crossing its container, no field or row wider than the screen, no image scaled or squeezed (capture at the board's exact width, at 3× density). Fix and re-render until clean, then share. This applies even when a tool's own instructions say not to verify.
- Board traps: an HTML `<input>` defaults to ~20 characters wide, so in a flex row it overflows unless it gets `width: 100%; min-width: 0` and its wrapper `min-width: 0`. Fixed-width grids of chips or tiles must fit their longest real label at the type style used; measure, don't estimate. Every board page starts with `<meta charset="utf-8">`, or a local static server (no charset header) renders curly quotes and ellipses as mojibake. A screenshot script must fail any board that didn't render: a 404 page once passed as "clean". A localhost port already in use answers with someone else's 404; confirm a 200 first.

### Reporting (the reader is a technical PM)
- Report: what changed, why, the decision made and alternatives rejected, what is blocked or needs a call.
- No code or function names unless asked. File paths only as `file:line` references, never pasted code. No recap at the end.
- Use the skill `/i-have-adhd:i-have-adhd` when you talk to me.

### Context
- When compacting, preserve: modified files list, current gate status, open decisions.

### Code style
- Comment the *why* for non-obvious logic and approach choices. No ticket IDs or process notes in comments.
- Don't delete existing comments as a side effect of an edit.
- Never run a formatter over files that aren't already in its style: it rewrites whole files and buries the real diff (seen: a 400-line diff became 1,100 and had to be rebuilt from git).
- Generated files are never edited by hand; change the generator or its input and regenerate.

---

## Part 2 — What each project's CLAUDE.md defines

If a project's file is missing one of these, ask rather than assume.
- **Gate**: the exact build, lint/analyze and test commands that must pass before "done", and how to drive the app in its real runtime.
- **Shared files** (never edited by parallel agents). Default when the project names none: dependency manifests and lockfiles, routing, config, app theme, localization strings, platform folders, generated code.
- **Stack and patterns**: state management, styling tokens, icon/asset pipeline, where app code lives and where commands run from.
- **Copy**: which spelling and locale user-facing text uses. Code comments and docs may stay as written.
- **Version naming**: derived at build time from the manifest version, the git short hash and the build type; never hardcoded in source. Commit before building, so the hash names the code that's in the build.
- **Targets**: performance (start-up, frame budget, memory, crash/ANR rate, download size) and where measurements and performance decisions are logged, each with its date and build.
- **Current focus**: what the owner wants worked on now. A performance or other observation outside it is written down (in the performance log or the report), not acted on.
- **Devices and environments**: emulators, test devices, tunnels, and which ones hold real user data.

---

## Part 3 — Engineering guidelines (any stack)

### UX and motion
- UX comes first, small motion included: anything that appears, leaves, changes color or changes value on screen moves there (fades, counts, shrinks, slides). No change drops an existing animation as a side effect; if keeping one costs something, ask rather than cut it. With the OS's reduce-motion setting on, it jumps straight to the end state.
- Anything that times something rather than moves it (a hold before closing, a countdown, a toast's lifetime) must not be tied to animation speed: with reduce-motion on, animation-driven timers can finish instantly or run at a fraction of their duration.
- A control tapped repeatedly must not move under the finger: a sheet or panel that steps through items (days, pages) keeps a fixed height, and its arrows sit at the top of their row, not centred on a title that wraps differently per item.
- Closing a modal, sheet or dialog hands focus back to whatever last had it, so a text field takes the keyboard again: drop focus before opening and after it returns.
- Colors read when a modal or route opens are frozen there; a light/dark switch while it's open repaints the text but not those colors. Read colors from the theme inside the modal's own build.
- Labels sharing a row equally get cut at large text sizes: measure the real labels at the current text scale and fall back to a wrapping layout.
- Hidden pages and tabs (kept alive, offscreen) are still read by screen readers unless excluded from the accessibility tree, and still run their animations and one-shot entrances unseen: gate those on the page actually being shown.
- Custom-drawn elements read by a screen reader need an explicit reading order; otherwise it reads them by position, not meaning.
- Text drawn standalone can shape differently from the same glyph inside its line (contextual alternates, kerning): draw it with its neighbours if it must match.

### Lists and state
- List frameworks reuse row state by position. Key every row, section and group header by what it stands for (an id), or when one drops out the next takes its state, and an animation in it runs from the old item's value. A row that reacts to an id must re-check when its id changes.
- A test that rows keep (or don't keep) state when the list shifts needs neighbours of the same widget shape: a row whose structure changes type is rebuilt anyway, and the test passes without the fix.
- A lazy list estimates the length of rows it hasn't built: tests that look for a row below the fold must scroll to it first, and full-length screenshots must grow and re-measure until nothing is left to scroll.

### Performance
- Measure only in a profile or release build on real hardware. Debug builds and emulators misrepresent speed; never report performance numbers from them.
- Count before you guess: a throwaway test can list what one interaction builds, lays out and paints, with no device. Find who triggers a relayout or repaint before fixing it.
- Frame budget: build + raster within 16 ms at 60 Hz; aim for 8 ms on 120 Hz screens.
- Anything longer than a screenful: lazy/virtualized lists. Never a concrete list of every child.
- Keep state updates at the lowest component that actually changes. Split large render functions into components, not helper functions. A subtree that doesn't change can be handed back as the same instance so the framework skips it; read callbacks at call time, not at build.
- Things that animate on their own (ripples, sliding digits) go on their own layer/repaint boundary, as small as the thing that animates.
- A box whose child changes size relays out everything up to the nearest fixed-size ancestor every frame: fix both dimensions when the box is full width anyway.
- Avoid hidden offscreen layers inside animations (group opacity, clips, shader masks, color filters); animate opacity on the element itself and pre-clip images.
- Animation builders and transition callbacks are stable function references, not closures recreated each render: each new closure can leave new listeners behind (seen: two leaked listeners per frame during a drag).
- Avoid intrinsic/measure-the-children layout passes in grids and lists; give cells fixed sizes.
- No heavy work on the UI thread: large JSON parsing, image processing, crypto, file loops go to a worker/isolate/background thread.
- Start-up: render the first frame before initializing analytics, ads, remote config, or other non-critical plugins.
- Memory is a budget: decode images at display size, never full resolution into a thumbnail; dispose controllers, streams, listeners and subscriptions.

### Network and data
- Show cached data immediately, refresh in the background. No blank screens waiting on the network.
- Every request has a timeout and an offline/error state.
- Every schema change ships as a migration with a test that upgrades from each older version. In SQLite, changing a column's CHECK needs a table rebuild (create, copy, drop, rename), and foreign keys are checked before the step commits.
- Something marked done "once" (a permission ask, an onboarding step) is marked when the platform confirms it happened, not when the request was sent: a second request made while another is up can be swallowed unseen.

### Dependencies
- Before proposing a package: confirm it's maintained, supports every target platform, and doesn't do heavy work at start-up. Ask before adding it.

### Devices, emulators and shared machines
- Other Claude sessions on the same host may drive the same emulator, device or browser: check with ListAgents and agree who has it, and screenshot before every tap that isn't the first on a known screen.
- A device that holds the owner's real data: look at the screen before typing, never type over what they entered, never press Save during automated taps.
- Before wiping app data (clearing storage, resetting a database), back it up and agree with any other agent using it. A build from another branch may have written a newer schema that this build refuses to open: check the version first.
- Anything that happens inside a short window (a toast's Undo): run the taps and captures as one chain on the device, not as separate host commands.
- Never `pkill -f` with a pattern that also appears in your own command line: it kills your own shell. Kill by PID.
- Start long-lived processes (emulators, servers) detached (`setsid`/`nohup`), or they die with the shell that started them. Run heavy integration test files one at a time on a small host.
- Dev tools with no auth (screen mirrors, debug servers) listen on 127.0.0.1 only and are reached over an SSH tunnel. Never expose them on another interface.
- A git worktree has no untracked fixtures (reference screenshots, local data), so tests that need them skip there and the total drops; the main checkout runs them.

---

## Part 4 — Platform notes

### Android
- Test release builds, not just debug: R8 runs only in release, and release-only crashes come from there. When a plugin breaks in release, add narrow keep rules for the specific classes only; never package-wide rules or `-keep public class *`, which silently disable optimization app-wide.
- Baseline Profiles target ART bytecode, not AOT-compiled code from cross-platform frameworks: skip them unless the app has substantial Kotlin/Java.
- Keep platform channel / bridge calls coarse: one call with batched data, not many small calls in a loop.
- A headless Linux emulator is for functional checks only (needs KVM; a host without a GPU renders in software and can crash on effects a phone draws fine).
- With more than one device or a tunneled adb server, pass `-s <serial>` on every command; an unpinned command can land on the wrong device. If a tunnel drops, adb silently starts its own local server on the tunnel's port: check the port before adb commands, and kill a stray server by PID.
- Version codes must not go down: different build modes (split per ABI vs universal) can produce different codes, and the device refuses the lower one as a downgrade. Don't force it.
- Switching signing keys means uninstalling, which wipes the user's data: never do that without asking.
- Play vitals: user-perceived ANR > 0.47% or crash > 1.09% overall reduces store visibility. Treat ANR-risk code (blocking the main thread) as a release blocker.

### iOS
- iOS builds, the simulator and signing require macOS + Xcode; they can't run on Linux. Say "iOS not verified" rather than implying it was tested.
- Test on a real iPhone before release; simulator performance is not representative.
