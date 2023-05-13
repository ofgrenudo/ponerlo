<#
    Ignore any untrusted ssl/tls certs.
#>
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

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

<#
    This function will read through an existing .env file and return a hashmap containing each of the values present
    in the .env file.
#>
function Get-EnvironmentVariables { 
    $environment_variables = @{}

    Get-Content .env | ForEach-Object {
        $name, $value = $_.split('=')
        if ([string]::IsNullOrWhiteSpace($name) -Or $name.Contains('#')) {
            continue
        }
        $environment_variables.add($name, $value)
    }
    return $environment_variables
}

<#
    This function will go through the .env hashtable returned and print each of the values out to the console.
#>
function Test-GetEnvironmentVariables {
    $my_env = Get-EnvironmentVariables
    foreach ($sub_env in $my_env.GetEnumerator() ) {
        Write-Host "$($sub_env.Name) : $($sub_env.Value)"
    }
}

<#
    This device will make a get request to your SnipeIT infrastructure point and will query for a devcie with the provided serial number.
    if the device does exists. It will return an object, with existing information from the Snipe Inventory. If the device does not exist, 
    it will return, a error value.
    
    Snipe-IT API Documentation: https://snipe-it.readme.io/reference/hardware-by-serial
#>
function Get-DeviceFromSnipeWithSN([string]$serial_number) {
    $my_env = Get-EnvironmentVariables

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/hardware/byserial/" + $serial_number + "?deleted=false"
 
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers
    $response = $response | ConvertFrom-Json  

    return $response
}

function Test-GetWithBadSN {
    $response_from_snipe = Get-DeviceFromSnipeWithSN("234215131242")
    if ($response_from_snipe.status) { Write-Host $response_from_snipe.messages }
}

function Test-GetWithGoodSN {
    $my_device = Get-DeviceInformation
    $response_from_snipe = Get-DeviceFromSnipeWithSN($my_device.serial_number)
    if ($response_from_snipe.status) { Write-Host $response_from_snipe.messages }

    $response_from_snipe.rows[0] | Format-Table
}

function Get-DeviceFromSnipeWithAT([string]$asset_tag) {
    $my_env = Get-EnvironmentVariables

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/hardware/bytag/" + $asset_tag + "?deleted=false"
 
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers
    $response = $response | ConvertFrom-Json  

    return $response
}

function Test-GetWithBadAT {
    $response_from_snipe = Get-DeviceFromSnipeWithAT("987654321")
    if ($response_from_snipe.status) { Write-Host $response_from_snipe.messages }
}

function Test-GetWithGoodAT {
    $my_device = Get-DeviceInformation
    $response_from_snipe = Get-DeviceFromSnipeWithAT($my_device.asset_tag)
    if ($response_from_snipe.status) { Write-Host $response_from_snipe.messages }
    else {
        $response_from_snipe
    }
}

function Get-Models {
    $my_env = Get-EnvironmentVariables

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/models" + $asset_tag
 
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers
    $response = $response | ConvertFrom-Json  

    return $response
}

function Get-MyModelID([string]$my_model) {
    $response_from_snipe = Get-Models

    $max = $response_from_snipe.total
    $i = 0
    While ($i -le $max) {
        if ($response_from_snipe.rows[$i].name -eq $my_model) {
            return $response_from_snipe.rows[$i].id
        }
        # Write-Host "ID: " $response_from_snipe.rows[$i].id " Model: " $response_from_snipe.rows[$i].name "`t| Looking For: " $my_device.model
        $i = $i + 1
    }
}

function Test-GetModels {
    $my_device = Get-DeviceInformation
    $response_from_snipe = Get-Models

    $max = $response_from_snipe.total
    $i = 0
    While ($i -le $max) {
        if ($response_from_snipe.rows[$i].name -eq $my_device.model) {
            Write-Host "Model ID:" + $response_from_snipe.rows[$i].id
        }
        Write-Host "ID: " $response_from_snipe.rows[$i].id " Model: " $response_from_snipe.rows[$i].name "`t| Looking For: " $my_device.model
        $i = $i + 1
    }
}

function New-Model([string]$new_model) {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/models" + $asset_tag

    $postParams = @{name=$my_device.model; category_id=0; manufacture_id=0}
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $postParams
    $response = $response | ConvertFrom-Json  

    return $response
}

function Test-AllFunctions { 
    # Test-GetEnvironmentVariables
    # Write-Host("="*100)
    # Test-GetDeviceInformation
    # Write-Host("="*100)
    # Test-GetWithBadSN
    # Write-Host("="*100)
    # Test-GetWithGoodSN    
    # Write-Host("="*100)
    # Test-GetWithBadAT
    # Write-Host("="*100)
    # Test-GetWithGoodAT
    Write-Host("="*100)
    # Get-Models
    # Test-GetModels
    Get-MyModelID("Latitude")
}

Test-AllFunctions