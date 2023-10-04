
# Imports
Import-Module ActiveDirectory               

                ### -------------------------------------------------------------------------------------- ###
                ###                                                                                        ###
                ### --- Please, before execute the script SET run Parameters in the MAIN section below --- ###  
                ###                                                                                        ###
                ### -------------------------------------------------------------------------------------- ###

### -------------------------------------------- ------------------- -------------------------------------------- ###
### --------------------------------------------  F U N C T I O N S  -------------------------------------------- ###
### -------------------------------------------- ------------------- -------------------------------------------- ###

##### --- #####
function Random-String($Length) {
    $result = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $char = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','0','1','2','3','4','5','6','7','8','9') | Get-Random
        $result += $char
    }

    return "K1!" + $result
}

##### --- #####
function Choose-RandomLine($filename) {
    $lines = Get-Content $filename
    $linenumber = Get-Random -Maximum $lines.Length -Minimum 1
    return $lines[$linenumber]
}

##### --- #####
function Create-RandomUser($domain, $OU_users, $OU_groups, $firstnames, $lastnames, $groupnames) {

    $nome      = Choose-RandomLine $firstnames
    $cognome   = Choose-RandomLine $lastnames
    $username  = "$nome $cognome"
    $username2 = $nome.SubString(0,1) + $cognome

    $password  = Random-String(10) | ConvertTo-SecureString -AsPlainText -Force

    # If the current user already exists, recurse until a new user is created
    $user = Get-ADUser -Filter "Name -eq '$username'" -SearchBase $OU_users
    if ($user) {
        Write-Output "User '$username' already exixts" | Out-File -Append -FilePath $global:LogPath
        Create-RandomUser $domain $OU_users $OU_groups $firstnames $lastnames $groupnames 
    }

    # Sets variable parameters
    $pwdexp = $true, $true, $false, $false, $false, $false | Get-Random 

    $user   = New-ADUser -Name $username -displayName $username -SamAccountName $username2 -GivenName $nome -Surname $cognome -UserPrincipalName $username2@$domain -AccountPassword $password -PasswordNeverExpires $pwdexp -Enabled $true -Path $OU_users
    # Write-Output "Created user: $user"
    # $user   = Get-ADUser -Filter {Name -eq $username} -SearchBase "$OU_users"

    Write-Output "Created user: $username" | Out-File -Append -FilePath $global:LogPath

    #Adds the user to a random group
    $groups = Get-ADGroup -Filter * -SearchBase "$OU_groups"
    if ($groups.Length -eq 0) {

        for ($i = 0; $i -le 3; $i++) {
            Create-RandomGroup $OU_groups $groupnames
        }
        Start-Sleep -Seconds 1
        $groups = Get-ADGroup -Filter * -SearchBase "$OU_groups"
    }
    $tgt = Get-Random -Maximum $groups.Length
    $targetGroup = $groups[$tgt]
    Add-ADGroupMember -Identity $targetGroup -Members $user -Confirm:$false
    
    Write-Output "User: $username added to Group: $targetGroup" | Out-File -Append -FilePath $global:LogPath

    Start-Sleep -Seconds 1

    # Ensures that the specified minimum number of users has been reached
    $ckuser = Get-ADUser -Filter * -SearchBase $OU_users
    if ($ckuser -isnot [array] -or $ckuser.Length -lt $global:StartUsers) {
        Create-RandomUser $domain $OU_users $OU_groups $firstnames $lastnames $groupnames
    }
}

##### --- #####
function Disable-User($OU_users) {
    
    Write-Output " --- Disable-User" | Out-File -Append -FilePath $global:LogPath

    $users = Get-ADUser -Filter {Enabled -eq $true} -SearchBase "$OU_users"
    if ($users -is [array]) {
        if ($users.Length -lt 3) {
            return
        }
    } else {
        return
    }
    $disable = Get-Random -Maximum $users.Length
    $user    = $users[$disable]
    Disable-ADAccount -Identity $user -Confirm:$false

    Write-Output "Disabled user: $user" | Out-File -Append -FilePath $global:LogPath
}

##### --- #####
function Enable-User($OU_users) {
    
    Write-Output " --- Enable-User" | Out-File -Append -FilePath $global:LogPath

    $users = Get-ADUser -Filter {Enabled -eq $false} -SearchBase "$OU_users"
    if ($users -is [array]) {
        if ($users.Length -le 3) {
            return
        }
    } else {
        return
    }
    $enable = Get-Random -Maximum $users.Length
    $user   = $users[$enable]
    Enable-ADAccount -Identity $user -Confirm:$false

    Write-Output "Enabled user: $user" | Out-File -Append -FilePath $global:LogPath
}

##### --- #####
function Create-RandomGroup($OU_groups, $groupnames) {
    
    Write-Output " --- Create-RandomGroup" | Out-File -Append -FilePath $global:LogPath
    $groupname = Choose-RandomLine $groupnames

    # Sets variable parameters
    $category  = @('Security','Security','Security','Security','Distribution','Distribution') | Get-Random 
    $scope     = @('DomainLocal','Global','Global','Global','Global','Universal') | Get-Random

    $group = Get-ADGroup -Filter {Name -eq $GroupName}
    if ($group) {
        Write-Output "Group '$group' already exixts" | Out-File -Append -FilePath $global:LogPath
        return
    }
    $group = New-ADGroup -Name $groupname -GroupCategory $category -GroupScope $scope -Path $OU_groups -Confirm:$false
    Write-Output "Created group: $groupname" | Out-File -Append -FilePath $global:LogPath
}

##### --- #####
function Delete-RandomUser($OU) {

    Write-Output " --- Delete-RandomUser" | Out-File -Append -FilePath $global:LogPath
    $users = Get-ADUser -Filter * -SearchBase "$OU"
    
    if ($users.Length -le $global:StartUsers) {
        return
    }

    $dele = Get-Random -Maximum $users.Length
    $user = $users[$dele]
    Remove-ADUser -Identity $user -Confirm:$false -Confirm:$false

    Write-Output "Deleted user: $user" | Out-File -Append -FilePath $global:LogPath
}


##### --- #####
function Move-RandomUser($OU_groups) {

    Write-Output " --- Move-RandomUser" | Out-File -Append -FilePath $global:LogPath

    # Gets a source random group
    $groups = Get-ADGroup -Filter * -SearchBase "$OU_groups"
    if ($groups.Length -le $global:StartGroups) {
        return
    }
    $srcix    = Get-Random -Maximum $groups.Length
    $srcgroup = $groups[$srcix]

    # Gets a target random group
    $tgtix    = Get-Random -Maximum $groups.Length
    $tgtgroup = $groups[$tgtix]

    # If source and target group are the same, then recurse
    if ($tgtgroup -eq $srcgroup) {
        Move-RandomUser $OU_groups
    }

    # Gets a random source group member
    $srcmems = Get-ADGroupMember -Identity $srcgroup
    if ($srcmems.Length -eq 0) {
        Move-RandomUser $OU_groups
    } 
    $srcix   = Get-Random -Maximum $srcmems.Length
    $srcmem  = $srcmems[$srcix]

    Add-ADGroupMember -Identity $tgtgroup -Members $srcmem -Confirm:$false
    Remove-ADGroupMember -Identity $srcgroup -Members $srcmem -Confirm:$false
    
    Write-Output "User: $srcmem moved from group: $srcgroup to group: $tgtgroup" | Out-File -Append -FilePath $global:LogPath
}

##### --- #####
function Delete-RandomGroup($OU_groups) {

    Write-Output " --- Delete-RandomGroup" | Out-File -Append -FilePath $global:LogPath
    
    # Gets a source random group
    $groups = Get-ADGroup -Filter * -SearchBase "$OU_groups"
    if ($groups.Length -le $global:StartGroups) {
        return
    }
    $srcix    = Get-Random -Maximum $groups.Length
    $srcgroup = $groups[$srcix]

    # Gets a target random group
    $tgtix    = Get-Random -Maximum $groups.Length
    $tgtgroup = $groups[$tgtix]

    if ($tgtgroup -eq $srcgroup) {
        Delete-RandomGroup $OU_groups
    } 

    # Gets source groups members
    $srcmems = Get-ADGroupMember -Identity $srcgroup

    foreach ($srcmem in $srcmems) {
        Add-ADGroupMember -Identity $tgtgroup -Members $srcmem -Confirm:$false
        Write-Output "     Group Member:  $srcmem moved to group Group: $tgtgroup" | Out-File -Append -FilePath $global:LogPath
    }
    Remove-ADGroup -Identity $srcgroup -Confirm:$false
    Write-Output "     Deleted Group: $srcgroup" | Out-File -Append -FilePath $global:LogPath
}


### -------------------------------------------- --------- -------------------------------------------- ###
### --------------------------------------------  M A I N  -------------------------------------------- ###
### -------------------------------------------- --------- -------------------------------------------- ###

#                                                                        #
# -----------------  Script Parameters Initialization  ----------------- #
#                                                                        #

$global:LogPath     = "C:\ADSym\LastRunLog.txt"  # --- Last run Log file full path
$global:StartUsers  = "10"                       # Initial number of users to be created before the standard pocess starts
$global:StartGroups = "4"                        # Initial number of groups to be created before the standard pocess starts

$Speed              = "Faster"                   # Commands execution frequency. Can be 'Normal', 'Fast', 'Faster' or 'Rocket'
$domain             = "YODA.local"                                   # --- Domain Name
$OU_users           = "OU=xGen,OU=Users,DC=YourDomain,DC=local"      # --- OU where Users will be created
$OU_groups          = "OU=xGen,OU=Groups,DC=YourDomain,DC=local"     # --- OU where Groups will be created
$firstnames         = "C:\ADSym\FirstNames.txt"                      # --- Users names file full path
$lastnames          = "C:\ADSym\LastNames.txt"                       # --- Users last names file full path
$groupnames         = "C:\ADSym\GroupNames.txt"                      # --- Groups names file full path


#                                                                               #
# -----------------  End of Script Parameters Initialization  ----------------- #
#                                                                               #



# 
# -----------------  Runs forever  -----------------
#
while ($true) {

    # Cleans up the last run log
    Write-Output "" | Out-File -FilePath $global:LogPath
    $runtime = Get-Date
    Write-Output $runtime | Out-File -Append -FilePath $global:LogPath
    Write-Output "" | Out-File -Append -FilePath $global:LogPath

    # Gets a random action
    $action = 1,1,1,1,2,2,2,3,3,3,3,3,4,4,4,4,5,5,6,6,7,7 | Get-Random
    
    switch ($action) {
        1 { Delete-RandomUser $OU_users
            Break
            }
        2 { Create-RandomGroup $OU_groups $groupnames
            break
            }
        3 { Create-RandomUser $domain $OU_users $OU_groups $firstnames $lastnames $groupnames
            break
            }
        4 { Move-RandomUser $OU_groups
            break
            }
        5 { Delete-RandomGroup $OU_groups
            break
            }
        6 { Disable-User $OU_users
            break
            }
        7 { Enable-User $OU_users
            break
            }
    }

    switch ($Speed) {
        'Normal' {
            $maxTime = 86400
            $minTime = 3600
            break
        }
        'Fast' {
            $maxTime = 28800
            $minTime = 1800
            break
        }
        'Faster' {
            $maxTime = 14400
            $minTime = 900
            break
        }
        'Rocket' {
            $maxTime = 300
            $minTime = 60
            break
        }
    }
    # Generates a random interval between 24h and 1h 
    $interval = Get-Random -Maximum $maxTime -Minimum $minTim
    Write-Output " ... sleeping for $interval seconds." | Out-File -Append -FilePath $global:LogPath
    Start-Sleep -Seconds $interval
    # Start-Sleep -Seconds 10  # use for testing purpose
}
