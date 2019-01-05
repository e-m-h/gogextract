#!/usr/bin/env bash

# Use innoextract to unpackage GOG games while removing extraneous files (e.g. DOSBox)
# Create appropriate directory using GOG ID (maybe capitalize and truncate to 8 characters)

# innoextract --exclude-temp

unset -f command

GAMEARCHIVE=${1}
EXDIR=${EXDIR:-${PWD}}

innoextractCheck() {
  if [[ $(command -v innoextract) ]]; then
    printf "Innoextract found.\n"
    :
  else
    case $(uname -s) in
      Darwin)
        printf "Using Mac, checking for Brew...\n";
          if [[ $(command -v brew) ]]; then 
            brew install innoextract
          else
            printf "Homebrew not found. Install Homebrew or innoextract to continue.";
            exit 
          fi
        ;;
      Linux)
        case $(lsb_release --id | awk '{ print $3 }') in
          Fedora)
            sudo yum install innoextract
          ;;
          Ubuntu|Debian)
            sudo apt install innoextract
          ;;
					*)
						printf "Distribution not recognized!\n";
						exit
        esac
#        More please
        ;;    
    esac
  fi
}

extractFiles() {
  innoextract --exclude-temp "${GAMEARCHIVE}" -d "${EXDIR}"
}

removeFiles() {
  printf "Removing extraneous files from %s/ (commonappdata and DOSBox/GOG files).\n" "${EXDIR}";
  rm -rfv "${EXDIR}"/commonappdata;
  find "${EXDIR}" -iname "*goggame*" -exec rm -vf {} \;
  rm -vf "${EXDIR}"/app/webcache.zip;
  rm -vf "${EXDIR}"/app/GameuxInstallHelper.dll;
  rm -rvf "${EXDIR}"/app/__support/
  if [[ -d "${EXDIR}"/app/DOSBOX/ ]]; then
    rm -rvf "${EXDIR}"/app/DOSBOX/;
  fi
  #Rename directory to game ID
  mv "${EXDIR}"/app "$(innoextract --gog-game-id "${GAMEARCHIVE}" | cut -d '"' -f2 | head -n1)"
}

innoextractCheck
extractFiles 
removeFiles

