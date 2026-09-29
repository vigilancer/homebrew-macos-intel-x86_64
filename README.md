# What, Why and for Whom

A patched Homebrew, with a few features that upstream does not have. Mostly relevant to devices running macOS on Intel CPUs.

See the list of patches below to decide if it is of any use to you.

## how to start using homebrew-macos-intel-x86_64 TODAY!

1. clone this repo

```sh
mkdir -p ~/brew-self
git clone https://github.com/vigilancer/homebrew-macos-intel-x86_64.git ~/brew-self
```

2. remove patches you don't need (if any)

```sh
cd ~/brew-self
rm patches/0001-unsupported-os-silent.patch
rm patches/0002-build-from-source.patch
rm patches/0003-formula-overlay.patch
rm patches/0004-odeprecated-silent.patch
rm patches/0005-info-installed-dependents.patch
rm patches/0006-info-recursive-runtime-names.patch
rm patches/0007-info-verbose.patch
rm patches/0009-manual-fetch-command.patch
```

3. brew your own

   this will fetch the latest `brew` release with full history into `.bare` and check `brew` out as a worktree of the latest version tag, then apply patches to it. If `.bare` is already there and the fetch fails, it warns and continues with the tags it has.

   brew? brew! ah, brew...

```sh
./update-and-patch
```

4. point the installed Homebrew at this checkout

   `./enable` writes `HOMEBREW_BREW_GIT_REMOTE` in `~/.homebrew/brew.env`
   (uncommenting it if it was commented, replacing it if it was already set)
   and points the install's `origin` at this checkout. It does not apply patches
   and does not update the installed Homebrew. After that, `brew update-reset`
   fetches from the patched repo.

```sh
./enable
```

   `./disable` comments that line out and resets the install onto the latest official tag already stored in `.bare`.

```sh
./disable
```

   The other switches still go in `brew.env` yourself:

```sh
HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1           # patch 0001
HOMEBREW_BUILD_FROM_SOURCES_YOU_PHILISTINE=1      # patch 0002
HOMEBREW_FORMULA_OVERLAY=$HOME/brew-self/Formula  # patch 0003
HOMEBREW_ODEPRECATED_AND_I_DONT_CARE=1           # patch 0004
HOMEBREW_INFO_VERBOSE=1                           # patch 0007
HOMEBREW_FETCH_PRINT_COMMAND=1                    # patch 0009
```

   `0005` and `0006` have no switch. They apply as long as the patch is installed.

5. pick up a newer patched tag

   `./update-and-patch` only moves the checkout in this repo.
   `brew update-reset` fetches that checkout into the installed Homebrew and checks out the moved tag.
   Use it instead of `brew update`. Each run rewrites history, and `brew update` tries to rebase.

```sh
./update-and-patch && brew update-reset
```

6. check that everything goes as expected

```sh
brew config
```

   `ORIGIN` should match `HOMEBREW_BREW_GIT_REMOTE`.

## short overview of patches

`0001-unsupported-os-silent.patch`  
Makes it possible to disable the annoying warning that Intel macOS is not supported.  
Set `$HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS`.  
Take that Apple Silicon!

`0002-build-from-source.patch`  
Adds `$HOMEBREW_BUILD_FROM_SOURCES_YOU_PHILISTINE`.  
If it is set, build _everything_ from source.  
Yes, including dependencies.  
Yes, even when bottles are available.

`0003-formula-overlay.patch`  
Now it is possible to create a local overlay for any formula.  
No need to mess with taps.  
No need to wait for upstream fixes.  
Just create a formula with the same name locally and brew will treat it like a regular formula.  
Set `$HOMEBREW_FORMULA_OVERLAY` to that directory, for example `$HOME/brew-self/Formula`.  
`brew fetch` and `brew install` may reload that file by path; the overlay directory is allowed, and the formula stays in `homebrew/core`.

`0004-odeprecated-silent.patch`  
Adds `$HOMEBREW_ODEPRECATED_AND_I_DONT_CARE`.  
If it is set, Homebrew does not warn about environment variables marked `odeprecated: true`.  
Variables marked `odisabled: true` still warn.

`0005-info-installed-dependents.patch`  
No switch.  
`brew info` lists installed formulae that depend on this one, grouped by how they depend on it:  
Required, Recommended, Optional, Build, Test, Implicit.  
Empty groups are skipped. Casks are not included.  
Only shown in a terminal, same as the old one-line dependent count.

`0006-info-recursive-runtime-names.patch`  
No switch.  
`brew info` prints the names in `Recursive Runtime`, not only a count.  
Each name is marked installed or missing.  
The list is the runtime tree recorded when the formula was installed.

`0007-info-verbose.patch`  
Adds `$HOMEBREW_INFO_VERBOSE`.  
If it is set, `brew info` shows the same output as `brew info --verbose`.

`0009-manual-fetch-command.patch`  
`brew fetch --print-command` prints a command that fetches that file or git repo into Homebrew's cache.  
`$HOMEBREW_FETCH_PRINT_COMMAND=1` does the same for every download.  
Copy the command and run it when a download stalls. The next `brew fetch` then sees the file as already downloaded.

## caveats

`0008-clear-receipt-cache.patch` was removed on 7.0.7. Upstream already runs `Tab.clear_cache` right after `build`.

As you can see, there is no way yet to tie patches to a specific `brew` version.  
Upstream changes can break the patches.  
If that happens, ask your favorite agent to fix them.  
Or wait for me to push an update to this repo.

