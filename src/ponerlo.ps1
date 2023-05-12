<#
    Get-DeviceInformation indexes your computer and generates a object that contians
        - computer_name (Hostname)
        - make (The devices Manufacturer)
        - model 
        - serial_number
        - asset_tag
#>
function Get-DeviceInformation {
    $system_information = Get-CimInstance -ClassName Win32_ComputerSystem
    # Contains Name (Host Name), PrimaryOwnerName, Domain, Model, Manufacture

    $bios_information   = Get-CimInstance -ClassName Win32_SystemEnclosure
    # Contains Manufacture, SerialNumber SMBIOSAssetTag

    $device = @{}

    $device.computer_name = $system_information.Name
    $device.make = $system_information.Manufacturer
    $device.model = $system_information.Model
    $device.serial_number = $bios_information.SerialNumber
    $device.asset_tag = $bios_information.SMBIOSAssetTag # We will have to check two places, bios, and MECM task sequence.

    return $device
}

<#
    This function tests the Get-DeviceInformation function by returning values to the console for a human inspection.
    TODO: Assert values not null? Im not sure how to make this a proper test.
#>
function Test-GetDeviceInformation { 
    $device = Get-DeviceInformation
    Write-Host $device.computer_name
    Write-Host $device.make
    Write-Host $device.model
    Write-Host $device.serial_number
    Write-Host $device.asset_tag
}