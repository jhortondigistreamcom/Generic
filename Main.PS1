#${env:cmd} = "AddDeviceToGroup"
#${env:UPNorDevice} = "L011846"
#${env:Group} = "Intune Security - Disable SMB 2.0"
#sanitizing inputs
$CMD = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent("${env:cmd}")
$UPNorDevice = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent("${env:UPNorDevice}")
$Group = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent("${env:Group}")

Connect-MgGraph -Identity
#list of approved safe Entra Groups
$ApprovedEntraUserGroup = "Intune Security - Disable SMB 2.0","Intune - Allow Entra Kerberos","Intune - Policy - Windows Hello"
$ApprovedEntraDeviceGroup = "Intune - Policy - Always On VPN","Intune - Policy - Q & R Drive","Intune - Policy - Time Server"
#list of Approved Functions (mostly for AI)
$ApprovedFunctions = "AddUserToGroup","AddDeviceToGroup","ApprovedGroups"

#add user to user group
Function AddUserToGroup{
    param(
        [Parameter(Mandatory=$true)] $UPN,
        [Parameter(Mandatory=$true)] $Group
    )
 
    if(ApprovedGroups -Group $Group){
        $groupobj = Get-MgGroup -Filter "DisplayName eq '$Group'"
        $userobj = Get-MgUser -UserId $UPN
        try{
            New-MgGroupMember -GroupId $groupobj.Id -DirectoryObjectId $userobj.Id
        }catch{
            $_
            return $false
        }
        return $true
    }else{
        write-host "Group is not an approved group for this script to manage"
        return $false
        
    }
}

#add user to device group
Function AddDeviceToGroup{
    param(
        [Parameter(Mandatory=$true)] $Device,
        [Parameter(Mandatory=$true)] $Group
    )
 
    if(ApprovedGroups -Group $Group){
        $groupobj = Get-MgGroup -Filter "DisplayName eq '$Group'"
        $Deviceobj = Get-MgDevice -Filter "displayName eq '$Device'"
        try{
            New-MgGroupMember -GroupId $groupobj.Id -DirectoryObjectId $Deviceobj.Id
        }catch{
            return $false
        }
        return $true
    }else{
        write-host "Group is not an approved group for this script to manage"
        return $false
        
    }
}

#Checks if a group is approved
Function ApprovedGroups{
    param(
        [Parameter(Mandatory=$true)] $Group
    )
    if (($ApprovedEntraUserGroup -contains $Group) -or ($ApprovedEntraDeviceGroup -contains $Group)){
        return $true
    }else{
        return $false
    }
}

#debug code
#$CMD = "AddDeviceToGroup"
#$UPNorDevice = "L011846"
#$Group = "Intune Security - Disable SMB 2.0"

#main, we use CMD to determine which functiont yo run.
if($CMD -eq "AddUserToGroup"){
    $result = AddUserToGroup -UPN $UPNorDevice -Group $Group
}elseif($CMD -eq "AddDeviceToGroup"){
    $result = AddDeviceToGroup -Device $UPNorDevice -Group $Group
}

return $result
