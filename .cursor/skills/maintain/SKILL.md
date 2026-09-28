---
name: maintain
description: >-
  Updates this Homebrew fork. Use when the user asks to update brew, update
  the overlay, update packages, sync formulae, rebase patches, or says
  "обнови brew", "обнови overlay", "обнови всё", "update brew",
  "update overlay", "update all". Task brew rebases patches onto the latest
  Homebrew/brew tag so the next brew update picks it up. Task overlay
  refreshes Formula/*.rb from homebrew-core while keeping local patches.
  "all" runs brew, then overlay.
---

# Maintain brew-self

Repo root is the checkout that contains `./update-and-patch`, `patches/`, and `Formula/`.
`brew/` is a gitignored full-history checkout of Homebrew/brew. Do not commit
or push unless the user asks.

Write the report in the user's language.

## Which task

| User asks | Run |
|---|---|
| brew only | Brew |
| overlay / packages / formulae only | Overlay |
| all, both, or no task named | Brew, then Overlay |

If Brew stops to ask the user, do not start Overlay.

## When to stop and ask

Stop as soon as the next step needs a choice or a fact you do not have.
Report what already changed, what blocked, and the exact question.
Do not guess past these:

- A patch's target was removed or redesigned, and more than one change would preserve its behavior.
- A local formula hunk no longer maps onto the upstream formula.
- The formula is missing from homebrew-core.
- formulae.brew.sh or GitHub is unreachable, the checksum does not match, or auth/git fails. Do not invent the file. Ask the user to set up access.
- A fix would change user-visible behavior beyond "make the existing patch apply on the new upstream".

## Brew

Goal: `./update-and-patch` leaves `brew/` at the latest `X.Y.Z` tag from
https://github.com/Homebrew/brew plus every `patches/*.patch`, with that tag
moved onto the patched commit. The user's `brew update` follows
`HOMEBREW_BREW_GIT_REMOTE` and picks this up. Do not run the user's
`brew update`.

1. Read `./update-and-patch` and the patch blurbs in `README.md` before editing anything.
2. Run `./update-and-patch`. It fetches the latest `X.Y.Z` tag, resets `brew` main onto
   that commit, applies `patches/*.patch` in version order, commits each one
   inside `brew/`, and force-moves the tag.
3. If it prints `brew is already <version> plus patches`, this task is done.
4. If `git apply` fails, the patch files in `patches/` are the source of truth,
   not the half-applied `brew/` worktree. Fix the failing patch so the hunk
   matches current upstream and the behavior in the README blurb still holds.
   Re-run `./update-and-patch`. A later run checks out the upstream commit again, so a
   failed mid-apply is discarded.
5. After a successful apply on a new tag, read each hunk in the patched tree.
   Confirm the flag, branch, or message still does what the patch is for.
   Context can apply onto the wrong block. If the behavior drifted, fix the
   patch file and re-run `./update-and-patch`.
6. Durable repo edits are under `patches/`. Commits inside `brew/` stay local.

## Overlay

Goal: each overlay formula matches the formula brew would use, plus this
repo's local hunks. Keep upstream bottles and every other upstream stanza.
`Formula/patches/<name>.patch` is those hunks. A formula with no patch
there is local-only and stays as written.

Upstream is two records that name the same file:

- `https://formulae.brew.sh/api/formula/<name>.json` is what `brew update`
  fetches. It names `tap_git_head`, `ruby_source_path`, and
  `ruby_source_checksum`. It does not contain the Ruby.
- The Ruby is `https://raw.githubusercontent.com/Homebrew/homebrew-core/<tap_git_head>/<ruby_source_path>`.
  `brew` downloads that exact URL when it needs the formula source, and
  checks `ruby_source_checksum`.

GitHub `main` can be ahead of `tap_git_head`. A local homebrew-core checkout
can be stale or hand-edited. `brew cat` and `brew info` follow
`HOMEBREW_FORMULA_OVERLAY` and show our file. None of those are upstream.

If formulae.brew.sh or GitHub does not answer, or the downloaded bytes do
not match `ruby_source_checksum`, stop the overlay task. Do not reconstruct
the formula, do not use GitHub `main`, and do not copy a local checkout.
Tell the user which host failed and ask them to set up access. Do not
continue with the remaining formulae.

`Formula/<name>.rb` is what Homebrew loads. `Formula/patches/<name>.patch`
applied to the upstream Ruby produces that file. `patch -R` on
`Formula/<name>.rb` restores the upstream Ruby. The overlay loader only
opens `Formula/<name>.rb`, so the patch directory is not formulae.

A formula with no `Formula/patches/<name>.patch` is ours alone. Skip it.
Do not download it and do not create a patch.

For each formula that has `Formula/patches/<name>.patch`:

1. Download the JSON, then the Ruby at `tap_git_head`, and verify the
   checksum. A 404 means it is missing: stop and ask. Any other fetch or
   checksum failure: stop and ask the user to set up access.
2. Reverse-apply the patch to a copy of `Formula/<name>.rb`. That result
   is the upstream this overlay was built from. If it matches the download,
   skip.
3. Apply the patch to the download. If it applies cleanly, write the result
   to `Formula/<name>.rb` and regenerate `Formula/patches/<name>.patch` with
   `diff -u` from the download to that result, labeled `upstream/<name>.rb`
   and `Formula/<name>.rb`. Bottles and every other upstream stanza stay,
   except lines the patch itself changes.
4. If either apply fails, stop that formula and ask. Leave both files
   unchanged. Do not merge by hand and do not continue by guessing.

## Report

Keep it short:

- Brew: previous state, new tag or "already current", patch files edited.
- Overlay: per formula, local-only / skipped / updated.
- Anything left uncommitted.
- The question, if you stopped.
