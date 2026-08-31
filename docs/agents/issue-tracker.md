# Issue tracker: GitHub

Issues and PRDs live in GitHub Issues for `agisilaos/ColorKit`. Use the `gh` CLI for all operations. Run it inside this clone so it infers the repository from the git remote, or pass `--repo agisilaos/ColorKit` explicitly. For `gh api`, use `repos/agisilaos/ColorKit/...` endpoints.

## Conventions

- Create an issue: `gh issue create --title "..." --body-file <path>`.
- Read an issue: `gh issue view <number> --json number,title,body,labels,comments`.
- List issues: `gh issue list --state open --limit 100 --json number,title,body,labels,comments`, with appropriate label and state filters. Increase the limit or paginate via `gh api` when the queue exceeds it.
- Comment on an issue: `gh issue comment <number> --body-file <path>`.
- Apply or remove labels: `gh issue edit <number> --add-label "..." --remove-label "..."`.
- Close an issue: `gh issue close <number>`; post any resolution comment separately.

Write multiline issue bodies and comments to a temporary UTF-8 file and pass it with `--body-file`. Preserve real newlines and literal text. Follow the current task's authorization before publishing issues or comments.

## Pull requests as a triage surface

**PRs as a request surface: yes.**

External PRs use the same triage labels and states as issues. Exclude authors with `OWNER`, `MEMBER`, or `COLLABORATOR` association so collaborators' in-flight work stays out of this queue.

List external PRs with:

    gh api --paginate 'repos/agisilaos/ColorKit/pulls?state=open&per_page=100' \
      --jq '.[] | select(.author_association == "CONTRIBUTOR" or .author_association == "FIRST_TIME_CONTRIBUTOR" or .author_association == "FIRST_TIMER" or .author_association == "NONE") | {number,title,author: .user.login,author_association,labels: [.labels[].name]}'

Use the API for this filter: `gh pr list --json` does not expose author association in the installed CLI. Leave unknown association values for human review rather than guessing.

- Read a PR and its discussion: `gh pr view <number> --comments`.
- Read its labels and body: `gh pr view <number> --json number,title,body,labels,author`.
- Inspect its code: `gh pr diff <number>`.
- Comment: `gh pr comment <number> --body-file <path>`.
- Apply or remove labels: `gh pr edit <number> --add-label "..." --remove-label "..."`.
- Close: `gh pr close <number>`.

Issues and PRs share a number space. For an ambiguous `#<number>`, read `gh api repos/agisilaos/ColorKit/issues/<number>`; the presence of `pull_request` identifies a PR. Surface authentication or network errors instead of interpreting them as an issue type.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Resolve whether the number is an issue or PR, then read its body, labels, and discussion using the commands above.

## Wayfinding operations

Used by `/wayfinder`. The map is one GitHub issue with child issues as tickets.

- Map: label the map issue `wayfinder:map`; its body holds Notes, Decisions-so-far, and Fog.
- Child ticket: link it to the map using GitHub sub-issues through `gh api`. If sub-issues are unavailable, add it to the map's task list and put `Part of #<map>` at the top of its body. Use `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, or `wayfinder:task` as appropriate. Create these labels when needed; they are separate from the five triage labels.
- Blocking: use native GitHub issue dependencies. Add a dependency with `gh api --method POST repos/agisilaos/ColorKit/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-database-id>`. Fetch the database ID using `gh api repos/agisilaos/ColorKit/issues/<blocker-number> --jq .id`; do not use the issue number or node ID. If dependencies are unavailable, use a `Blocked by: #<number>, #<number>` line in the child body. A ticket is unblocked when all blockers are closed.
- Frontier: inspect the map's open children in map order. Skip assigned tickets and those with open blockers (`issue_dependencies_summary.blocked_by > 0`, or open issues named in the fallback line). The first remaining child is next.
- Claim: `gh issue edit <number> --add-assignee @me` is the wayfinding session's first write.
- Resolve: post the answer with `gh issue comment <number> --body-file <path>`, close the child issue, and append a concise finding and link to the map's Decisions-so-far.
