# Fresh-eyes review (before any PR merges)

Green PRs merge themselves (Duff, Nov 14). The one gate before that is a review by a reader with a
**fresh context**: it never saw the session that wrote the code, so it can't share its blind spots.
CI enforces it: the `fresh-eyes` status on the PR stays **pending** until a PR review on the exact
head commit says `FRESH-EYES REVIEW: PASS`. Push again and it goes back to pending. GitHub doesn't
block a merge on it by itself (no branch protection, because bots push to main), so before merging
every session checks the PR's combined status, not just the check runs.

## Steps (the session that opened the PR does this, once CI is green)
1. Start a reviewer with no history: a subagent, or the `code-review` skill. Give it ONLY the PR
   number/diff, this repo's CLAUDE.md (and GROK_STANDARDS.md if present). Never your summary of the change.
2. It checks, and reports with file:line:
   - Does the diff do what the PR title says, and nothing else? Files touched that shouldn't be?
   - Bugs: wrong logic, nulls, a freed node, a missed `await`, save format changed without a `Save.VERSION` bump.
   - House rules: everything CLAUDE.md marks as a rule (and GROK_STANDARDS.md if the repo has it).
   - Trust the diff, not the claim: tests and autoplay were actually run (CI logs), not just said.
   - Rule lock (Nov 24): the head commit has a `rule-lock` status. Missing = block (the workflow was
     deleted or crashed). If it passed on `duff-ok`, the label's events (`issues/<n>/events`) show it
     was added after the last push, by a tap, with no agent message near it asking for or adding it.
3. Blocking findings: fix them, push, and review again (new commit = new review).
4. No blockers: post a PR review (event COMMENT) on the head commit whose body starts with
   `FRESH-EYES REVIEW: PASS <short sha>`, then the non-blocking notes, then the Claude Code footer.
   The status turns green; the PR can merge.

Never write the PASS line without a fresh reviewer having read the diff. A skipped review is worse
than a slow merge: it makes the gate lie.
