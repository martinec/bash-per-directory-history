# Per directory history for Bash [![Build Status](https://travis-ci.org/martinec/bash-per-directory-history.svg?branch=master)](https://travis-ci.org/martinec/bash-per-directory-history)

## Install

Before install create a backup of your `.bash_history`, then clone this
repository to your home directory:

```
cd ~
git clone https://github.com/martinec/bash-per-directory-history.git .bash-per-directory-history
```

Add to your `~/.bashrc`:

```
source ~/.bash-per-directory-history/per-directory-history.sh
```

## Features

- Per directory history.
- Global history with `gistory` command.
- `pushd` and `popd` as a drop in `cd` replacement.
- Spell suggestions for mistyped directory names.
- Preserve history no matter if a directory has been moved or renamed (same filesystem).
- Add-ons: `faster_history_navigation`, `smarter_tab_completion`, `better_bash_history`.
- [ShellCheck](https://www.shellcheck.net/)-compliant code.

## Reporting bugs

Please use the GitHub issue tracker for any bugs or feature suggestions:

https://github.com/martinec/bash-per-directory-history/issues

## Contributing

Everyone is welcome to contribute! [Fork us](https://github.com/martinec/bash-per-directory-history/fork) and [request a pull](https://github.com/martinec/bash-per-directory-history/pulls) to the [develop branch](https://github.com/martinec/bash-per-directory-history/tree/develop).

--












