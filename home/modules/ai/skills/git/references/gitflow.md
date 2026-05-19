# Git Flow Reference

Git flow is a branching model and a CLI tool that formalizes it. This machine has
**git-flow AVH Edition 1.12.3** installed at `/usr/bin/git-flow`.

---

## The Branching Model

Designed by Vincent Driessen (2010) for versioned software with discrete release cycles.

> **When to use git-flow:** Versioned software (libraries, apps with separate releases
> for v1, v2, etc.). Multiple versions in production simultaneously. Teams that do
> scheduled releases rather than continuous deployment.
>
> **When NOT to use git-flow:** Continuous delivery / deploy-on-merge web apps.
> For those, simpler workflows (GitHub Flow: main + feature branches) are better.

### Two Permanent Branches

| Branch | Purpose | Rule |
| --- | --- | --- |
| `main` (or `master`) | Production-ready code | Every commit here = a release |
| `develop` | Integration branch | Latest delivered development changes |

### Supporting Branches (Temporary)

| Type | Branch from | Merge back to | Naming |
| --- | --- | --- | --- |
| Feature | `develop` | `develop` | `feature/*` |
| Bugfix | `develop` | `develop` | `bugfix/*` |
| Release | `develop` | `main` + `develop` | `release/*` |
| Hotfix | `main` | `main` + `develop` | `hotfix/*` |
| Support | `main` (old tag) | — | `support/*` |

---

## Initializing Git Flow

```bash
git flow init                           # interactive setup with prompts
git flow init -d                        # use all defaults (recommended for new repos)

# git flow init asks for:
# Branch name for production releases: [master]
# Branch name for "next release" development: [develop]
# Feature branches prefix: [feature/]
# Bugfix branches prefix: [bugfix/]
# Release branches prefix: [release/]
# Hotfix branches prefix: [hotfix/]
# Support branches prefix: [support/]
# Version tag prefix: []
```

After init, your repo will have `main` (or `master`) and `develop` branches.
All development work starts from `develop`.

---

## Feature Branches

Features are developed in isolation from `develop`. They should never interact
directly with `main`.

```bash
# Start a feature
git flow feature start <name>
# = git switch -c feature/<name> develop

# List features
git flow feature list

# Finish a feature (merges --no-ff into develop, deletes branch)
git flow feature finish <name>
# = git merge --no-ff feature/<name> into develop
# + deletes feature/<name> locally

# Share a feature with teammates
git flow feature publish <name>         # push feature/<name> to origin

# Pull a colleague's published feature
git flow feature track <name>           # checkout + track origin/feature/<name>

# Pull latest changes into your feature from origin
git flow feature pull origin <name>

# Delete a feature branch without finishing it
git flow feature delete <name>          # local only
git flow feature delete -r <name>       # local + remote
```

**Feature workflow example:**

```bash
git flow feature start user-auth
# ... develop, commit multiple times ...
git commit -m "feat(auth): add JWT middleware"
git commit -m "feat(auth): add refresh token endpoint"

# Share for code review
git flow feature publish user-auth
# (teammate reviews on GitHub/GitLab)

# Merge after approval
git flow feature finish user-auth
git push origin develop
```

---

## Bugfix Branches

Bugfix branches (AVH addition, not in original gitflow) behave like features but
are intended for bug fixes targeting the next release, not new functionality.

```bash
git flow bugfix start <name>            # branch from develop
git flow bugfix finish <name>           # merge back to develop
git flow bugfix publish <name>
git flow bugfix track <name>
git flow bugfix delete <name>
```

---

## Release Branches

A release branch is created when `develop` is ready for a release. During the
release branch lifetime, only bug fixes, documentation, and release prep go in —
no new features.

```bash
# Start a release
git flow release start 2.0.0
# = git switch -c release/2.0.0 develop

# Share the release branch (so others can contribute release fixes)
git flow release publish 2.0.0

# Finish a release
git flow release finish 2.0.0
# = merges release/2.0.0 --no-ff → main
# + tags main with "2.0.0"
# + merges release/2.0.0 --no-ff → develop  (back-merge, critical!)
# + deletes release/2.0.0

git push origin main develop --tags    # push everything after finish
```

**Why the back-merge to develop matters:** Any bug fixes applied during the release
prep need to be included in `develop` so they're in the next release too. Forgetting
this is a common git-flow mistake.

**Release workflow example:**

```bash
# Develop is ready for v2.0.0
git flow release start 2.0.0

# Bump version number
echo "2.0.0" > VERSION && git commit -am "chore: bump to 2.0.0"

# Fix last-minute bugs found during QA
git commit -m "fix: edge case in payment flow"

# Ship it
git flow release finish 2.0.0
git push origin main develop --tags
```

---

## Hotfix Branches

Hotfixes address critical production bugs that can't wait for the next release cycle.
They branch from `main` (the production state) and merge back to both `main` AND
`develop`.

```bash
# Start a hotfix (branches from main)
git flow hotfix start 2.0.1
# = git switch -c hotfix/2.0.1 main

# Fix the bug, commit
git commit -m "fix: null crash in session handler"

# Finish the hotfix
git flow hotfix finish 2.0.1
# = merges hotfix/2.0.1 --no-ff → main
# + tags main with "2.0.1"
# + merges hotfix/2.0.1 --no-ff → develop  (or current release branch if one exists)
# + deletes hotfix/2.0.1

git push origin main develop --tags
```

> If a release branch currently exists (e.g., `release/2.1.0`), git-flow will
> merge the hotfix into the release branch instead of develop. The release branch
> will eventually carry the fix into develop when it finishes.

---

## Support Branches

Long-lived maintenance branches for supporting old major versions. Branches from
a specific tag on `main`.

```bash
git flow support start 1.x v1.5.0       # create support/1.x from the v1.5.0 tag
git flow support list
# Support branches do NOT have a finish command — they're permanent
```

Use support branches when you need to maintain v1.x while developing v2.x on develop.

---

## Configuration & Info

```bash
git flow config                         # show current git-flow config
git flow config set feature.start my-hook-script   # set a hook
git flow version                        # show git-flow version (1.12.3 AVH)
git flow log                            # show git log for commits deviating from base branch
```

Git flow stores its config in `.git/config`:

```ini
[gitflow "branch"]
    master = main
    develop = develop
[gitflow "prefix"]
    feature = feature/
    bugfix = bugfix/
    release = release/
    hotfix = hotfix/
    support = support/
    versiontag =
```

---

## Complete Cycle Example: Feature → Release → Hotfix

```bash
# Day 1: start feature work
git flow feature start user-dashboard
git commit -m "feat: add user dashboard skeleton"
git commit -m "feat: add dashboard metrics"
git flow feature finish user-dashboard
git push origin develop

# Day 15: ready to ship v1.3.0
git flow release start 1.3.0
echo "1.3.0" > VERSION && git commit -am "chore: bump to 1.3.0"
git commit -m "docs: update changelog"
git flow release finish 1.3.0           # tags v1.3.0, merges to main + develop
git push origin main develop --tags

# Day 17: critical bug found in production
git flow hotfix start 1.3.1
git commit -m "fix: division by zero in metrics calc"
git flow hotfix finish 1.3.1            # tags v1.3.1, merges to main + develop
git push origin main develop --tags
```

---

## Common git-flow Mistakes

| Mistake | Fix |
| --- | --- |
| Forgot to back-merge release into develop | `git switch develop && git merge --no-ff release/x.y.z` |
| Pushed to main directly | Revert on main, apply to develop properly |
| Feature branch too long-lived (many conflicts) | Rebase feature onto develop regularly: `git rebase develop` |
| Release branch has new features | Move them to develop; release branches are for stabilization only |
| Hotfix merged to develop but not main | `git switch main && git merge --no-ff hotfix/x.y.z && git tag -a vX.Y.Z` |
