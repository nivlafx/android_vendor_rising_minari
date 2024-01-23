# Copyright 2024 risingOS

# Function to download and extract the latest platform tools
function Download-And-Extract-Platform-Tools {
    Write-Host "Downloading the latest platform tools..."
    Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile 'platform-tools.zip'
    Expand-Archive -Path 'platform-tools.zip' -DestinationPath . -Force
    $env:PATH = "$($PWD)\platform-tools;$($env:PATH)"
}

# Function to display an error message for 10 seconds
function Display-Error-Message {
    param([string]$errorMessage)
    Write-Host "Error: $errorMessage"
    Start-Sleep -Seconds 10
    exit 1
}

# Function to check fastboot version and update if needed
function Check-Fastboot-Version {
    $fastbootOutput = & fastboot --version 2>&1

    # Display the full output of the fastboot command for debugging
    Write-Host "Fastboot command output: $fastbootOutput"

    # Extract the version from the output using regex
    $versionMatch = $fastbootOutput | Select-String -Pattern 'version (.+)$' -AllMatches
    if ($versionMatch.Matches.Count -gt 0) {
        $currentFastbootVersion = $versionMatch.Matches[0].Groups[1].Value
    } else {
        $currentFastbootVersion = $null
    }

    if (-not $currentFastbootVersion) {
        $errorMessage = "Unable to extract the current fastboot version. Exiting."
        Display-Error-Message -errorMessage $errorMessage
    }

    Write-Host "Current fastboot version: $currentFastbootVersion"

    # Define the target version as a string
    $targetVersion = "34.0.5-10900879"

    if ($currentFastbootVersion -eq $targetVersion) {
        Write-Host "Fastboot is up to date."
    } else {
        Write-Host "Fastboot is outdated; updating to version $targetVersion."
        Download-And-Extract-Platform-Tools

        $env:PATH = "$($PWD)\platform-tools;$($env:PATH)"

        # Verify that fastboot is now up to date
        $fastbootOutput = & fastboot --version 2>&1
        $versionMatch = $fastbootOutput | Select-String -Pattern 'version (.+)$' -AllMatches
        if ($versionMatch.Matches.Count -gt 0) {
            $currentFastbootVersion = $versionMatch.Matches[0].Groups[1].Value
        } else {
            $currentFastbootVersion = $null
        }

        if (-not $currentFastbootVersion -or $currentFastbootVersion -ne $targetVersion) {
            $errorMessage = "Error updating fastboot. Exiting."
            Display-Error-Message -errorMessage $errorMessage
        }

        Write-Host "Fastboot is now up to date."
    }
}

# Check the fastboot version and update if needed
Check-Fastboot-Version

# Function to check if the device is in fastboot mode
function Check-Fastboot-Mode {
    $fastbootOutput = fastboot devices

    if ($fastbootOutput -eq $null) {
        $warningMessage = "Unable to retrieve fastboot devices. Attempting to reboot to fastboot..."
        Write-Warning $warningMessage
        adb reboot-bootloader
        Start-Sleep -Seconds 5

        # Verify again after attempting to reboot
        $fastbootOutput = fastboot devices

        if ($fastbootOutput -eq $null) {
            $errorMessage = "Unable to retrieve fastboot devices after reboot. Exiting script..."
            Display-Error-Message -errorMessage $errorMessage
        }

        $currentMode = $fastbootOutput | Select-String "fastboot" -Quiet

        if ($currentMode) {
            Write-Host "Device is now in fastboot mode."
        } else {
            $errorMessage = "Device is still not in fastboot mode after reboot. Exiting script..."
            Display-Error-Message -errorMessage $errorMessage
        }
    } else {
        Write-Host "Device is in fastboot mode."
    }
}

# Check if the device is in fastboot mode
Check-Fastboot-Mode

# Specify desired versions
$desiredBootloaderVersion = "slider-1.3-10780582"
$desiredRadioVersion = "g5123b-125137-231014-b-10950115"

# Function to check the version of the bootloader
function Check-Bootloader-Version {
    $currentBootloaderVersion = (fastboot getvar version-bootloader 2>&1 | Select-String "version-bootloader").ToString().Split(":")[1].Trim()

    if ($currentBootloaderVersion -ne $desiredBootloaderVersion) {
        Write-Host "Flashing the latest bootloader..."
        fastboot flash bootloader "bootloader-raven-$desiredBootloaderVersion.img"
        fastboot reboot-bootloader
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Bootloader is already up to date. Skipping..."
    }
}

# Check the version of the bootloader and update it if outdated
Check-Bootloader-Version

# Function to check the version of the radio
function Check-Radio-Version {
    $currentRadioVersion = (fastboot getvar version-baseband 2>&1 | Select-String "version-baseband").ToString().Split(":")[1].Trim()

    if ($currentRadioVersion -ne $desiredRadioVersion) {
        Write-Host "Flashing the latest radio..."
        fastboot flash radio "radio-raven-$desiredRadioVersion.img"
        fastboot reboot-bootloader
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Radio is already up to date. Skipping..."
    }
}

# Check the version of the baseband and update it if outdated
Check-Radio-Version

# Install risingOS
Write-Host "About to install the latest version of risingOS..."
# Check if the user wants to wipe
$wipeOption = Read-Host "Do you want to wipe the device? (yes/no): "
if ($wipeOption.ToLower() -eq "yes") {
    Write-Host "Wiping the device and updating..."
    $updateResult = fastboot -w update "risingOS-OFFICIAL-BUNDLED-raven-fastboot.zip"
    if (-not $updateResult) {
        Display-Error-Message "Error updating risingOS. Exiting."
    }
} else {
    Write-Host "Updating without wiping the device..."
    $updateResult = fastboot update "risingOS-2.0-OFFICIAL-BUNDLED-raven-fastboot.zip"
    if (-not $updateResult) {
        Display-Error-Message "Error updating risingOS. Exiting."
    }
}

# Check if the update was successful
if ($updateResult) {
    Write-Host "Script completed successfully."
    Pause
    exit 0
}
