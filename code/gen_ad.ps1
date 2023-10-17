param( [Parameter(Mandatory=$true)] $JSONFile)

function CreateADGroup {
    param (
        [Parameter(Mandatory=$true)] $group_nameObject
    )

    $name = $group_nameObject.name
    New-ADGroup -name $name -GroupScope Global    
}

function RemoveADGroup {
    param (
        [Parameter(Mandatory=$true)] $group_nameObject
    )

    $name = $group_nameObject.name
    Remove-ADGroup -Identity $name -Confirm:$False    
}

function WeakenPasswordPolicy() {
    secedit /export /cfg c:\Windows\Tasks\secpol.cfg
    (Get-Content c:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File c:\Windows\Tasks\secpol.cfg
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
    
    # Check if each group exists and create it if it doesn't
    foreach ($group_name in $userObject.groups) {
        if (-not (Get-ADGroup -Filter {Name -eq $group_name})) {
            # Group doesn't exist, so create it
            New-ADGroup -Name $group_name -GroupScope Global
        }

        # Add the user to the group
        Add-ADGroupMember -Identity $group_name -Members $username
    }
    # Actually create the AD user object
    New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalName@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount


}


WeakenPasswordPolicy

$json = ( Get-Content $JSONFile | ConvertFrom-Json)
$Global:Domain = $json.domain

foreach($group_name in $json.groups ) {
    CreateADGroup $group_name
}

foreach ( $user in $json.users) {
    CreateADUser $user
}

# function CreateADUser() {
#     param([Parameter(Mandatory=$true)] $userObject)

#     # Pull out the name form the JSON object
#     $name = $userObject.name
#     $password = $userObject.password

#     # Generate a "first initial, last name" structure for the username
#     $firstname, $lastname = $name.Split(" ")
#     $username = ($firstname[0] + $lastname).ToLower()
#     $samAccountName = $username
#     $principalName = $username

#     # Check if each group exists and create it if it doesn't
#     foreach ($group_name in $userObject.groups) {
#         if (-not (Get-ADGroup -Filter {Name -eq $group_name})) {
#             # Group doesn't exist, so create it
#             New-ADGroup -Name $group_name -GroupScope Global
#         }

#         # Add the user to the group
#         Add-ADGroupMember -Identity $group_name -Members $username
#     }

#     # Actually create the AD user object
#     New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalName@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount
# }
