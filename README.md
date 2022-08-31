# Per directory history for Bash [![Build Status](https://travis-ci.org/martinec/bash-per-directory-history.svg?branch=master)](https://travis-ci.org/martinec/bash-per-directory-history)

## Install

Before install create a backup of your `.bash_history`, then clone this
repository to your home directory:

```
cd ~
git clone https://github.com/martinec/bash-per-directory-history.git .bash-per-directory-history
```

and append the next line at the bottom of your `~/.bashrc`:

```
source ~/.bash-per-directory-history/per-directory-history.sh
```

alternatively, to [ensure sync](https://unix.stackexchange.com/a/18443) between the
bash memory and the history file, for example to share the history across all open
terminals, you can instead append:

```
source ~/.bash-per-directory-history/per-directory-history.sh
PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"
```

## Features

- Per directory history.
- Global history with `gistory` command.
- Enhanced `cd` (using behind `pushd` and `popd` as replacement).
- Spell suggestions for mistyped directory names.
- Preserve history no matter if a directory has been moved or renamed (same filesystem).
- Add-ons: `faster-history-navigation`, `smarter-tab-completion`, `better-bash-history`.
- [ShellCheck](https://www.shellcheck.net/)-compliant code.

## Reporting bugs

Please use the GitHub issue tracker for any bugs or feature suggestions:

https://github.com/martinec/bash-per-directory-history/issues

## Contributing

Everyone is welcome to contribute! [Fork us](https://github.com/martinec/bash-per-directory-history/fork) and [request a pull](https://github.com/martinec/bash-per-directory-history/pulls) to the [develop branch](https://github.com/martinec/bash-per-directory-history/tree/develop).

---












