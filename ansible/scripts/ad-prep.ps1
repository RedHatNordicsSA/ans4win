<powershell>
$myPassword = "Password1"
$Secure_String_Pwd = ConvertTo-SecureString $myPassword -AsPlainText -Force
$myDomain = "ans4win.local"
$myNetbios = "ANS4WIN"
$myScript = "c:\usersgrops.ps1"

$daScript = @'
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Import-module ActiveDirectory
$Secure_String_Pwd = ConvertTo-SecureString "Password1" -AsPlainText -Force
New-ADUser -Name "Hakan Hagenrud" -SamAccountName "hger" -UserPrincipalName "hger@ans4win.local" -Company "Furniture Heaven" -AccountPassword $Secure_String_Pwd -Enabled $true -ChangePasswordAtLogon $false
New-ADUser -Name "Daniel Svensson" -SamAccountName "vsda" -UserPrincipalName "vsda@ans4win.local" -Company "Furniture Heaven" -AccountPassword $Secure_String_Pwd -Enabled $true -ChangePasswordAtLogon $false
New-ADUser -Name "Mister Manager" -SamAccountName "mgmt" -UserPrincipalName "mgmt@ans4win.local" -Company "Furniture Heaven" -AccountPassword $Secure_String_Pwd -Enabled $true -ChangePasswordAtLogon $false
New-ADUser -Name "Mister Intern" -SamAccountName "intr" -UserPrincipalName "intr@ans4win.local" -Company "Furniture Heaven" -AccountPassword $Secure_String_Pwd -Enabled $true -ChangePasswordAtLogon $false
New-ADUser -Name "Workstation Adder" -SamAccountName "wsadder" -UserPrincipalName "wsadder@ans4win.local" -Company "Furniture Heaven" -AccountPassword $Secure_String_Pwd -Enabled $true -ChangePasswordAtLogon $false
New-ADGroup "Managers" -GroupCategory Security -GroupScope Global
New-ADGroup "Minions" -GroupCategory Security -GroupScope Global
Add-ADGroupMember -Identity "Domain Admins" -Members "CN=Workstation Adder,CN=Users,DC=linux4win,DC=local"
Add-ADGroupMember -Identity "Minions" -Members "CN=Hakan Hagenrud,CN=Users,DC=linux4win,DC=local", "CN=Daniel Svensson,CN=Users,DC=linux4win,DC=local"
Add-ADGroupMember -Identity "Managers" -Members "CN=Mister Manager,CN=Users,DC=linux4win,DC=local"
'@

$Secure_String_Pwd = ConvertTo-SecureString "Password1" -AsPlainText -Force
$username = 'ANS4WIN\Administrator'
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-executionpolicy bypass -file c:/myfile.ps1 -PropertyType ExpandString"
$trigger = New-ScheduledTaskTrigger -AtStartup 
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "populateAD" -RunLevel Highest -User $username -Password $Secure_String_Pwd

$username = 'ANS4WIN\Administrator'
$Secure_String_Pwd = ConvertTo-SecureString "Password1" -AsPlainText -Force
$action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument "-executionpolicy bypass -file c:/myfile.ps1"
$trigger =  New-ScheduledTaskTrigger -AtStartup
$params = @{
"TaskName"    = "Do the stuff"
"Action"      = $action
"Trigger"     = $trigger
"User"        = $Username
"Password"    = $Secure_String_Pwd
"RunLevel"    = "Highest"
"Description" =  "Run the thing with the stuffs"
}
Register-ScheduledTask @Params



echo $daScript > $myScript
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name "addusers" -Value "%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file $myScript" -PropertyType ExpandString
Start-Sleep -s 5
#net user /passwordreq:yes Administrator $myPassword
Set-LocalUser -Name "Administrator" -Password $Secure_String_Pwd
#Install-Windowsfeature AD-Domain-Services
#Install-WindowsFeature RSAT-ADDS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Start-Sleep -s 20
Install-WindowsFeature DNS -IncludeManagementTools
Start-Sleep -s 20
Import-Module ADDSDeployment
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "Win2012R2" -DomainName $myDomain -DomainNetbiosName $myNetbios -ForestMode "Win2012R2" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword:$Secure_String_Pwd
Rename-Computer -NewName mydc -Force
Restart-Computer
</powershell>

