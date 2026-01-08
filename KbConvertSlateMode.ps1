$Targets = @(                               # The device IDs
    "HID\VID_0123&PID_0123&MI_00",
    "HID\VID_4567&PID_4567"
)

$script:LastHID   = $null                   # Remembers whether the device was plugged in last time
$script:LastSlate = $null                   # Remembers what mode Windows was in last time

function DevicePresence {                   # Checks if the device is currently plugged in
    $devices = Get-PnpDevice -PresentOnly
    foreach ($t in $Targets) {
        if ($devices.InstanceId -like "*$t*") {
            return $true
        }
    }
    return $false
}

function SlateModeValue {                   # Reads whether Windows is in tablet mode or laptop mode
    (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl").ConvertibleSlateMode
}

function SetSlateMode($value) {             # Tells Windows to switch to tablet mode (0) or laptop mode (1)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ConvertibleSlateMode /t REG_DWORD /d $value /f | Out-Null
}

function MonitorHID {                       # Watches for the device being plugged in or unplugged
    Register-WmiEvent -Class Win32_DeviceChangeEvent -SourceIdentifier "HIDWatch" | Out-Null
}

function MonitorSlate {                     # Watches for Windows changing tablet/laptop mode
    Register-WmiEvent -Query "
        SELECT * FROM RegistryValueChangeEvent
        WHERE Hive='HKEY_LOCAL_MACHINE'
        AND KeyPath='SYSTEM\\CurrentControlSet\\Control\\PriorityControl'
        AND ValueName='ConvertibleSlateMode'
    " -SourceIdentifier "SlateWatch" | Out-Null
}

$currentHID   = DevicePresence              # Get the current device status and mode before starting
$currentSlate = SlateModeValue

Write-Host "[WATCH] initializing hid presence & slatemode value"

$script:LastHID   = $currentHID
$script:LastSlate = $currentSlate

if ($currentHID) {                          # Pick the correct mode based on whether the device is plugged in right now
    Write-Host "  [HID] present      > initializing laptop mode"
    SetSlateMode 1
} else {
    Write-Host "  [HID] absent       > initializing tablet mode"
    SetSlateMode 0
}

MonitorHID
MonitorSlate

while ($true) {                             # Loop forever, waiting for Windows to report changes

    $event = Wait-Event

    switch ($event.SourceIdentifier) {

        "HIDWatch" {                        # Runs whenever the device is plugged in or unplugged

            $newHID = DevicePresence

            if ($newHID -ne $script:LastHID) {
                Write-Host "[WATCH] hid presence change detected"

                if ($newHID) {
                    Write-Host "  [HID] connected    > entering laptop mode"
                    SetSlateMode 1
                } else {
                    Write-Host "  [HID] disconnected > entering tablet mode"
                    SetSlateMode 0
                }

                $script:LastHID = $newHID
            }
        }

        "SlateWatch" {                      # Runs whenever Windows changes the mode setting

            $newSlate = SlateModeValue

            if ($newSlate -ne $script:LastSlate) {
                Write-Host "[WATCH] slate value change detected"
            }

            if ($script:LastHID -eq $true -and $newSlate -eq 0) {
                Write-Host "[SLATE] overridden   > restoring laptop mode"
                SetSlateMode 1
                $newSlate = 1
            }

            $script:LastSlate = $newSlate
        }
    }

    Remove-Event -EventIdentifier $event.EventIdentifier

}
