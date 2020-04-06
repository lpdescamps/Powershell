<#This script will configure the Hyper-V server.
Created on 2020/04/06 by Louis-Philippe Descamps

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

#1. Remove all Teams (if any)
Remove-NetLbfoTeam -Name *

#2. free up all eth
Set-VMSwitch * -SwitchType Internal

#3. Create new Teams

New-NetLbfoTeam -Name "$($corp)-tm" -TeamMembers "NIC1","NIC5" -TeamingMode LACP -LoadBalancingAlgorithm Dynamic -Confirm:$false
New-NetLbfoTeam -Name "$($ha)-tm" -TeamMembers "NIC8","NIC4" -TeamingMode LACP -LoadBalancingAlgorithm Dynamic -Confirm:$false
New-NetLbfoTeam -Name "$($Inet)-tm" -TeamMembers "NIC6","NIC2" -TeamingMode LACP -LoadBalancingAlgorithm Dynamic -Confirm:$false
New-NetLbfoTeam -Name "$($pstn)-tm" -TeamMembers "NIC7","NIC3" -TeamingMode LACP -LoadBalancingAlgorithm Dynamic -Confirm:$false

#4. Create Nic Team Interfaces
Add-NetLbfoTeamNIC -Team "$($corp)-tm" -VlanID $corp_sbc_vlan
Add-NetLbfoTeamNIC -Team "$($corp)-tm" -VlanID $corp_host_vlan

#5. Create Vitrual Switches
New-VMSwitch "$($corp_sbc)-vs" -NetAdapterName "$($corp)-tm - VLAN $corp_sbc_vlan" -AllowManagementOS $false
New-VMSwitch "$($corp_host)-vs" -NetAdapterName "$($corp)-tm - VLAN $corp_host_vlan" -AllowManagementOS $true
New-VMSwitch "$($ha)-vs" -NetAdapterName "$($ha)-tm" -AllowManagementOS $false
New-VMSwitch "$($Inet)-vs" -NetAdapterName "$($Inet)-tm" -AllowManagementOS $false
New-VMSwitch "$($pstn)-vs" -NetAdapterName "$($pstn)-tm" -AllowManagementOS $false
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "$($corp_host)-vs" -Access -VlanID $corp_host_vlan -ManagementOS

#5. Assign Hyper-V IP
New-NetIPAddress -InterfaceAlias "vEthernet ($($corp)-vs)" -IPAddress $IP -PrefixLength $Mask -DefaultGateway $GW

#6. Change Hostname
Rename-Computer -NewName $hostname -Restart
