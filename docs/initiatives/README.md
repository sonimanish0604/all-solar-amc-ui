# Initiative Docs

Place new initiative briefs in this folder.

Recommended pattern:
- one folder per initiative
- keep the original brief and a working breakdown together

Suggested structure:

```text
docs/
  initiatives/
    README.md
    TEMPLATE.md
    <initiative-name>/
      brief.md
      issue-breakdown.md
```

How to use this folder:
- put the raw initiative document in `brief.md`
- use `issue-breakdown.md` to turn the brief into epics, stories, and tasks
- once issues are created, add issue links back into `issue-breakdown.md`

If the initiative is still early and no branch exists yet, that is fine.
This folder is meant for pre-implementation planning as well as execution context.
