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

    try {
        $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
        $device.asset_tag = $tsenv.Value("OSDAssetTag")        
    }
    catch {
        $device.asset_tag = $bios_information.SMBIOSAssetTag # We will have to check two places, bios, and MECM task sequence.
    }
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
        $environment_variables.add($name.Trim(), $value.Trim())
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

<#
    This will test Get-DeviceFromSnipeWithSN by providing it a bad Serial Number.
#>
function Test-GetWithBadSN {
    $response_from_snipe = Get-DeviceFromSnipeWithSN("234215131242")
    if ($response_from_snipe.status) { Write-Host $response_from_snipe.messages }
}

<#
    This will test Get-DeviceFromSnipeWithAT by providing it a bad Serial Number.
#>
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
    $my_device = Get-DeviceInformation
    $response = Get-Models

    $max = $response.total 
    $i = 0
    While ($i -le $max) {
        if ($response.rows[$i].name -eq $my_device.model) {
            # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name
            return $response.rows[$i].id            
        }
        # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name "`t`tMatching: "      $my_device.model
        $i = $i + 1
    }
    
    Write-Host "Could not find " $my_device.make "`nCreating now..."
    New-Model
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

    $postParams = @{name=$my_device.model; category_id=Get-CategoryID; manufacture_id=Get-ManufactureID}
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $postParams
    $response = $response | ConvertFrom-Json  

    return $response
}

function New-CategoryID {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/categories" + $asset_tag

    $postParams = @{name=$my_env.snipe_category_name; category_type="asset";}
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $postParams
    $response = $response | ConvertFrom-Json  
    return $response
}

function Get-CategoryID {
    $my_env = Get-EnvironmentVariables

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/categories" + $asset_tag
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers
    $response = $response | ConvertFrom-Json  

    $max = $response.total
    $i = 0
    While ($i -le $max) {
        if ($response.rows[$i].name -eq $my_env.snipe_category_name) {
            # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name
            return $response.rows[$i].id            
        }
        # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name "`t`tMatching: "      $my_env.snipe_category_name
        $i = $i + 1
    }
    
    Write-Host "Could not find " $my_env.snipe_category_name "`nCreating now..."
    New-CategoryID
    Write-Error "Please run the script again..."
}

function New-Manufacturer {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/manufacturers" + $asset_tag

    $postParams = @{name=$my_device.make}
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $postParams
    $response = $response | ConvertFrom-Json  
    return $response
}

function Get-ManufactureID {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/manufacturers" + $asset_tag
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers
    $response = $response | ConvertFrom-Json  

    $max = $response.total 
    $i = 0
    While ($i -le $max) {
        if ($response.rows[$i].name -eq $my_device.make) {
            # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name
            return $response.rows[$i].id            
        }
        # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name "`t`tMatching: "      $my_device.make
        $i = $i + 1
    }
    
    Write-Host "Could not find " $my_device.make "`nCreating now..."
    New-Manufacturer
    Write-Error "Please run the script again..."
}

function New-Status {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/statuslabels" + $asset_tag

    $postParams = @{name=$my_env.snipe_status_label;type=$my_env.snipe_status_type}
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $postParams
    $response = $response | ConvertFrom-Json  
    return $response
}

function Get-StatusID {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    $uri = $my_env.snipe_root_url + "api/v1/statuslabels" + $asset_tag
    $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers
    $response = $response | ConvertFrom-Json  

    $max = $response.total 
    $i = 0
    While ($i -le $max) {
        if ($response.rows[$i].name -eq $my_env.snipe_status_label) {
            # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name
            return $response.rows[$i].id            
        }
        # Write-Host "ID: " $response.rows[$i].id "`tName: " $response.rows[$i].name
        $i = $i + 1
    }

    Write-Host "Could not find " $my_env.snipe_status_label "`nCreating now..."
    New-Status
    Write-Error "Please run the script again..."
}

function Update-Snipe {
    $my_env = Get-EnvironmentVariables
    $my_device = Get-DeviceInformation

    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("content-type", "application/json")
    $headers.Add("Authorization", "Bearer " + $my_env.snipe_api_key)

    # Do I Exist?
    $snipe_device = Get-DeviceFromSnipeWithAT($my_device.asset_tag)
    if($snipe_device.status) {      # No
        Write-Host "Device does not exist with AT " $my_device.asset_tag
    } else {                        # Yes
        Write-Host "Device exists with associated AT. Updating now..."
        $uri = $my_env.snipe_root_url + "api/v1/hardware/" + $snipe_device.id

        $patchParams = @{asset_tag=$my_device.asset_tag; model_id=Get-MyModelID; serial=$my_device.serial_number; name=$my_device.computer_name} | ConvertTo-Json
        $json_body = @{
            serial= $my_device.serial_number
            name= $my_device.computer_name
            asset_tag= $my_device.asset_tag
            status_id= Get-StatusID
            model_id= Get-MyModelID
        }

        $json_body = $json_body | ConvertTo-Json

        $response = Invoke-WebRequest -Uri $uri -Method PATCH -Headers $headers -ContentType 'application/json' -Body $json_body
        $response = $response | ConvertFrom-Json  
        Write-Host "Successfully updated device with the following information"
        Write-Host $json_body

        # Set variables to indicate value and key to set
        $RegistryPath = 'HKLM:\Software\Ponerlo\'
        $Name         = 'Completed'
        $Value        = '1'
        # Create the key if it does not exist
        If (-NOT (Test-Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }  
        # Now set the value
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force
        break
    }

    # Do I Exist?
    $snipe_device = Get-DeviceFromSnipeWithSN($my_device.serial_number)
    if($snipe_device.status) {      # No
        Write-Host "Device does not exist with SN " $my_device.serial_number
    } else {                        # Yes
        Write-Host "Device exists with associated SN. Updating now..."

        $uri = $my_env.snipe_root_url + "api/v1/hardware/" + $snipe_device.rows[0].id

        $patchParams = @{asset_tag=$my_device.asset_tag; model_id=Get-MyModelID; serial=$my_device.serial_number; name=$my_device.computer_name} | ConvertTo-Json
        $json_body = @{
            serial= $my_device.serial_number
            name= $my_device.computer_name
            asset_tag= $my_device.asset_tag
            status_id= Get-StatusID
            model_id= Get-MyModelID
        }

        $json_body = $json_body | ConvertTo-Json

        $response = Invoke-WebRequest -Uri $uri -Method PATCH -Headers $headers -ContentType 'application/json' -Body $json_body
        $response = $response | ConvertFrom-Json  

        Write-Host "Successfully updated device with the following information"
        Write-Host $json_body

        # Set variables to indicate value and key to set
        $RegistryPath = 'HKLM:\Software\Ponerlo\'
        $Name         = 'Completed'
        $Value        = '1'
        # Create the key if it does not exist
        If (-NOT (Test-Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }  
        # Now set the value
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force
        break
    }

    if($snipe_device.status) {
        Write-Host "Creating new device now..."

        $uri = $my_env.snipe_root_url + "api/v1/hardware"

        $patchParams = @{asset_tag=$my_device.asset_tag; model_id=Get-MyModelID; serial=$my_device.serial_number; name=$my_device.computer_name} | ConvertTo-Json
        $json_body = @{
            serial= $my_device.serial_number
            name= $my_device.computer_name
            asset_tag= $my_device.asset_tag
            status_id= Get-StatusID
            model_id= Get-MyModelID
        }

        $json_body = $json_body | ConvertTo-Json

        $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -ContentType 'application/json' -Body $json_body
        $response = $response | ConvertFrom-Json  

        Write-Host "Successfully created device with the following information"
        Write-Host $json_body

        # Set variables to indicate value and key to set
        $RegistryPath = 'HKLM:\Software\Ponerlo\'
        $Name         = 'Completed'
        $Value        = '1'
        # Create the key if it does not exist
        If (-NOT (Test-Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }  
        # Now set the value
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force
        break
    }
}

Update-Snipe
