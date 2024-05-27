#!/usr/bin/env bash

# Author           : fist_it (fist-it@protonmail.com)
# Created On       : 12.05.2024
# Last Modified By : fist_it (fist-it@protonmail.com)
# Last Modified On : 27.05.2024
# Version          : 0.1.0
#
# Description      :
# Script copying configuration files from a git remote repository 
# with additional functionalities
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

set -u
shopt -s dotglob


# help, version, exit codes {{{
print_help() {
  echo "Usage: ./copyconfig [-hvSl] repository_link (without .git at the end)

  -h  Display this help message.
  -v  Display the version.
  -S  Use stow to symlink files.
  -l  Light mode, only link files that come from installed packages.

  combinations are NOT possible, only one flag can be used at a time.
  using GNU stow is recommended, but not required.

  example:
  ./copyconfig -S git@github.com:fist-it/dotfiles (works as well as https://github.com/fist-it/dotfiles)
  this will link dotfiles from https://github.com/fist-it/dotfiles with stow

  "
}

print_version() {
  echo "copyconfig beta@0.1.0"
}


throw () {
  case "$1" in
    1) echo "You are offline"; exit 1;;
    2) echo "Repository not provided"; exit 2;;
    3) echo "Repository not found"; exit 3;;

    127) echo "git not found"; exit 127;;
    128) echo "Stow usage declared but not found"; exit 128;;
    *) echo "unhandled error has occured"; exit 255;;
  esac
}

# }}}

# linking functions {{{

# no lightmode, manual link: {{{
link_dotfiles() {
  FROM=$1
  TO=$2
  for dotfile in "${FROM}"/*
  do
    if [ -d "${dotfile}" ] && [ "$(basename "${dotfile}")" != "." ] && [ "$(basename "${dotfile}")" != ".." ] && [ "$(basename "${dotfile}")" != ".git" ]; then
      if [ "${dotfile}" == "${FROM}/.config" ]; then
        if [ ! -d "${TO}/.config" ]; then
          mkdir "${TO}/.config"
        fi

        # handle .config files 
        for configfile in "${FROM}"/.config/*
        do
          if [ -d "${TO}/.config/$(basename "${configfile}")" ]; then
            mv "${TO}/.config/$(basename "${configfile}")" "${TO}/.config/$(basename "${configfile}").bak"
          fi
          ln -sf "${configfile}" "${TO}/.config/${configfile##*/}"
        done


      else
        ln -sf "${dotfile}" "${TO}/${dotfile##*/}"
      fi

    elif [ -f "${dotfile}" ]; then
      if [ -f "${TO}/$(basename "${dotfile}")" ]; then
        mv "${TO}/$(basename "${dotfile}")" "${TO}/$(basename "${dotfile}").bak"
      fi
      ln -sf "${dotfile}" "${TO}/${dotfile##*/}"
    fi
  done
}
# }}}

# lightmode, only link files that come from installed packages: {{{
light_link_dotfiles() {
  FROM=$1
  TO=$2
  for dotfile in "${FROM}"/*
  do
    if [ -d "${dotfile}" ] && [ "$(basename "${dotfile}")" != "." ] && [ "$(basename "${dotfile}")" != ".." ] && [ "$(basename "${dotfile}")" != ".git" ]; then
      if [ "${dotfile}" == "${FROM}/.config" ]; then
        if [ ! -d "${TO}/.config" ]; then
          mkdir "${TO}/.config"
        fi

        # handle .config files 
        for configfile in "${FROM}"/.config/*
        do
          
          # powinno zwracac zero przy istnieniu komendy
          # ale dzialalo odwrotnie
          if command -v "$(basename "${configfile}")" &> /dev/null 
          then
            echo "linking ${configfile##*/}"
            if [ -d "${TO}/.config/$(basename "${configfile}")" ]; then
              mv "${TO}/.config/$(basename "${configfile}")" "${TO}/.config/$(basename "${configfile}").bak"
            fi
            ln -sf "${configfile}" "${TO}/.config/${configfile##*/}"
          else
            rm -rf "${configfile}"
          fi
        done


      else
        ln -sf "${dotfile}" "${TO}/${dotfile##*/}"
      fi

    elif [ -f "${dotfile}" ]; then
      if [ -f "${TO}/$(basename "${dotfile}")" ]; then
        mv "${TO}/$(basename "${dotfile}")" "${TO}/$(basename "${dotfile}").bak"
      fi
      ln -sf "${dotfile}" "${TO}/${dotfile##*/}"
    fi
  done
}
# }}}

# }}}

LIGHT=0
STOW=0


while getopts 'hvSl' option; do
  case "$option" in
    h) print_help; exit;;
    v) print_version; exit;;
    S) STOW=1; echo "stow enabled";;
    l) LIGHT=1; echo "light mode enabled";;
    *) echo "unknown flag: $1"; print_help; exit;;
  esac
done

# if any flag provided, shift the arguments
shift $((OPTIND - 1))

# something going wrong before cloning the repository handled {{{

if : >/dev/tcp/8.8.8.8/53
then
    echo "Online, checking repository availability"
else
  throw 1
fi

if [ $# -lt 1 ]; then
  print_help
  throw 2
else
  REPO=$1
fi

if ! command -v git &> /dev/null
then
    throw 127
 else
   echo "git installed"
fi
# }}}

# convert ssh to https if needed, check if repo exists, if yes clone {{{
ssh_regex="^git@.*"

if [[ $REPO =~ $ssh_regex ]]; then
  # Remove "git@" from the beginning
  trimmed="${REPO#git@}"
  
  # Replace ":" with "/"
  replaced="${trimmed/://}"
  
  # Insert "https://" at the beginning
  REPO="https://$replaced"
fi
  
if git ls-remote "${REPO}"
then
  git clone --depth 1 "${REPO}" ~/.dotfiles
else
  throw 3
fi
# }}}

DOTFILES="${HOME}/.dotfiles"
if ! command -v stow &> /dev/null
then
  if [ "${STOW}" -ne 0 ]; then
    throw 128
  fi
fi

if [ "${STOW}" -ne 0 ]; then
  echo "Stowing files"
  stow -d "${DOTFILES}" .
else
  if [ "${LIGHT}" -ne 0 ]; then
    echo "Light linking files"
    light_link_dotfiles "${DOTFILES}" "${HOME}"
  else
    echo "Linking files"
    link_dotfiles "${DOTFILES}" "${HOME}"
  fi
fi
