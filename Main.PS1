Connect-MgGraph -Identity
$ApprovedEntraUserGroup = "Intune Security - Disable SMB 2.0","zz"
$ApprovedEntraDeviceGroup = "Intune - Policy - Always On VPN","zz"
$ApprovedFunctions = "AddUserToGroup","AddDeviceToGroup","ApprovedGroups"
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

#${env:cmd} = "AddDeviceToGroup"
#${env:UPNorDevice} = "L011846"
#${env:Group} = "Intune Security - Disable SMB 2.0"

if(${env:cmd} -eq "AddUserToGroup"){
    $result = AddUserToGroup -UPN ${env:UPNorDevice} -Group ${env:Group}
}elseif(${env:cmd} -eq "AddDeviceToGroup"){
    $result = AddDeviceToGroup -Device ${env:UPNorDevice} -Group ${env:Group}
}

return $result
