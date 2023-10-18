param( 
    [Parameter(Mandatory=$true)] $JSONFile,
    [switch]$undo)

function CreateADGroup {
    param (
        [Parameter(Mandatory=$true)] $group_nameObject
    )

    $group_name = $group_nameObject.name.value
    New-ADGroup -Name $group_name -GroupScope Global    
}

function CreateADGroup {
    param (
        [Parameter(Mandatory=$true)] $group_nameObject
    )

    $group_name = $json.group.name.value
    New-ADGroup -Name $group_name -GroupScope Global    
}


function RemoveADGroup {
    param (
        [Parameter(Mandatory=$true)] $group_nameObject
    )
    $group_name = $group_nameObject

    if (Get-ADGroup -Filter {Name -eq $group_name}) {
        Remove-ADGroup -Identity $group_name -Confirm:$False    
    } else {
        Write-Host "Group $group_name not found. Skipping removal"
    }
}

function RemoveADUser {
    param (
        [Parameter(Mandatory=$true)] $userObject
    )

    $name = $userObject.name
    $firstname, $lastname = $name.split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username 
    Remove-ADUser -Identity $samAccountName -Confirm:$False    
}

function WeakenPasswordPolicy() {
    secedit /export /cfg c:\Windows\Tasks\secpol.cfg
    (Get-Content c:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 1") | Out-File c:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg c:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    rm -force c:\Windows\Tasks\secpol.cfg -confirm:$false    
}

function StrengthenPasswordPolicy() {
    secedit /export /cfg c:\Windows\Tasks\secpol.cfg
    (Get-Content c:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("MinimumPasswordLength = 1", "MinimumPasswordLength = 7") | Out-File c:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg c:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    rm -force c:\Windows\Tasks\secpol.cfg -confirm:$false    
}


function CreateADUser(){
    param( [Parameter(Mandatory=$true)] $userObject)
    
    # Pull out the name form the json object
    $name = $userObject.name
    $password = $userObject.password

    # Generate a "first inital, last name" structure for username
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username
    $principalName = $username

    # Extract group names from the userObject
    $groupNames = $userObject.groups | ForEach-Object { $_.name.value }
    
    # Check if each group exists and create it if it doesn't
    foreach ($group_name in $groupNames) {
        if (-not (Get-ADGroup -Filter {Name -eq $group_name})) {
            # Group doesn't exist, so create it
            New-ADGroup -Name $group_name -GroupScope Global
        }

        # Add the user to the group
        Add-ADGroupMember -Identity $group_name -Members $username
    }
    # Actually create the AD user object
    New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalName@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

    if ( $userObject.local_admin -eq $true ){
        net localgroup administrators $Global:Domain\$username /add
    }
}


$json = ( Get-Content $JSONFile | ConvertFrom-Json)
$Global:Domain = $json.domain

if ( -not $undo ) {
    
    WeakenPasswordPolicy
    foreach($group in $group_nameObject.name.value ) {
        # Extract the group name from the group Object
        $groupName = $group
        CreateADGroup $groupName
    }
    
    foreach ( $user in $json.users) {
        CreateADUser $user
    }
} else {
    StrengthenPasswordPolicy
    
    foreach ( $user in $json.users) {
        RemoveADUser $user
    }
    foreach ( $group in $group_nameObject.name.value ){
        # Extract the group name from the group object
        $groupName = $group
        Write-Debug "Removing group: $groupName"
        RemoveADGroup $groupName
    }

}




