<#This script will import the sbc VM and configure the skeleton.
Created on 2020/04/06 by Louis-Philippe Descamps
Dependency: have the source VM on the local drive and adjust the variables below.

Handy command to check config
Get-NetLbfoTeam
Get-NetLbfoTeamMember
Get-NetLbfoTeamNic
Get-NetAdapter
Get-NetAdapter -Name "*" -IncludeHidden | Format-List -Property "Name", "InterfaceDescription", "InterfaceName"
Get-VMNetworkAdapter -VMName $VMname -Name $corp
Get-Variable

0. variables#>
$Source = "C:\AudioCodes\sbc\sbc-F7.20A.156.028 - HyperV\sbc-F7.20A.156.028 - HyperV\Virtual Machines\B527B136-BA3B-42F3-896C-4D8ADF058302.XML"
$SnapshotFilePath = "C:\Datastore\VirtualMachines\AudioCodes_SBC\Checkpoint"
$VirtualMachinePath = "C:\Datastore\VirtualMachines\AudioCodes_SBC\Virtual Machines"
$SmartPagingFilePath = "C:\Datastore\VirtualMachines\AudioCodes_SBC\PagingFile"
$VhdSourcePath = "C:\AudioCodes\sbc\sbc-F7.20A.156.028 - HyperV\sbc-F7.20A.156.028 - HyperV\Virtual Hard Disks"
$VhdDestinationPath = "C:\Datastore\VirtualMachines\AudioCodes_SBC\Virtual Hard Disks"
$hostname = "Server1"
$Location ="EUBEBXL"
$VMname = "$($Location)_ACSBC-vm"
$corp_host_vlan = "1"
$corp_sbc_vlan = "2"
$corp_ha_vlan = "3"
$corp_Inet_vlan = "4"
$corp_pstn_vlan = "5"
$corp = "$($Location)_CorpDMZ_VL$($corp_sbc_vlan)-$($corp_host_vlan)_1"
$corp_sbc = "$($Location)_CorpDMZ_VL$($corp_sbc_vlan)_1"
$corp_host = "$($Location)_CorpDMZ_VL$($corp_host_vlan)_1"
$ha = "$($Location)_HASBC_VL$($corp_ha_vlan)_2"
$Inet = "$($Location)_InetDMZ_VL$($corp_Inet_vlan)_3"
$pstn = "$($Location)_PSTN_VL$($corp_pstn_vlan)_4"
$IP = "192.168.1.2"
$Mask = "24"
$GW = "192.168.1.1"

#1. Create dummy vswitch
New-VMSwitch "Virtual Switch 1" -SwitchType Private

#2. import the VM
Import-VM -Path $Source -SnapshotFilePath $SnapshotFilePath -VirtualMachinePath $VirtualMachinePath -SmartPagingFilePath $SmartPagingFilePath -VhdSourcePath $VhdSourcePath -VhdDestinationPath $VhdDestinationPath -Copy -GenerateNewId

#3. Remove unused virtual network adapter
Remove-VMNetworkAdapter -VMName sbc-F* -VMNetworkAdapterName *

#4. remove dummy vswitch and OSN
Remove-VMSwitch "Virtual Switch 1" -Force
Remove-VMSwitch "InternalIf OSN" -Force

#5. rename vm
Rename-VM sbc-F* -NewName $VMname

#6. create virtual network adapter for the vm
Add-VMNetworkAdapter -VMName $VMname -Name "$($corp)-vn" -SwitchName "$($corp)-vs"
Add-VMNetworkAdapter -VMName $VMname -Name "$($ha)-vn" -SwitchName "$($ha)-vs"
Add-VMNetworkAdapter -VMName $VMname -Name "$($Inet)-vn" -SwitchName "$($Inet)-vs"
Add-VMNetworkAdapter -VMName $VMname -Name "$($pstn)-vn" -SwitchName "$($pstn)-vs"
Set-VMNetworkAdapterVlan -VMName $VMname -VMNetworkAdapterName "$($corp)-vn" -Access -VlanId $corp_sbc_vlan

#6. add cpu
Set-VMProcessor $VMname -Count 4

#7. set VMNetworkAdapter mac to static
Start-VM -Name $VMname
Start-Sleep -s 2
Stop-VM -Name $VMname -Force
$corpMACAddress = (Get-VMNetworkAdapter -VMName $VMname -Name "$($corp)-vs").MacAddress
Set-VMNetworkAdapter -VMName $VMname -Name "$($corp)-vs" -StaticMacAddress $corpMACAddress
$haMACAddress = (Get-VMNetworkAdapter -VMName $VMname -Name "$($ha)-vs").MacAddress
Set-VMNetworkAdapter -VMName $VMname -Name "$($ha)-vs" -StaticMacAddress $haMACAddress
$InetMACAddress = (Get-VMNetworkAdapter -VMName $VMname -Name "$($Inet)-vs").MacAddress
Set-VMNetworkAdapter -VMName $VMname -Name "$($Inet)-vs" -StaticMacAddress $InetMACAddress
$pstnMACAddress = (Get-VMNetworkAdapter -VMName $VMname -Name "$($pstn)-vs").MacAddress
Set-VMNetworkAdapter -VMName $VMname -Name "$($pstn)-vs" -StaticMacAddress $pstnMACAddress
