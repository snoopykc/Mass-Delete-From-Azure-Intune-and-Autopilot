Import-Module AzureAD
Import-Module ImportExcel
Import-Module Microsoft.Graph.Intune
import-module WindowsAutopilotIntune


# Load the Excel file containing the list of serial numbers to delete
$excelFilePath = "C:\Test\test.xlsx"
$excelData = Import-Excel $excelFilePath

# Connect to Intune
Connect-MsGraph
Connect-AzureAD

# Delete devices from Intune
foreach ($serialNumber in $excelData.SerialNumber) {
    $deviceId = Get-IntuneManagedDevice | Where-Object { $_.SerialNumber -eq $serialNumber } | Select-Object -ExpandProperty id
    if ($deviceId) {
        Write-Host "Deleting device with serial number $serialNumber from Intune..."
        Remove-IntuneManagedDevice -DeviceId $deviceId -Confirm:$false
    } else {
        Write-Host "Device with serial number $serialNumber not found in Intune."
    }
}

# Delete devices from Autopilot
foreach ($serialNumber in $excelData.SerialNumber) {
    $devices = Get-AutopilotDevice
    $device = $devices | Where-Object { $_.serialNumber -eq $serialNumber }
    if ($device) {
        try {
            Write-Host "Deleting device with serial number $serialNumber from Autopilot..."
            Remove-AutopilotDevice -Id $device.id
        } catch {
            Write-Host "Error deleting device with serial number $serialNumber from Autopilot: $_"
        }
    } else {
        Write-Host "Device with serial number $serialNumber not found in Autopilot."
    }
}

# Delete devices from Azure AD
foreach ($serialNumber in $excelData.SerialNumber) {
    $deviceId = (Get-AzureADDevice | Where-Object { $_.DevicePhysicalIds -contains $serialNumber }).ObjectId
    if ($deviceId) {
        Write-Host "Deleting device with serial number $serialNumber from Azure AD..."
        Remove-AzureADDevice -ObjectId $deviceId
    } else {
        Write-Host "Device with serial number $serialNumber not found in Azure AD."
    }
}
