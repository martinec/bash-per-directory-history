#!/usr/bin/env bash
# =============================================================================
# Per directory history for Bash
# =============================================================================
# Copyright (c) 2017, Cristian Martinez (martinec)
# =============================================================================
# Code must be ShellCheck-compliant @see http://www.shellcheck.net/about.html
# for information about how to run ShellCheck locally
# e.g shellcheck -s bash per-directory-history.sh
# =============================================================================
# shellcheck disable=SC2034
BPDH_SCRIPT_VERSION="0.9.0"
# =============================================================================
# Minimal Bash version
BPDH_SCRIPT_MINIMAL_BASH_VERSION_STRING="3.2.25"
BPDH_SCRIPT_MINIMAL_BASH_VERSION_NUMBER=$((3 * 100000 + 2 * 1000 + 25))
# =============================================================================
BPDH_SCRIPT_DEFAULT_ERROR_CODE=1
# =============================================================================
BPDH_COMMAND_PRINTF=$( command -v printf )
BPDH_COMMAND_CD="builtin cd"
BPDH_COMMAND_PUSHD="builtin pushd"
BPDH_COMMAND_POPD="builtin popd"
BPDH_COMMAND_HISTORY="builtin history"
# =============================================================================
# Script name
BPDH_SCRIPT_NAME=${BASH_SOURCE[0]##*/}
# This snippet is from @source http://stackoverflow.com/a/246128
BPDH_SCRIPT_BASEDIR=$( $BPDH_COMMAND_CD "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# history data store
BPDH_HOME="$BPDH_SCRIPT_BASEDIR/fs/${USER}@${HOSTNAME}"
BPDH_INDS="$BPDH_SCRIPT_BASEDIR/is/${USER}@${HOSTNAME}"
# default bash_history filename
BPDH_DEF_FILE="bash_history.txt"
# backup bash_history filename
BPDH_BKP_FILE="bash_history.bkp"
# =============================================================================
# Portable echo function
# @source http://www.etalabs.net/sh_tricks.html
# =============================================================================
bpdh::echo() (
  fmt=%s end=\\n IFS=" "

  while [ $# -gt 1 ] ; do
   case "$1" in
    [!-]*|-*[!ne]*) break;;
    *ne*|*en*) fmt=%b end=;;
    *n*) end=;;
    *e*) fmt=%b;;
   esac
   shift
  done

  $BPDH_COMMAND_PRINTF "$fmt$end" "$*"
)
# =============================================================================
# Portable readlink -f
# based on @see http://stackoverflow.com/a/1116890/2042871
# =============================================================================
bpdh::readlinkf() {
  TARGET_FILE="$1"

  $BPDH_COMMAND_CD "$(dirname "$TARGET_FILE")" || {
    # @see https://github.com/koalaman/shellcheck/wiki/SC2164
    $BPDH_COMMAND_PRINTF "%s" "$1" && return
  }

  TARGET_FILE=$(basename "$TARGET_FILE")

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]
  do
    TARGET_FILE=$(readlink "$TARGET_FILE")
    $BPDH_COMMAND_CD "$(dirname "$TARGET_FILE")"  || {
      # @see https://github.com/koalaman/shellcheck/wiki/SC2164
      $BPDH_COMMAND_PRINTF "%s" "$1" && return
    }
    TARGET_FILE=$(basename "$TARGET_FILE")
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  PHYS_DIR=$(pwd -P)
  if [[ "${PHYS_DIR}" = "/" ]]; then
    RESULT="/$TARGET_FILE"
  else
    RESULT="$PHYS_DIR/$TARGET_FILE"
  fi

  $BPDH_COMMAND_PRINTF "%s" "$RESULT"
}
# =============================================================================
# Print an error message to stderr
# =============================================================================
function bpdh::error() {
  bpdh::echo "[$BPDH_SCRIPT_NAME@$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}
# =============================================================================
# Check if the bash version is the minimal need to run this script
# =============================================================================
function bpdh::check_bash_version() {
  local -r bash_version_string="${BASH_VERSION%%[^0-9.]*}"
  local -r bash_version_major="${BASH_VERSINFO[0]}"
  local -r bash_version_minor="${BASH_VERSINFO[1]}"
  local -r bash_version_patch="${BASH_VERSINFO[2]}"

  #          $bash_version_major * (major <= +INF)
  # 100000 + $bash_version_minor * (minor <= 99)
  # 1000   + $bash_version_patch   (patch <= 999)
  local -r bash_version_number=$(echo "$bash_version_major  * 100000 \
                                     + $bash_version_minor  * 1000 + \
                                       $bash_version_patch" | bc)

  # check bash version
  if [ "$bash_version_number" -lt "$BPDH_SCRIPT_MINIMAL_BASH_VERSION_NUMBER" ]; then
    bpdh::error "Bad Bash version: Required($BPDH_SCRIPT_MINIMAL_BASH_VERSION_STRING)"\
                "- Using($bash_version_string)"
    return 1
  fi
}
# =============================================================================
# enhanced cd
# adapted from @see https://gist.github.com/mbadran/130469
# =============================================================================
function bpdh::ecd() {
  # typing just `bpdh::ecd` will take you $HOME ;)
  if [ "$1" == "" ]; then
      $BPDH_COMMAND_PUSHD "$HOME" > /dev/null

  # use `bpdh::ecd -` to visit previous directory
  elif [ "$1" == "-" ]; then
      $BPDH_COMMAND_PUSHD "$OLDPWD" > /dev/null

  # use `bpdh::ecd -n` to go n directories back in history
  elif [[ "$1" =~ ^-[0-9]+$ ]]; then
      # shellcheck disable=SC2034
      for i in $(seq 1 "${1/-/}"); do
          $BPDH_COMMAND_POPD > /dev/null
      done

  # use `bpdh::ecd -- <path>` if your path begins with a dash
  elif [ "$1" == "--" ]; then
      shift
      $BPDH_COMMAND_PUSHD -- "$@" > /dev/null

  # allow `bpdh::ecd` stdoud output if looks like a command line option
  elif [[ "$1" == --* ]]; then
      $BPDH_COMMAND_PUSHD "$@"

  # basic case: move to a dir and add it to history
  else
      $BPDH_COMMAND_PUSHD "$@" > /dev/null
  fi
}
# =============================================================================
# cd command featuring per-directory history capabilities
# @see http://www.debian-administration.org/articles/543#comment_17
# @see http://dieter.plaetinck.be/post/per_directory_bash_history
# @see http://www.compbiome.com/2010/07/bash-per-directory-bash-history.html
# @see http://www.onerussian.com/Linux/bash_history.phtml
# @see http://www.softpanorama.org/Scripting/Shellorama/bash_command_history_reuse.shtml
# =============================================================================
function bpdh::cd() {
  local -r directory="$*"
  local exit_status

  local -r history_size=$($BPDH_COMMAND_HISTORY | wc -l)

  # only rewrite the history when non empty
  if [[ "$history_size" -ge 1 ]]; then
    # read all history lines not already read from the history
    # file and append them to the history list
    $BPDH_COMMAND_HISTORY -n
    # write the current history to the history file
    $BPDH_COMMAND_HISTORY -w

    # create a backup of the default history
    local previous_directory
    # get the canonical directory name
    previous_directory="$(bpdh::readlinkf "$PWD")"
    # default place where the per-directory history will be saved
    local PREVIOUS_HISTDIR="${BPDH_HOME}${previous_directory}"

    # only if there is a history to backup
    if [ -f "${PREVIOUS_HISTDIR:?}/${BPDH_DEF_FILE:?}" ]; then
      cp -f "${PREVIOUS_HISTDIR:?}/${BPDH_DEF_FILE:?}" \
            "${PREVIOUS_HISTDIR:?}/${BPDH_BKP_FILE:?}" >/dev/null
    fi
  fi

  {
    # Change the current directory using the bpdh::ecd command
    bpdh::ecd "$directory"

    # save the return code
    exit_status=$?
  }

  # if the directory has changed
  if [[ "$exit_status" -eq 0 ]]; then
    local current_directory
    # get the canonical directory name
    current_directory="$(bpdh::readlinkf "$PWD")"
    # default place where the per-directory history will be saved
    local HISTDIR="${BPDH_HOME}${current_directory}"

    if [ ! -d "${HISTDIR:?}" ]; then
      # no error if existing, make parent directories as needed
      mkdir -p "${HISTDIR:?}" > /dev/null
    fi

    # if a directory is moved or renamed the history will be lost.
    # However, if the destination is the same filesystem as the
    # source, this has no impact on the inode number, it will only
    # changes the time stamps in the inode table
    local -r HISTIND="${BPDH_INDS:?}/$(stat -c '%i' "$current_directory")"
    if [ ! -d "${HISTIND:?}" ]; then
      # create a symbolic link from /fs/canonical/path to /is/inode
      ln -s "${HISTDIR:?}" "${HISTIND:?}"  > /dev/null
    fi

    # when the shell starts up, the history is initialized from the file
    # named by the HISTFILE variable, if the /fs/canonical/path/history.txt
    # doesn't exists but /is/inode/history.txt is there, then load the
    # history file from the inode path
    if [ ! -f "${HISTDIR:?}/${BPDH_DEF_FILE:?}" ] && \
       [   -f "${HISTIND:?}/${BPDH_DEF_FILE:?}" ]; then
      # move /is/inode/history.txt to /fs/canonical/path
      mv "${HISTIND:?}/${BPDH_DEF_FILE:?}" \
         "${HISTDIR:?}/${BPDH_DEF_FILE:?}" > /dev/null
      # remove previous symbolic link
      unlink "${HISTIND:?}" > /dev/null
      # recreate a symbolic link from /fs/canonical/path to /is/inode
      ln -s "${HISTDIR:?}" "${HISTIND:?}"  > /dev/null
    fi

    # test when to load the default or backup history
    if [ -f "${HISTDIR:?}/${BPDH_DEF_FILE:?}" ] && \
       [ -f "${HISTDIR:?}/${BPDH_BKP_FILE:?}" ]; then
      local BPDH_DEF_FILE_SIZE
      BPDH_DEF_FILE_SIZE=$(wc -l < "${HISTDIR:?}/${BPDH_DEF_FILE:?}")

      local BPDH_BKP_FILE_SIZE
      BPDH_BKP_FILE_SIZE=$(wc -l < "${HISTDIR:?}/${BPDH_BKP_FILE:?}")

      # if the default history is empty and there are entries in the backup
      if (( BPDH_DEF_FILE_SIZE==0 && BPDH_BKP_FILE_SIZE>1 )); then
        # restore to default history
        cat "${HISTDIR:?}/${BPDH_BKP_FILE:?}" >> \
            "${HISTDIR:?}/${BPDH_DEF_FILE:?}"
      fi
    fi

    # load directory history from /fs/canonical/path/history.txt
    export HISTFILE="${HISTDIR:?}/${BPDH_DEF_FILE:?}"
  else
    # if the cd command fails, try to show a suggestion using cdspell
    # returns success if cdspell is enabled; return fails otherwise
    shopt cdspell >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
      local suggestion
      suggestion=$(bash --init-file <(echo "shopt -s cdspell") -i -c "builtin cd $directory 2>/dev/null")
      # shellcheck disable=SC2181
      if [[ "$?" -eq 0 ]]; then
        bpdh::echo "try cd $suggestion"
      fi
    fi
  fi

  # clear the history list by deleting all of the entries
  $BPDH_COMMAND_HISTORY -c
  # read the history file and append the contents to the history list
  $BPDH_COMMAND_HISTORY -r

  # return the status
  return $exit_status
}
# =============================================================================
# Faster history navigation
# This allows typing part of a command and then using the arrows to
# select matching commands from history. The last two bindings ensure
# that the left and right keys continue to work correctly.
# @source https://ss64.com/bash/bind.html
# =============================================================================
function bpdh::faster_history_navigation() {
  # search backward through the history for the string of characters
  # between the start of the current line and the point.
  bind '"\e[A": history-search-backward'
  # search forward through the history for the string of characters
  # between the start of the current line and the point.
  bind '"\e[B": history-search-forward'
  # move forward a character
  bind '"\e[C": forward-char'
  # move back a character
  bind '"\e[D": backward-char'
}
# =============================================================================
# Smarter tab completion
# @source http://mrzool.cc/writing/sensible-bash
# =============================================================================
function bpdh::smarter_tab_completion() {
  #  perform filename completion in a case-insensitive fashion
  bind 'set completion-ignore-case on'
  # filename matching during completion will treat hyphens and
  # underscores as equivalent
  bind 'set completion-map-case on'
  # display all possible matches for an ambiguous pattern at the
  # first <Tab> press instead of at the second
  bind 'set show-all-if-ambiguous on'
}
# =============================================================================
# Better bash history
# @see https://sanctum.geek.nz/arabesque/better-bash-history
# =============================================================================
function bpdh::better_bash_history() {
  # save multi-line commands as one command
  shopt -s cmdhist

  # re-edit a history substitution line if it failed
  shopt -s histreedit

  # allow a larger history file
  HISTSIZE=500000
  HISTFILESIZE=100000

  # ignoredups : lines which match the previous history entry will not be saved
  # erasedups  : all previous lines matching the current line will be removed
  #              before that line is saved
  # ignorespace: lines which begin with a space character will be not saved
  HISTCONTROL="ignoredups:erasedups:ignorespace"

  # remove the use of certain commands from your history
  export HISTIGNORE="$HISTIGNORE${HISTIGNORE+:}exit:clear:ls:history"
}
# =============================================================================
# Initialization
# =============================================================================
function bpdh::init() {
  # check bash version
  bpdh::check_bash_version ||\
           return $BPDH_SCRIPT_DEFAULT_ERROR_CODE
  # if signal, append history lines from this session to the history file
  # for a discussion, @see http://unix.stackexchange.com/a/18443/220737
  trap '$BPDH_COMMAND_HISTORY -n;
        $BPDH_COMMAND_HISTORY -w; 
        $BPDH_COMMAND_HISTORY -c; 
        $BPDH_COMMAND_HISTORY -r' SIGHUP SIGINT SIGTERM
  # prepare directories
  mkdir -p "${BPDH_HOME:?}" "${BPDH_INDS:?}" > /dev/null ||\
           return $BPDH_SCRIPT_DEFAULT_ERROR_CODE
  # write the current history to the history file
  $BPDH_COMMAND_HISTORY -w
  # legacy cd command is now available as _bcd
  alias _bcd='$BPDH_COMMAND_CD'
  # append to the history file, don't overwrite it
  shopt -s histappend
  # better bash history
  bpdh::better_bash_history
  # replace standard `cd` with the bpdh version
  alias cd=bpdh::cd
  # ensure tab-completion works
  complete -d cd
  # useful Readline bind commands
  command -v bind >/dev/null 2>&1 && {
    # allows typing part of a command and then using the arrows to
    # select matching commands from history
    bpdh::faster_history_navigation
    # smarter tab completion
    bpdh::smarter_tab_completion
  }
  # star tracking from the current directory
  export HISTFILE
  HISTFILE="${BPDH_HOME}$(bpdh::readlinkf "$PWD")/${BPDH_DEF_FILE:?}"
  # ensures the creation of the history file when bash is run for a new interactive
  # shell pointing to a directory that does not have yet its own local history file
  bpdh::cd "$PWD"
}
# =============================================================================
# Global history
# =============================================================================
function gistory() {
  find "${BPDH_HOME:?}" -name "${BPDH_DEF_FILE:?}" -type f -exec cat {} \; 2>/dev/null | nl
}
# =============================================================================
# ~/.bashrc is supposed to be only sourced for interactive shells.
# Nevertheless, we test when $- includes i to check if the script
# is really running in interactive mode
if [[ $- == *i* ]]; then
  bpdh::init "$@" || return $BPDH_SCRIPT_DEFAULT_ERROR_CODE
fi
