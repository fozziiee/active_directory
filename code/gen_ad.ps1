param( [Parameter(Mandatory=$true)] $JSONFile)

function CreateADGroup {
    param (
        [Parameter(Mandatory=$true)] $group_nameObject
    )

    $name = $group_nameObject.name
    New-ADGroup -name $name -GroupScope Global    
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

    #Actually create the AD user object
    # Actually create the AD user object
    New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalName@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount


    # Add the user to its appropriate group
    foreach($group_name in $userObject.groups) {

        try {
            Get-ADGroup -Identity "$group_name" 
            Add-ADGroupMember -Identity $group_name -Members $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] 
        {
            Write-Warning "User $name NOT added to grop $group_name because it does not exist"
        }        
    }
}


$json = ( Get-Content $JSONFile | ConvertFrom-Json)

$Global:Domain = $json.domain

foreach($group_name in $json.groups ) {
    CreateADGroup $group_name
}

foreach ( $user in $json.users) {
    CreateADUser $user
}

