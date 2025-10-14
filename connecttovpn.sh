#!/bin/bash
set -x

# Admin check (ensure script is run as root)
if [ "$EUID" -ne 0 ]; then
  echo "Restarting script as root..."
  sudo --preserve-env=VPN_USER --preserve-env=VPN_PASS --preserve-env=HTWG_TOTP_SECRET "$0" "$@"
  exit
fi

# Determine working directory, important when called via symlink
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
workingDir="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
# Paths
pathToConfigFile="$workingDir/HTWG-MFA-WS2526-STUD.ovpn"
pathToPythonScript="$workingDir/getotp.py"
logFile="$workingDir/vpn_log.txt"

# Environment variables
userName="$VPN_USER"
password="$VPN_PASS"
pathToPython="python3"

# OTP generation
passwordExtension="$($pathToPython "$pathToPythonScript" $HTWG_TOTP_SECRET 2>> "$logFile")"
echo "OTP: $passwordExtension"

if [ $? -ne 0 ]; then
  echo "[ERROR] OTP generation failed." >> "$logFile"
  exit 1
fi
passwordExtension="$(echo "$passwordExtension" | xargs)"

# Write auth file
if [ $? -ne 0 ]; then
  echo "[ERROR] Writing auth file failed." >> "$logFile"
  exit 1
fi

echo "$userName\n$password$passwordExtension"

# Start OpenVPN connection
openvpn --config "$pathToConfigFile" --auth-user-pass <(echo -e "$userName\n$password$passwordExtension")
if [ $? -ne 0 ]; then
  echo "[ERROR] OpenVPN connection failed." >> "$logFile"
  exit 1
fi

echo "Script execution finished. Press any key to exit."