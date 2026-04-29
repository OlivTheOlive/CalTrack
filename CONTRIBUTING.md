# Contributing

This project uses branch naming conventions to drive automated versioning and releases.

## Branch naming

Create branches using one of these prefixes:

- `feature/<short-description>` or `feat/<short-description>`
- `fix/<short-description>`
- `bug/<short-description>`
- `chore/<short-description>`

Examples:

- `feature/add-meal-plans`
- `fix/crash-on-startup`
- `chore/update-deps`

## Versioning rules

The app version lives in `pubspec.yaml` as:

- `version: X.Y.Z+N`
  - `X.Y.Z` is the marketing version (SemVer-style)
  - `+N` is the build number

When a PR is merged into `main`, GitHub Actions will bump the version based on the PR's source branch name:

- `feat/` or `feature/`:
  - bump **minor**: `X.(Y+1).0`
- `fix/`, `bug/`, or `chore/`:
  - bump **patch**: `X.Y.(Z+1)`

The build number (`+N`) is set to the GitHub Actions run number for uniqueness.

After bumping, CI will tag the commit as `vX.Y.Z` and create a GitHub Release with the Android release APK attached.

## Pull requests and merges

- Open PRs targeting `main`.
- Keep one logical change per PR when possible.
- Recommended merge method: **Squash and merge** (keeps one PR = one version bump/release).

## Recommended repository settings

To keep versioning predictable, protect `main`:

- Require status checks to pass before merging (at minimum the `CI` workflow).
- Restrict direct pushes to `main` (so merges come from PRs and the workflow can read the PR branch name).

