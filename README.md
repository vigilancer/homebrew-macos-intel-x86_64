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
rm patches/0001-unsupported-os.patch
rm patches/0002-build-from-source.patch
rm patches/0003-formula-overlay.patch
rm patches/0004-forbid-casks-no-whining.patch
rm patches/0005-info-installed-dependents.patch
```

3. brew your own

   this will fetch the latest `brew` release with full history into the `brew` folder and apply patches to it.

   brew? brew! ah, brew...

```sh
./update
```

4. set new source for `brew` updates

   and enable the patches you kept

```sh
mkdir -p ~/.homebrew
cat > ~/.homebrew/brew.env << EOF
HOMEBREW_BREW_GIT_REMOTE=$HOME/brew-self/brew
HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1           # patch 0001
HOMEBREW_BUILD_FROM_SOURCES_YOU_PHILISTINE=1      # patch 0002
HOMEBREW_FORMULA_OVERLAY=$HOME/brew-self/Formula  # patch 0003
EOF
```

5. update brew

```sh
brew update
```

6. check that everything goes as expected

```sh
brew config
```

   `ORIGIN` should match `HOMEBREW_BREW_GIT_REMOTE`.

7. (optionally) add shell alias

   fish:

```fish
function brew-update
    ~/brew-self/update; and brew update $argv
end
```

   bash & zsh:

```bash
brew-update() {
    ~/brew-self/update && brew update "$@"
}
```

## short overview of patches

`0001-unsupported-os.patch`  
Makes it possible to disable the annoying warning that Intel macOS is not supported.  
Take that Apple Silicon!

`0002-build-from-source.patch`  
Adds a switch to build _everything_ from source.  
Yes, including dependencies.  
Yes, even when bottles are available.

`0003-formula-overlay.patch`  
Now it is possible to create a local overlay for any formula.  
No need to mess with taps.  
No need to wait for upstream fixes.  
Just create a formula with the same name locally and brew will treat it like a regular formula.  
Place your overlays in `$HOME/brew-self/Formula/`.

`0004-forbid-casks-no-whining.patch`  
Disables the annoying *Calling HOMEBREW_FORBID_CASKS is deprecated! There is no replacement.* message.  
(Really should be made into a global toggle to disable *odeprecated* messages all at once. But this is how it is for now).

`0005-info-installed-dependents.patch`  
`brew info` lists installed formulae that depend on this one, grouped by how they depend on it:  
Required, Recommended, Optional, Build, Test, Implicit.  
Empty groups are skipped. Casks are not included.  
Only shown in a terminal, same as the old one-line dependent count.

## caveats

As you can see, there is no way yet to tie patches to a specific `brew` version.  
Upstream changes can break the patches.  
If that happens, ask your favorite agent to fix them.  
Or wait for me to push an update to this repo.

