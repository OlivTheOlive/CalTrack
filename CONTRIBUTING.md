# Contributing

This project uses branch naming conventions to drive automated versioning and releases.
The sections below are ordered the way a change travels: pick one logical goal, name the
branch for it, build it, open the PR, let CI cut the release.

## 1. One branch = one logical goal

Every branch (and its PR) must contain a **single logical goal**. A logical goal is one
sentence without an "and" in it:

- **One goal:** "Fix the nutrition calculation when a custom food has no serving size."
- **Mixed goals:** "Fix the nutrition calculation and add macronutrient charts and bump the
  charting package."

The reason is mechanical, not stylistic:

- The **branch prefix decides the version bump** (see §3). A branch that mixes a new
  feature with a bug fix has to pick one prefix, so either the feature ships in a patch
  release or a fix triggers a minor one.
- PRs are **squash-merged**, so the branch collapses into one commit. A mixed branch
  becomes one commit (and one release note) describing two unrelated things.
- One goal per branch means a goal can be **reverted on its own** — `git revert <squash
  commit>` undoes exactly that change and nothing else.

Practical test before you open a PR: can you state the branch's goal as a single PR title,
and does that title still describe every file in the diff?

### What belongs in the branch

- The change itself.
- The tests for that change.
- Documentation the change invalidates (`README.md`, `doc/Feature.md` checkmarks).
- Mechanical formatting *of the files you actually touched* (for example `dart format`).

### What does not

- Drive-by refactors, renames, or whitespace churn in unrelated files.
- Dependency bumps (`pubspec.yaml`) that are not required by the goal.
- "While I'm here" fixes for other bugs. Fix those on their own branch.
- A second feature you just thought of.

### When a second goal shows up mid-branch

Don't fold it in. Pick one:

- **Finish and merge the current branch**, then branch again from `main` for the new goal.
- **Branch off the current branch** if the second goal genuinely depends on the first
  (`fix/nutrition-totals` → `fix/nutrition-totals-export`), and open its PR against the
  first branch. Land them in order.
- **Stash it** as an issue so it isn't lost.

## 2. Branch naming

Format: `<type>/<short-description>`

| Type | Use for | Version bump |
| --- | --- | --- |
| `feat/<description>` or `feature/<description>` | New user-visible capability | **minor** (`X.(Y+1).0`) |
| `fix/<description>` | Correction to existing behaviour | patch (`X.Y.(Z+1)`) |
| `bug/<description>` | Same as `fix/`, when you want to flag it as a reported defect | patch |
| `chore/<description>` | Tooling, CI, deps, docs, housekeeping | patch |
| `release/vX.Y.Z` | **Created by CI only** — see §5. Never make one by hand. | — |

Description rules:

- Lowercase, hyphen-separated, ASCII: no spaces, `&`, `.`, or slashes.
  (`feat/future&edit` is not a valid example — write `feat/future-and-edit`.)
- Describe the goal, not the files: `fix/fixing-nutrition-calculation`, not
  `fix/db-dart-edit`.
- Keep it short enough to read in a `git log --oneline` line, specific enough that it
  isn't reusable: `chore/update-deps` tells nobody anything,
  `chore/refresh-opennutrition-catalog` does.
- One description per branch. If you need an "and", you need two branches.

Examples:

- `feat/add-meal-plans`
- `feat/barcode-scan-fallback`
- `fix/fixing-nutrition-calculation`
- `bug/app-fails-to-update`
- `chore/update-contribution`

## 3. Versioning rules

The app version lives in `pubspec.yaml` as:

- `version: X.Y.Z+N`
  - `X.Y.Z` is the marketing version (SemVer-style)
  - `+N` is the build number

When a PR is merged into `main`, GitHub Actions reads the **merged PR's source branch name**
and bumps the version with `tool/bump_version.py`:

- `feat/`, `feature/` → **minor**: `X.(Y+1).0`
- `fix/`, `bug/`, `chore/` → **patch**: `X.Y.(Z+1)`
- Anything else → **patch** (the fallback, not a licence to name branches arbitrarily)

The build number (`+N`) is set to the GitHub Actions run number for uniqueness.

Never edit the version line by hand in a feature branch: the bump is generated, and a PR
that only changes `pubspec.yaml` does not trigger the prepare workflow at all.

## 4. Building and verifying

Run these locally before opening a PR — the same commands CI runs:

```bash
flutter pub get
flutter analyze
flutter test
```

For changes that touch Android configuration, plugins, or native code, also build once:

```bash
flutter build apk --debug
```

## 5. Pull requests and merges

- Open PRs targeting `main`.
- Keep one logical change per PR (see §1) — the PR title is what becomes the squash commit,
  so make it read like the change: `fix: correcting nutrition calculation for custom foods`.
- Rebase or merge `main` into your branch so the squash applies cleanly and CI runs on
  current code.
- Recommended merge method: **Squash and merge** (keeps one PR = one version bump/release).
- Delete the branch after merging; leftover branches clutter `git branch -a`.
- **Never hand-create or hand-merge a `release/*` branch.** Merging one is what publishes a
  release and pushes a tag.

### What CI does after you merge

1. `Release (Android) — version bump PR` (`release-android-prepare.yml`) bumps the version
   and opens a PR from `release/vX.Y.Z` titled `chore(release): vX.Y.Z`.
2. `Release (Android) — tag, APK, GitHub Release` (`release-android-publish.yml`) runs when
   *that* PR is merged: it tags the commit `vX.Y.Z`, builds the release APK, and creates a
   GitHub Release with the APK attached.

So: your PR merges the change, and a second, automated PR promotes it to a release.

## 6. Recommended repository settings

To keep versioning predictable, protect `main`:

- Require status checks to pass before merging (at minimum the `CI` workflow).
- Restrict direct pushes to `main` (so merges come from PRs and the workflow can read the PR
  branch name).
- Require linear history if you want the PR-to-commit relationship to stay one-to-one.
