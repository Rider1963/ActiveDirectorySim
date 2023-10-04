# ActiveDirectorySim

 
Simulate AD operation through a Powershell script. 

This Powershell executes random AD commanda at random intervals.
Following actions are currently available:

- User creation ( randomly with PWD never expire)
  - Add newly create user to a random Group 
- User deletion
- Disable User
- Enable User
- Move a User to another group randomly chosed
- Group creation (randomly Security/Distribution) (randomly Local/Global/Universal)
- Group Deletion moving group's users to another group randomly chosed
  

Don't forget to properly configure script parameters below

                                                                        
 -----------------  Script Parameters Initialization  ----------------- 
                                                                        
$global:LogPath     = "C:\ADSym\LastRunLog.txt"  --- Last run Log file full path
$global:StartUsers  = "10"                       --- Initial number of users to be created before the standard pocess starts
$global:StartGroups = "4"                        --- Initial number of groups to be created before the standard pocess starts

$Speed              = "Faster"                   --- Commands execution frequency. Can be 'Normal', 'Fast', 'Faster' or 'Rocket'
$domain             = "YODA.local"                                   --- Domain Name
$OU_users           = "OU=xGen,OU=Users,DC=YourDomain,DC=local"      --- OU where Users will be created
$OU_groups          = "OU=xGen,OU=Groups,DC=YourDomain,DC=local"     --- OU where Groups will be created
$firstnames         = "C:\ADSym\FirstNames.txt"                      --- Users names file full path
$lastnames          = "C:\ADSym\LastNames.txt"                       --- Users last names file full path
$groupnames         = "C:\ADSym\GroupNames.txt"                      --- Groups names file full path
                                                                  
 -----------------  End of Script Parameters Initialization  -----------------                         


Run the script from an Administrative Powershell Amministrativa or schedule it through the Windows scheduler.
