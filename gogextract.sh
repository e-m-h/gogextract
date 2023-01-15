#!/usr/bin/env bash

# Use innoextract to unpackage GOG games while removing extraneous files (e.g. DOSBox)
# Create appropriate directory using GOG ID (maybe capitalize and truncate to 8 characters)

# innoextract --exclude-temp

unset -f command

GAMEARCHIVE=${1}
EXDIR=${EXDIR:-${PWD}}
NEWDIR=$(innoextract --gog-game-id "${GAMEARCHIVE}" | cut -d '"' -f2 | head -n1 | tr " " "_")

checkGamedir() {
	if [[ $(innoextract -l ${GAMEARCHIVE} | grep -ic app) -gt 10 ]]; then
		printf "A large number of files found in 'app' directory.\n"
	else
		printf "Smaller number of files found in 'app' directory.\n"
	fi 
}

innoextractCheck() {
  if [[ $(command -v innoextract) ]]; then
    printf "Innoextract found. Proceeding with extraction.\n"
    :
  else
    case $(uname -s) in
      Darwin)
        printf "Using macOS, checking for Brew...\n";
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
            printf "Fedora found. Proceeding with innoextract install via yum.\nYou may be prompted for your password.\n";
            sudo yum install innoextract
          ;;
          Ubuntu|Debian)
            printf "%s found. Proceeding with innoextract install via apt.\nYou may be prompted for your password.\n" "$(lsb_release --id | awk '{ print $3 }')";
            sudo apt install innoextract
          ;;
          *)
            printf "Distribution not recognized!\n";
            exit
          ;;
        esac
#        More please
        ;;    
    esac
  fi
}

extractFiles() {
  if [[ -d "${EXDIR}" ]]; then
    printf "Extracting to %s" "${EXDIR}\n";
    innoextract --exclude-temp "${GAMEARCHIVE}" -d "${EXDIR}"
  else
    printf "Directory "${EXDIR}" does not exist. Exiting.\n";
    exit
  fi
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
  mv "${EXDIR}"/app "${NEWDIR}"
}

createConfig() {
  touch "${EXDIR}/${NEWDIR}"/start.sh
  #GOG DOSBox configs tend to use relative paths and fail to start the game if don't start from a subdirectory. This replaces parent directory with current.
  sed -i "s/\.\./\./g" "$(find $"${EXDIR}/${NEWDIR}" -iname "dosbox*single.conf")"
  printf "dosbox -conf %s" "$(find $"${EXDIR}/${NEWDIR}" -iname "dosbox*single.conf")" > "${EXDIR}/${NEWDIR}"/start.sh
  chmod 755 "${EXDIR}/${NEWDIR}"/start.sh
}

#checkGamedir
innoextractCheck
extractFiles 
removeFiles
createConfig
