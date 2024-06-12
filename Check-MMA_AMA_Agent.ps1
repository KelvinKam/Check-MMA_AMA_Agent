# Script for scanning MMA and AMA agent
# Made by Kelvin Kam (GSIM)
# Version 2024-6-7

$azSubs = Get-AzSubscription

foreach ( $azSub in $azSubs ) {
    Set-AzContext -Subscription $azSub | Out-Null
    $azSubName = $azSub.Name
    $azSubName = $azSubName.replace("/","-")

    $all_workspace = Get-AzOperationalInsightsWorkspace
    $VMs = Get-AzVM
    #$WindowsVMs = $VMs | Where-Object { $PSItem.StorageProfile.OSDisk.OSType -eq "Windows" }

    foreach ($VM in $VMs) {

        $MicrosoftMonitoringAgent = $false
        $MicrosoftMonitoringAgentProvisioningState = $null
        $AzureMonitorWindowsAgent = $false
        $AzureMonitorWindowsAgentProvisioningState = $null
        $AzureMonitorLinuxAgent = $false
        $AzureMonitorLinuxAgentProvisioningState = $null
        $MMAWorkspace = $null
        [Int32]$i = 0

        $Extension = Get-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name
        if ($extension.Name -contains "MicrosoftMonitoringAgent" -or $extension.Name -contains "MMAExtension" -or $extension.Name -like "OmsAgent*") {
            $MicrosoftMonitoringAgent = $true

            #$MicrosoftMonitoringAgentProvisioningState = ($extension | Where-Object {$_.Name -eq "MicrosoftMonitoringAgent"} | select ProvisioningState).ProvisioningState
            $MicrosoftMonitoringAgentProvisioningState = ($extension | Where-Object {$_.Name -contains "MicrosoftMonitoringAgent" -or $extension.Name -contains "MMAExtension" -or $extension.Name -like "OmsAgent*"} | select ProvisioningState).ProvisioningState
            if($MicrosoftMonitoringAgentProvisioningState -contains "Failed"){
                $MicrosoftMonitoringAgentProvisioningState = "Failed"
            }else{
                $MicrosoftMonitoringAgentProvisioningState = "Succeeded"
            }

            $workspace_id = ($Extension.PublicSettings | ConvertFrom-Json -ErrorAction SilentlyContinue).workspaceId | Select-Object -First 1

            #$workspace_id
            foreach($w in $all_workspace){
                if($w.CustomerId.Guid -eq $workspace_id){ 
                        #here, I just print out the vm name and the connected Log Analytics workspace name
                        $MMAWorkspace = $($w.name)
                    }
            }


        }

        if ($extension.Name -contains "AzureMonitorWindowsAgent") {
            $AzureMonitorWindowsAgent = $true
            $AzureMonitorWindowsAgentProvisioningState = ($extension | Where-Object {$_.Name -eq "AzureMonitorWindowsAgent"} | select ProvisioningState).ProvisioningState
        }

        if ($extension.Name -contains "AzureMonitorLinuxAgent") {
            $AzureMonitorLinuxAgent = $true
            $AzureMonitorLinuxAgentProvisioningState = ($extension | Where-Object {$_.Name -eq "AzureMonitorLinuxAgent"} | select ProvisioningState).ProvisioningState
        }

        $Result = [PSCustomObject]@{
            'Subscription' = $azSubName
            'VM Name'= $vm.Name
            'VM RG' = $vm.ResourceGroupName 
            'MMA' = $MicrosoftMonitoringAgent
            'MMA_PS' = $MicrosoftMonitoringAgentProvisioningState
            'MMA_Workspace' = $MMAWorkspace
            'AMA-Windows' = $AzureMonitorWindowsAgent
            'AMA-Windows_PS' = $AzureMonitorWindowsAgentProvisioningState
            'AMA-Linux' = $AzureMonitorLinuxAgent
            'AMA-Linux_PS' = $AzureMonitorLinuxAgentProvisioningState
        }

        #$Result | Export-Csv -Path "$($home)\clouddrive\VM-MMA-AMA-AgentStatus.csv" -NoTypeInformation -Append -force
        $Result | Export-Csv -Path "VM-MMA-AMA-AgentStatus.csv" -NoTypeInformation -Append -force
    }
}