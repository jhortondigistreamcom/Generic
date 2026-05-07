#${env:cmd} = "AddDeviceToGroup"
#${env:UPNorDevice} = "L011846"
#${env:Group} = "Intune Security - Disable SMB 2.0"
#sanitizing inputs
$CMD = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent("${env:CMD}")
$UPNorDevice = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent("${env:UPNORDEVICE}")
$Group = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent("${env:GROUP}")

Connect-MgGraph -Identity
#list of approved safe Entra Groups
$ApprovedEntraUserGroup = "Intune Security - Disable SMB 2.0","Intune - Allow Entra Kerberos","Intune - Policy - Windows Hello"
$ApprovedEntraDeviceGroup = "Intune - Policy - Always On VPN","Intune - Policy - Q & R Drive","Intune - Policy - Time Server"
#list of Approved Functions (mostly for AI)
$ApprovedFunctions = "AddUserToGroup","AddDeviceToGroup","ApprovedGroups","GetGroupMembers"

#add user to user group
Function AddUserToGroup{
    param(
        [Parameter(Mandatory=$true)] $UPN,
        [Parameter(Mandatory=$true)] $Group
    )
    Write-host "[Status]: Attempting to Add $UPN to $Group"
    if(ApprovedGroups -Group $Group){
        Write-host "[Approved]: $Group is an approved group"
        $groupobj = Get-MgGroup -Filter "DisplayName eq '$Group'"
        $userobj = Get-MgUser -UserId $UPN
        try{
            New-MgGroupMember -GroupId $groupobj.Id -DirectoryObjectId $userobj.Id
        }catch{
            Write-host '[Failed]: Unable to process command, see error:'
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
    Write-Host "[Status]: Get Group Members for $($Group.DisplayName)"
    if(ApprovedGroups -Group $Group){
        Write-host "[Approved]: $Group is an approved group"
        $groupobj = Get-MgGroup -Filter "DisplayName eq '$Group'"
        $Deviceobj = Get-MgDevice -Filter "displayName eq '$Device'"
        try{
            Write-host '[Failed]: Unable to process command, see error:'
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

Function GetGroupMembers{
    param(
        [Parameter(Mandatory=$true)] $Group
    )
    Write-host "[Status]: Get Group Members for $Group"
    try{
        $SearchKey = $Group.Replace("-"," ")
        $SearchKey = $SearchKey.Replace("."," ")
        $SearchKey = $SearchKey.Replace("&"," ")

        Write-host "[Status]: Searching Key $SearchKey" 
        $GroupOBJ = Get-MgGroup -Search "displayName:$SearchKey" -ConsistencyLevel eventual -CountVariable recCount
        if($GroupOBJ){
            $GroupOBJ
            try{
                $GroupMembers = Get-MgGroupMember -All -GroupId $GroupOBJ.id  | ForEach-Object { $_.AdditionalProperties['displayName'] }
                write-host " "
                $groupDisplayname = ($GroupOBJ).DisplayName
                write-host "$groupDisplayname"
                write-host "Members:"
                for($i=0;$i-lt $GroupMembers.count;$i++){write-host $GroupMembers[$i]}
                 write-host " "
            }catch{
                Write-host '[Failed]: Unable to process command, see error:'
                $_
                return $false
            }
        }else{
            Write-host '[Failed]: to find the group:'
            return $false
        }
        
        Return $true
    }catch{
        Write-host '[Failed]: Unable to process command, see error:'
        $_
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
}elseif($CMD -eq "GetGroupMembers"){
    $result = GetGroupMembers -Group $Group
}

return $result
