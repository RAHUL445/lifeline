# 🪢 lifeline — the pitch

*"Your coding agent is brilliant, confident, and occasionally lying to your face. lifeline makes it show its work."*

---

## 🎬 The 30-second version (read this if you're busy and important)

AI agents ship code fast. They also ship code that *looks* done — green tests, confident
summary, "all set!" — while the real handler was mocked out and never actually ran.

**lifeline** wraps your coding agent (Claude Code, Cursor) in a gated dev lifecycle:
spec → plan → build → review → test → merge. Every gate produces a **real document a human
can read**, and nothing — no skipped step, no override, no coverage gap — happens off the
record.

It's the difference between "trust me bro" and a paper trail. 🪢

---

## 😤 The problem (for everyone who's been burned)

You ask an AI to build a feature. It does. The tests pass. You merge.

Three days later: production is on fire, and you discover the 152 passing tests were all
testing a mock of the thing that broke. The actual code path? Never executed. Not once.
The AI didn't lie, exactly. It just... didn't mention that part. 🔥

The agent is fast. The agent is tireless. The agent is also a junior dev with infinite
confidence and zero memory of what it did yesterday. Left alone it will:

- Skip the spec and "just start coding" (we've all met that person)
- Mock the hard parts and call it tested
- Make an architectural decision in a function name and tell no one
- Merge a planted secret because nothing was watching

**lifeline is the adult in the room.** Not to slow the agent down — to make it leave
evidence.

---

## 🎯 What it actually does

Six gated phases. Each one dispatches a *focused role* (spec-writer, architect, implementer,
reviewer, test-runner), that role hands back a structured result, and lifeline writes a
**durable artifact to disk before moving on**.

| Phase | What happens | What you get to read later |
|---|---|---|
| 📝 Spec | Intent → testable spec. Open questions surfaced, never guessed. | `spec.md` |
| 🗺️ Plan | 2–3 approaches, you pick one, work split into ordered waves. | `plan.md` |
| 🔨 Build | TDD per task. Independent tasks run in parallel. | `task.md` |
| 🔎 Review | Four lenses every time: logic, architecture, security, performance. | `review.md` |
| 🧪 Test | Coverage measured on *changed files*; every gap → a smoke-checklist line. | `test_result.md` |
| 🚀 Merge | Invariant check, override audit, smoke gate → two handoff docs. | `reviewer_doc.md`, `qa_doc.md` |

You approve at every gate. You can **override** any gate — overrides are legal! — but the
override gets logged and *resurfaces at merge*. No sneaking it past the bouncer. 🕵️

---

## 👔 For the senior manager (the "what's the ROI" section)

You care about risk, throughput, and not explaining an outage to *your* boss. lifeline gives you:

- **🛡️ Risk down, not velocity down.** The agent still moves fast. It just can't merge a
  black box anymore. Coverage gaps become a visible human checklist instead of a silent
  surprise in prod.
- **📋 Audit trail for free.** Every gate, retry, verdict, and override lands in an
  append-only log. When someone asks "why did we build it this way?" — there's a document.
  Compliance and incident reviews stop being archaeology.
- **🤝 Handoffs that actually hand off.** Merge produces a reviewer doc *and* a QA doc.
  Your reviewers stop reverse-engineering the diff; your QA stops guessing what to test.
  That's real hours back, every feature.
- **🔌 No lock-in, no rewrite.** It's a plugin. Runs on Claude Code and Cursor today, same
  behavior. `core/` is portable markdown — adding a new tool is one file, zero core changes.
  Your team's investment survives whatever AI tool wins next year.

**TL;DR:** same speed, far less "how did *this* reach production," and a paper trail you'll
be glad exists the one time you need it.

---

## 📊 For the product managers (the "does this help me ship" section)

- **🎯 Specs that are testable, not vibes.** Phase 1 turns "users want it faster" into a
  spec with explicit success criteria — and *surfaces the open questions instead of the
  agent quietly assuming an answer.* You catch the misunderstanding before code, not after.
- **🗺️ You see the tradeoffs.** Plan phase proposes 2–3 approaches with their costs. You're
  in the decision, not informed of it afterward.
- **✅ "Is it actually done?" has an answer.** The QA doc gives you feature flow, numbered
  test cases, and a smoke checklist in plain language. You can verify the thing works
  *without reading code*.
- **📈 Predictable, visible progress.** Cycle pauses at gates you approve. Close your laptop
  mid-feature; it cold-resumes from disk. No "where were we?" standup.

**TL;DR:** fewer "that's not what I asked for" rounds, and a clear blackbox answer to
"can we ship?"

---

## 🐣 For the juniors (the "will this make me look good / save my weekend" section)

- **🧙 The setup wizard does the thinking.** One command, sane defaults, hit enter a few
  times. lifeline even auto-detects *your project's own* lint and test commands — it won't
  impose some default it likes. Your tools, not its tools.
- **🎓 It's a senior dev pairing with you for free.** Four-lens review on every task —
  security holes, performance traps, architecture smells — caught before your actual senior
  dev sees the PR. You learn the patterns by watching it flag them.
- **🚫 It stops you committing the dumb thing.** Planted secret? Chunky diff? The pre-commit
  gate physically blocks it on Claude Code. Future-you, at 11pm, says thanks.
- **👻 Debug lane = no fixing ghosts.** Got a bug? `lifecycle debug "the thing breaks"`.
  It reproduces first, confirms with you, *then* fixes. You never again spend two hours
  fixing a bug that wasn't the bug.
- **💬 You don't even need to learn commands.** Just talk. "let's build a rate limiter"
  fires the spec discipline. "review this" fires the review. The slash command is there if
  you want the full gated ride.

**TL;DR:** looks like you suddenly got really disciplined. Our secret. 🤫

---

## 🧠 The one idea to remember

> **Passing tests are necessary, not sufficient.** Green ≠ proven. lifeline's whole
> personality is refusing to confuse the two — and leaving a document every step of the way
> so a human can check.

Your agent is the brilliant intern. lifeline is the process that turns brilliant-but-chaotic
into brilliant-and-accountable. 🪢

---

## 🚀 Try it (5 minutes, no commitment)

**Claude Code**
```
/plugin marketplace add RAHUL445/lifeline
/plugin install lifeline@lifeline
```

**Cursor** (≥ 2.5): Settings › Plugins › Add Marketplace › Import from Repo →
`RAHUL445/lifeline`, install **lifeline**.

Then just say *"let's build a rate limiter"* and watch it leave a paper trail.

Questions? → [Getting Started](docs/GETTING-STARTED.md) · [FAQ](docs/FAQ.md)

*Ship fast. Leave evidence.* 🪢
