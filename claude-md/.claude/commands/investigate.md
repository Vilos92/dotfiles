---
description: Read-only review of GitHub PR comments on the current branch
---

Do a READ-ONLY review of the feedback on this branch's GitHub pull request.

Hard rules for this task:
- Do NOT edit, create, or delete any files.
- Do NOT commit, stash, checkout, or push.
- Do NOT post, reply to, react to, or resolve anything on GitHub. No `gh pr comment`, `gh pr review`, or `gh api` calls with POST/PATCH/PUT/DELETE.
- Only run read commands. Your only output is a report to me.

Steps:

1. Find the PR for the current branch:
   `gh pr view --json number,url,title,headRefName,baseRefName`
   If there's no PR, tell me and stop.

2. Pull all feedback:
   - Top-level comments and review summaries: `gh pr view --json comments,reviews`
   - Inline review comments: `gh api --paginate "repos/{owner}/{repo}/pulls/<NUMBER>/comments"`
   - Thread resolution state: use `gh api graphql` to fetch `reviewThreads { isResolved isOutdated comments { body path line author { login } } }`

3. For each comment, investigate the code it refers to in the current checkout. Read the file, trace usages, and check related tests. Then classify it as one of:
   - **Valid**: the concern is correct and should be addressed
   - **Partially valid**: has merit but is overstated or needs nuance
   - **Not valid**: incorrect, already handled, or no longer applies
   - **Needs discussion**: a judgment call or design preference

4. Report back. For each comment, include:
   - Author, `file:line`, and a one-line summary of what they said
   - Verdict and reasoning, backed by specific code references
   - Suggested fix or reply, described in words only (don't apply it)
   - Whether the thread is resolved or outdated

   Skip bot noise (CI status, coverage bots) unless it flags a real issue.

   End with a short prioritized list of what's actually worth acting on.
