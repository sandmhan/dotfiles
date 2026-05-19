# History, Debugging & Search Reference

---

## Advanced `git log`

```bash
# ── Filtering ──────────────────────────────────────────────────────────────
git log --author="Alison"
git log --author="@aquinas\.pro"        # regex match
git log --since="2025-01-01" --until="2025-03-01"
git log --since="2 weeks ago"
git log --grep="fix: null"              # search commit message text
git log --grep="PROJ-123" --extended-regexp

# Follow file history across renames
git log --follow -- path/to/file.ts

# Show commits between refs
git log main..feature/auth             # commits in feature not yet in main
git log feature/auth..main             # commits in main not yet in feature
git log main...feature/auth            # symmetric difference (unique to either side)

# Content search (the "pickaxe")
git log -S "secretFunction"            # commits that added/removed this exact string
git log -G "secret.*function"          # commits where diff matches this regex
git log --all -S "password"            # search across all branches

# ── Output formats ─────────────────────────────────────────────────────────
git log --oneline --graph --all        # visual compact branch graph
git log -p                             # full patch per commit
git log -p --stat                      # patch + file summary
git log --stat                         # files changed per commit (no patch)
git log --shortstat                    # files changed + insertions/deletions summary
git log --name-only                    # just list changed file names
git log --name-status                  # file names + M/A/D status

# ── Custom formatting ──────────────────────────────────────────────────────
git log --format="%h %an %ar %s"       # hash, author, relative date, subject
git log --format="%C(yellow)%h%Creset %s %C(blue)(%ar) %C(green)%an%Creset"
git log --pretty=fuller                # full author + committer with dates

# ── GPG verification ──────────────────────────────────────────────────────
git log --show-signature               # show GPG sig status for each commit
git log --format="%h %G? %GS %s"       # %G? = sig status, %GS = signer
# Sig status: G=good, B=bad, U=unknown, E=missing, N=no sig
```

---

## `git blame`

Shows which commit last modified each line of a file. Invaluable for understanding
why code was written a certain way.

```bash
git blame <file>                        # full blame output
git blame -L 50,100 <file>              # specific line range
git blame -L "/function login/",+20 <file>  # from regex match, next 20 lines
git blame -w <file>                     # ignore whitespace changes
git blame -M <file>                     # detect moved/copied lines within file
git blame -C <file>                     # detect lines copied from other files in commit
git blame <sha> -- <file>               # blame at a specific commit

# Ignore specific commits (e.g., large reformatting commits)
git blame --ignore-rev <sha> <file>
git blame --ignore-revs-file .git-blame-ignore-revs <file>

# Typical .git-blame-ignore-revs content:
# <sha-of-formatting-commit>
# <sha-of-whitespace-fix>
```

---

## `git bisect` — Binary Search for Regressions

`bisect` finds the exact commit that introduced a bug using binary search. Instead
of manually checking commits, git picks the midpoint each time.

```bash
# Start a bisect session
git bisect start
git bisect bad                          # current commit is broken
git bisect good v1.2.0                  # this tag/commit was working

# Git checks out the midpoint commit. Test it, then mark:
git bisect good                         # midpoint is good (bug is in newer half)
git bisect bad                          # midpoint is bad (bug is in older half)
# Repeat until git identifies the first bad commit

# When done:
git bisect reset                        # return to original branch/commit

# Skip a commit if you can't test it (e.g., won't build)
git bisect skip <sha>
```

### Automated Bisect

When you have a test script that exits 0 for good and non-zero for bad:

```bash
git bisect start
git bisect bad HEAD
git bisect good v1.2.0
git bisect run npm test                 # automate: run this after each step

# Or a custom script:
git bisect run sh -c "node check.js"
git bisect run python -c "import sys; sys.exit(0 if check() else 1)"
```

### Bisect Tips

- Use `git bisect log` to see your session history
- Use `git bisect replay <logfile>` to replay a session
- The `--term-good` / `--term-bad` flags let you rename the states (e.g., `fast`/`slow` for performance regressions)

---

## `git grep` — Search Working Tree or History

Faster than filesystem grep on large repos (respects .gitignore, uses index).

```bash
git grep "console.log"                  # search all tracked files
git grep -n "console.log"               # with line numbers
git grep -l "console.log"               # file names only
git grep -c "console.log"               # count per file
git grep -i "todo"                      # case insensitive
git grep -w "log"                       # whole word match
git grep "pattern" -- "*.ts"            # limit to TypeScript files
git grep -e "foo" --and -e "bar"        # both patterns must match in same line

# Search a specific branch or commit
git grep "secretKey" main
git grep "apiKey" HEAD~5

# Search across all refs
git grep "password" $(git rev-list --all)  # can be slow on large repos
```

---

## `git describe` — Human-Readable Version Names

```bash
git describe                            # describe HEAD relative to nearest tag
# Output: v1.2.0-14-gabcdef7
# = tag v1.2.0, 14 commits ahead, at commit abcdef7

git describe --tags                     # use lightweight tags too
git describe --always                   # always output something (use SHA if no tags)
git describe --abbrev=8                 # longer SHA abbreviation
git describe --long                     # always include commit count even if exact tag
git describe <sha>                      # describe a specific commit
```

Use `git describe` in build scripts to generate version strings that encode exactly
which commit you're on relative to a release tag.

---

## `git reflog` — Recovery Log

Reflog records every time HEAD or branch tips moved — even after resets, rebases,
and abandoned merges. Think of it as your safety net.

```bash
git reflog                              # show HEAD reflog (last 90 days by default)
git reflog show <branch>                # reflog for a specific branch
git reflog show --all                   # all refs
git reflog --date=iso                   # show timestamps
git reflog -n 20                        # limit output

# Output format:
# abc1234 HEAD@{0}: commit: feat: add login
# def5678 HEAD@{1}: rebase finished: ...
# ghi9012 HEAD@{2}: checkout: moving from main to feature/auth
```

**Common recovery patterns using reflog:**

```bash
# Recover commits after accidental reset --hard
git reflog
git reset --hard HEAD@{3}               # go back 3 moves

# Recover a deleted branch
git reflog                              # find the tip SHA of the deleted branch
git switch -c recovered-branch <sha>    # recreate the branch

# Undo an accidental rebase
git reflog | grep "rebase finished"
git reset --hard HEAD@{N}               # N = position before rebase started
```

See `references/undoing.md` for full recovery patterns.

---

## `git shortlog` — Contributor Summary

```bash
git shortlog                            # group commits by author
git shortlog -sn                        # count only, sorted numerically
git shortlog -sn --all                  # across all branches
git shortlog -sn since="3 months ago"
git shortlog main...feature             # changes unique to each side
```

Useful for release notes, contribution stats, and reviewing who owns what.
