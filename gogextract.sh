#!/usr/bin/env bash

# Use innoextract to unpackage GOG games while removing extraneous files (e.g. DOSBox)
# Create appropriate directory using GOG ID (maybe capitalize and truncate to 8 characters)

# innoextract --exclude-temp


# unset -f command  # Not sure this is necessary

GAMEARCHIVE=${1}
EXDIR=${EXDIR:-${PWD}}
DESTDIR="${EXDIR}/$(innoextract --gog-game-id "${GAMEARCHIVE}" | cut -d '"' -f2 | head -n1 | tr -d " " | cut -c -8)"

checkGamedir() {
  if [[ $(ls ${DESTDIR}/app/ | wc -l ) -gt 10 ]]; then
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
  if [[ -d "${DESTDIR}" ]]; then
    printf "Destination directory already exists. Exiting.\n"
    exit
  else
    innoextract --exclude-temp "${GAMEARCHIVE}" -d "${DESTDIR}"
  fi
}

removeFiles() {
  printf "Removing extraneous files from %s/ (commonappdata and DOSBox/GOG files).\n" "${DESTDIR}";
  rm -rfv "${DESTDIR}"/commonappdata;
  find "${DESTDIR}" -iname "*goggame*" -exec rm -vf {} \;
  rm -vf "${DESTDIR}"/app/webcache.zip;
  rm -vf "${DESTDIR}"/app/GameuxInstallHelper.dll;
  rm -rvf "${DESTDIR}"/app/__support/
  if [[ -d "${DESTDIR}"/app/DOSBOX/ ]]; then
    rm -rvf "${DESTDIR}"/app/DOSBOX/;
  fi
  #Rename directory to game ID
  mv "${DESTDIR}"/app "${DESTDIR}"
}

createConfig() {
  touch "${EXDIR}/${DESTDIR}"/start.sh
  #GOG DOSBox configs tend to use relative paths and fail to start the game if don't start from a subdirectory. This replaces parent directory with current.
  sed -i "s/\.\./\./g" "$(find $"${EXDIR}/${DESTDIR}" -iname "dosbox*single.conf")"
  printf "dosbox -conf %s" "$(find $"${EXDIR}/${DESTDIR}" -iname "dosbox*single.conf")" > "${EXDIR}/${DESTDIR}"/start.sh
  chmod 755 "${EXDIR}/${DESTDIR}"/start.sh
}

testThings() {
  # Test variable assignment and other things
  printf "EXDIR = %s \n" "${EXDIR}"
  printf "DESTDIR = %s \n" "${DESTDIR}"
}


testThings
#innoextractCheck
extractFiles 
#removeFiles
#createConfig
checkGamedir
