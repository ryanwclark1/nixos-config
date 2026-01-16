---
description: Prep a branch, commit, and open a draft PR
argument-hint: [FILES=<paths>] [PR_TITLE="<title>"] [BRANCH="<branch-name>"]
---

Create a branch named `dev/$BRANCH` for this work (or use a descriptive name based on the changes if $BRANCH is not provided).

If files are specified, stage them first: $FILES.

Commit the staged changes with a clear, descriptive message that explains what was changed and why.

Open a draft PR on the same branch. Use $PR_TITLE when supplied, otherwise generate a descriptive title from the commit message.

Include a PR description that summarizes the changes, any breaking changes, and testing instructions.


