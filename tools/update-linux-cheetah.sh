#!/bin/sh

# Copyright 2024 risingOS

# Function to download and extract the latest platform tools
download_platform_tools() {
  echo "Downloading the latest platform tools..."
  wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip || return 1
  unzip -q platform-tools-latest-linux.zip
  export PATH=$(pwd)/platform-tools:$PATH
}

# Function to display an error message for 10 seconds
display_error_message() {
  error_message=$1
  echo "Error: $error_message"
  sleep 10
}

# Check if fastboot is at least version 34.0.5
check_fastboot_version() {
  current_fastboot_version=$($(which fastboot) --version | grep "version" | cut -c18-23 | sed 's/\.//g')
  if [ "$current_fastboot_version" -ge 3405 ]; then
    echo "fastboot is up to date."
  else
    error_message="Fastboot is too old; the latest version will be downloaded."
    download_platform_tools || { display_error_message "$error_message"; exit 1; }
    export PATH=$(pwd)/platform-tools:$PATH
    # Verify that fastboot is now up to date
    current_fastboot_version=$($(which fastboot) --version | grep "version" | cut -c18-23 | sed 's/\.//g')
    if [ "$current_fastboot_version" -ge 3405 ]; then
      echo "Fastboot is now up to date."
    else
      error_message="Error updating fastboot. Exiting."
      display_error_message "$error_message"
      exit 1
    fi
  fi
}

# Check fastboot version and update if needed
check_fastboot_version

# Function to check if the device is in bootloader mode
check_fastboot_mode() {
  current_mode=$(fastboot devices 2>&1 | awk '{print $2}')
  if [ "$current_mode" = "fastboot" ]; then
    echo "Device is in fastboot mode."
  else
    error_message="Device is not in fastboot mode. Rebooting to fastboot..."
    display_error_message "$error_message"
    adb reboot-bootloader
    sleep 5
    # Verify again after rebooting
    current_mode=$(fastboot devices 2>&1 | awk '{print $2}')
    if [ "$current_mode" = "fastboot" ]; then
      echo "Device is now in fastboot mode."
    else
      error_message="Error: Device is still not in fastboot mode. Exiting."
      display_error_message "$error_message"
      exit 1
    fi
  fi
}

# Check if the device is in bootloader mode
check_fastboot_mode

# Specify desired versions
desired_bootloader_version="cloudripper-14.0-10825040"
desired_radio_version="g5300q-230927-231102-B-11040898"

# Function to check the version of the bootloader
check_bootloader_version() {
  current_bootloader_version=$(fastboot getvar version-bootloader 2>&1 | awk -F": " '/version-bootloader:/ {print $2}')
  if [ "$current_bootloader_version" = "$desired_bootloader_version" ]; then
    echo "Bootloader is already up to date. Skipping..."
    return 1
  fi
}

# Function to check the version of the radio
check_radio_version() {
  current_radio_version=$(fastboot getvar version-baseband 2>&1 | awk -F": " '/version-baseband:/ {print $2}')
  if [ "$current_radio_version" = "$desired_radio_version" ]; then
    echo "Radio is already up to date. Skipping..."
    return 1
  fi
}

# Check and update bootloader
if check_bootloader_version; then
  echo "Flashing the latest bootloader..."
  fastboot flash bootloader bootloader-cheetah-$desired_bootloader_version.img || { error_message="Error flashing bootloader. Exiting."; display_error_message "$error_message"; exit 1; }
  fastboot reboot-bootloader
  sleep 5
fi

# Check and update radio
if check_radio_version; then
  echo "Flashing the latest radio..."
  fastboot flash radio radio-cheetah-$desired_radio_version.img || { error_message="Error flashing radio. Exiting."; display_error_message "$error_message"; exit 1; }
  fastboot reboot-bootloader
  sleep 5
fi

# Install risingOS
echo "About to install the latest version of risingOS..."
# Check if the user wants to wipe
read -p "Do you want to wipe the device? (yes/no): " wipe_option

if [ "$wipe_option" = "yes" ]; then
  echo "Wiping the device and updating..."
  fastboot -w update risingOS-2.0-OFFICIAL-BUNDLED-cheetah-fastboot.zip || { error_message="Error updating risingOS. Exiting."; display_error_message "$error_message"; exit 1; }
else
  echo "Updating without wiping the device..."
  fastboot update risingOS-2.0-OFFICIAL-BUNDLED-cheetah-fastboot.zip || { error_message="Error updating risingOS. Exiting."; display_error_message "$error_message"; exit 1; }
fi

echo "Script completed successfully."

