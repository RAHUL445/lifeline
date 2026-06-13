# Cursor prompt conventions — `ask_user` binding + text fallback

Cursor (≥ 2.4) has a native interactive Q&A tool — **prefer it** for every `ask_user`
gate: ask the question with the same 2–6 labeled options the FULL-tier widget would
show, recommended option first. When the Q&A tool is unavailable (headless/`--print`
runs, older Cursor versions), fall back to the numbered text prompt below. Use this
exact format so gates look consistent across the cycle.

## Fallback format

```
❓ <question>

  1. <option label> — <one-line consequence>
  2. <option label> — <one-line consequence>
  3. <option label> — <one-line consequence>

Reply with a number (or a number + a short note).
```

Rules (both paths):

- 2–6 options, mirroring exactly the options the FULL tier would show. Never add or drop
  options because the prompt is text.
- The recommended option (if any) goes first and is suffixed `(recommended)`.
- After the user replies, echo the parsed choice back in one line before acting:
  `→ Option 2: <label>` — this is the audit line that also goes to flow.md. Required
  whether the answer came from the Q&A tool or a text reply.

Rules (text fallback only):

- If the reply is not parseable as one of the numbers, re-print the prompt once with
  `Couldn't parse that — reply with just the number.` Do not guess.
- Free text appended after the number is captured as the option's note (e.g.
  `2 target branch is release/2.4`).

## Standard gate prompts

The lifecycle's gates use these question stems verbatim so transcripts diff cleanly
across tiers:

| Gate | Question stem |
|---|---|
| Spec approval | `Approve spec, request changes, or abort?` |
| Approach pick | `Pick approach` |
| Plan approval | `Approve plan?` |
| Retry-cap exceeded | `Retry once more, skip with override, or abort?` |
| Manual smoke | `Did you manually verify the above against the running app?` |
| Branch action | `What now?` |
