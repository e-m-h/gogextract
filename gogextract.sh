#!/usr/bin/env bash

# Use innoextract to unpackage GOG games while removing extraneous files (e.g. DOSBox)
# Create appropriate directory using GOG ID (maybe capitalize and truncate to 8 characters)

# innoextract --exclude-temp


# unset -f command  # Not sure this is necessary

GAMEARCHIVE=${1}
EXDIR=${EXDIR:-${PWD}}
DESTDIR="${EXDIR}/$(innoextract --gog-game-id "${GAMEARCHIVE}" | cut -d '"' -f2 | head -n1 | tr -d " " | cut -c -8)"


innoextractCheck() {
   if [[ $(command -v innoextract) ]]; then
     printf "Innoextract found. Proceeding with extraction.\n"
   else
      if [[ $( uname -s ) == 'Linux' ]]; then
        case $( grep -h -E "^ID=|^ID_LIKE=" /etc/*release | awk -F"=" '{print $2} ') in
          Fedora|fedora)
            printf "Fedora found. Proceeding with innoextract install via yum. You may be prompted for your password.\n"
            sudo yum install innoextract
            ;;
          Debian|debian)
            printf "Debian found. Proceeding with innoextract install via apt. You may be prompted for your password.\n"
            sudo apt install innoextract
            ;;
          *)
            printf "Distribution not recognized. Exiting.\n"
            exit
            ;;
        esac
      fi
      # Darwin)
      #   printf "Using macOS, checking for Brew...\n";
      #     if [[ $(command -v brew) ]]; then 
      #       brew install innoextract
      #     else
      #       printf "Homebrew not found. Install Homebrew or innoextract to continue.";
      #       exit 
      #     fi
      #   ;;
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
  # We don't actually know where the DOSBox config files will be from package to package, so
  # find and move them before deleting things. Discard error output if we don't find DOSBox config(s). 
  printf "Moving DOSBox configuration files...\n"
  find "${DESTDIR}" -iname "dosbox*.conf" -exec mv {} "${DESTDIR}"/ \; 2>/dev/null

  printf "Removing extraneous files from %s/ (commonappdata and DOSBox/GOG files).\n" "${DESTDIR}";
  find "${DESTDIR}" -type f '(' -name "webcache.zip" -o -name "GameuxInstallHelper.dll" -o -name "goggame*" ')' -exec rm -rfv {} \; \
    2>/dev/null
  find "${DESTDIR}" -type d '(' -name "commonappdata" -o -name "__support" -o -name "__redist" ')' -exec rm -rfv {} \; 2>/dev/null

  if [[ -d "${DESTDIR}"/app/DOSBOX/ ]]; then
    rm -rvf "${DESTDIR}"/app/DOSBOX/;
  fi

  # If the game data is located within the 'app' subdirectory, move it to base directory
  if [[ $(ls ${DESTDIR}/app/ | wc -l ) -gt 10 ]]; then
    mv "${DESTDIR}"/app/* "${DESTDIR}/"
  fi

  # Remove the remaining 'app' directory
  rmdir "${DESTDIR}"/app/
}

createConfig() {
  touch "${DESTDIR}"/start.sh

  # GOG DOSBox configs tend to use relative paths and fail to start the game if don't start from a subdirectory. This replaces parent directory with current.
  sed -i "s/\.\./\./g" "$(find "${DESTDIR}" -iname "dosbox*single.conf")"
  printf "dosbox -conf %s" "$(find "${DESTDIR}" -iname "dosbox*single.conf")" > "${DESTDIR}"/start.sh
  chmod 755 "${DESTDIR}"/start.sh
}

testThings() {
  # Test variable assignment and other things
  printf "EXDIR = %s \n" "${EXDIR}"
  printf "DESTDIR = %s \n" "${DESTDIR}"
}


#testThings
innoextractCheck
# extractFiles 
# removeFiles
# createConfig

