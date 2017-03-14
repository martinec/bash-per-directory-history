#!/usr/bin/env bash
# This is from https://github.com/caarlos0/shell-ci-build
# @author  Carlos Becker
# @license MIT
set -eo pipefail
[[ "${DEBUG:-}" ]] && set -x

success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] Linting %s...\n" "$1"
}

fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] Linting %s...\n" "$1"
  exit 1
}

check() {
  local script="$1"
  shellcheck -s bash -e SC2166 "$script" || fail "$script"
  success "$script"
}

find_prunes() {
  local prunes="! -path './.git/*'"
  if [ -f .gitmodules ]; then
    while read -r module; do
      prunes="$prunes ! -path './$module/*'"
    done < <(grep path .gitmodules | awk '{print $3}')
  fi
  echo "$prunes"
}

find_cmd() {
  # GNU Find no longer accepts -perm +111, even though the rest
  # world (MacOS, Solaris, BSD, etc.) does.  Sigh.  Using -executable
  # is arguably better, but it is a GNU extension.
  # @source guilt-fix-portability-problem-with-using-find-perm-111.html
  # @author Theodore Ts'o
  if find . -maxdepth 0 -executable > /dev/null 2>&1 ; then
    exe_test="-executable"
  else
    exe_test="-perm +111"
  fi

  echo "find . -type f -and \( $exe_test -or -name '*.sh' \) $(find_prunes)"
}

check_all_executables() {
  echo "Linting all executables and .sh files, ignoring files inside git modules..."
  eval "$(find_cmd)" | while read -r script; do
    head=$(head -n1 "$script")
    [[ "$head" =~ .*ruby.* ]] && continue
    [[ "$head" =~ .*zsh.* ]] && continue
    [[ "$head" =~ ^#compdef.* ]] && continue
    check "$script"
  done
}

check_all_executables
