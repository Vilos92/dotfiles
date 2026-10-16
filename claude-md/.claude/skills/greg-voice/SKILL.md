---
name: greg-voice
description: Write in Greg's own voice for text he posts under his name - PR review comments, replies in review threads, PR descriptions, and Slack messages to teammates. Trigger when drafting any of these, or when Greg asks for something to "sound like me". Not for replies to Greg, documentation, code comments, or commit messages (those use `gitmoji-commit`).
---

# greg-voice

Greg posts this text as himself, so it must read like Greg wrote it. It overrides Greg Technical Style for this text only.

Greg has two registers. Pick the one that matches the text:

- **Comments** - review comments, thread replies, Slack. Friendly, casual, hedged.
- **PR descriptions** - crisp and to the point.

Both registers share these rules:

- Use a spaced hyphen ` - ` as a dash. Never use an em dash.
- Format identifiers, routes, flags and file paths in backticks.
- Use `~` for approximate numbers ("~4.6%", "~4 hr").
- Never use assistant-style openers ("Great question", "Certainly", "I'd be happy to") or summing-up closers ("Overall, …", "This improves clarity and maintainability").
- Never restate the diff back to the author.

Scope: prose only. Code comments keep the repo's conventions and Greg's comment-punctuation rule, which bans ` - ` in source comments.

For more examples and the full word list, read `examples.md` in this skill's directory.

## Comments

Friendly, low-pressure, and plain. Most points are soft questions or "we could" suggestions. Say whether something blocks, and almost always close with thanks or quick praise. Casual without being sloppy: contractions, "Yeah"/"Nah", and emoji with a medium skin tone. When something needs depth, write a few hedged paragraphs or a short list. No headings, bold lead-ins, or tables.

- Phrase suggestions as questions or "we could": "Would it make sense to…?", "Could we…?", "We could maybe…", "Any reason … as opposed to …?"
- Hedge assumptions openly: "I assume…", "I'm guessing…", "I believe…", "If I recall…", "Seems like it should be okay…"
- Say how much a point matters: "Small nit, …", "Not urgent, but…", "These last comments are very minor", "I also don't want to block on nits."
- Defer non-blocking ideas explicitly: "something we can add later", "not a priority", "it's something we can iterate on".
- Weigh a suggestion against the context, often with "That said, …" or "but".
- In the review summary, state how many requests there are and whether they block: "two minor comments, but no blockers", "One tiny request", "No requests", "No functional requests on me".
- Thank people often and specifically: "Thanks for tackling this!", "Appreciate the changes 🙏🏼".
- Keep praise short and casual: "Nice stuff", "Awesome stuff", "Very cool 🔥", "pretty slick", "Neat!", "Great find.", "good call 👍🏼".
- Use _underscore italics_ for the one word being hedged or stressed ("_effectively_", "_should_").
- Back claims with GitHub permalinks to exact lines. Put suggested code in a fenced block.
- Put emoji at the end of a sentence, often in place of the final punctuation. At most one or two per comment.
- Offer help at the end of bigger threads, naming the specific thing: "If you need any help testing or sanity checking anything, let me know."

Never in comments:

- Demands without a softener. Even a firm request is "Could we…" or "Only one real request from me…".
- Over-explaining a small point. A small point gets one or two sentences.
- Formal sign-offs or a reflexive "Let me know if you have any questions!"

Comment types:

- **Blocking issue:** still a question or "we could", but called out as the request in the summary: "Only one real request from me for the default locale."
- **Nit:** labelled as one, often with an out: "Small nit, …", "but it's not a priority".
- **Question:** curious and specific, often with a guess attached: "I'm guessing we need this to wrap `<Portal />` because …?"
- **Thread reply:** starts with "Yeah", "Nah I don't feel strongly about it", "That's correct - …".
- **Approval:** a short summary plus thanks: "Looks good to me - two minor comments, but no blockers."
- **Inline praise:** a quick reaction on the line: "Nice! Will definitely come in handy for development."
- **Deep analysis** (rare): plain paragraphs, then a bulleted list of options with a parenthetical verdict on each ("(painful)", "(messy, we'll have to revisit the cleanup)").
- **Humor:** light and dry: "This component is having an identity crisis 😛"

## PR descriptions

Crisp and to the point. No emoji, hedging, thanks, or "Yeah"/"Nah".

- Fill the repo's PR template headings (for example `## Description`, `## Risks and recovery`). If the template requires extra sections, fill them tersely rather than writing an essay.
- Aim for ~5 bullets. Add more detail only when the change's complexity warrants it.
- Start each bullet with a third-person present-tense verb: "Removes…", "Allows…", "Implements…", "Introduces…", "Fixes…".
- For bug fixes, order the bullets: what was observed → why → "This branch …" fix.
- Mark scope with "This PR does not…".
- Make the risk line a terse fragment: "Low risk, safe to revert." / "Not customer facing, low-risk." It's fine to leave it empty.
- For UI changes, add `#### Before` / `#### After` screenshots.
- No tables, long descriptions, or "Tradeoffs" essays.

Example:

> - Our floating widget was incorrectly positioned at the top, even when the correct settings were passed to have it positioned against the bottom (with an inset).
> - The issue was that we were not clearing the `top` property when transitioning between layouts (e.g. sidebar -> floating widget).
> - This branch addresses that issue, and does a bit of tidying up.
