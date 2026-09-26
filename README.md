
# What, Why and for Whom

Patched `homebrew` with missing features that are relevant mostly for devices running macOS on Intel CPUs.

See list of patches below to decide if it is of any use for you personally.

# how to start using homebrew-macos-intel-x86_64 TODAY!

. clone this repo
```sh
mkdir -p ~/brew-self
git clone https://github.com/vigilancer/homebrew-macos-intel-x86_64.git ~/brew-self
```
. remove patches you don't need (if any)
```sh
cd ~/brew-self
rm patches/0001-unsupported-os.patch
rm patches/0002-build-from-source.patch
rm patches/0003-formula-overlay.patch
rm patches/0004-forbid-casks-no-whining.patch
```

. brew your own
  this will create shallow copy of latest `brew` release in `brew` folder and apply patches to it.
  brew? brew! ah, brew... 
```
./update
```

. set new source for `brew` updates
  and make use of installed patches
```sh
mkdir -p ~/.homebrew
cat > ~/.homebrew/brew.env << EOF
HOMEBREW_BREW_GIT_REMOTE=$HOME/brew-self/brew
HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1           # patch 0001
HOMEBREW_BUILD_FROM_SOURCES_YOU_PHILISTINE=1      # patch 0002
HOMEBREW_FORMULA_OVERLAY=$HOME/brew-self/Formula  # patch 0003
EOF
```

. update brew
```brew update```

. check that everything goes as expected
```sh
brew config
```
`ORIGIN` should match `HOMEBREW_BREW_GIT_REMOTE`.

. (optionally) add shell alias
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

# short overview of patches

`0001-unsupported-os.patch`
Makes possible to disable annoying warning about Intel macOS is not being supported.  
Take that Apple Silicon!

`0002-build-from-source.patch`
Adds flag to build from sources _everything_.  
Yes, including dependencies.  
Yes, even when bottles are available.  

`0003-formula-overlay.patch`
Now it is possible to create local overlay for every formula.  
No need to mess with taps.  
No need to wait for upstream fixes.
Just create formula with same name locally and brew will treat it like regular formula.
Place your overlays into `$HOME/brew-self/Formula/`.

`0004-forbid-casks-no-whining.patch`
Disables annoying *Calling HOMEBREW_FORBID_CASKS is deprecated! There is no replacement.* message.
(Really should be made into global toggle to disable *odeprecated* messages all at once. But this is how it is for now).

