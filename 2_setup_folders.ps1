# Baptiste PELLARIN - 2017 
# swano (at) swano-lab (dot) net
# This project is licensed under the MIT License - see the LICENSE file for details

# VARIABLES
# Arborescence .\
#               |-> Scripts 
#                          |-> ~Liste des scripts~
#               |-> Eleves
#                        |-> ELEVES.txt # Liste des eleves formats CSV. Delimiteur : " , "
#               |-> Profs
#                        |-> PROFS_~CLASSE~.txt # Liste des profs pour chaque salles. RETIEZ LES ESPACES ENTRE LES COLONNES ET REMPLACEZ " ; " PAR DES " , "

# A MODIFIER
$path = "C:\Users\Administrateur\Documents\" # Dossier ou sont stockés les dossiers Scripts, Eleves, Profs AVEC LE " \ " à la fin (C:\Users\Administrateur\Documents\)
$ADpath = "OU=Membres,DC=server,DC=local" # Chemin vers la racine de l'annuaire active directory (OU=Membres,DC=exemple,DC=local)
$ADname = "@server.local" # Nom DNS de l'AD (SRV1)$newpath = "E:\UsersData\Classes\" # Chemin vers le nouveau dossier (E:\Data\NewFolder\)

if((!$path) -or (!$ADpath) -or (!$newpath) -or (!$oldpath) -or (!$ADname)){"Manque une ou plusieures variable(s)"; exit(1)}

# DEBUT

# Ajout des dossiers 

function Get-ClassName($_){  
    $pattern = "(?<=.*_)\w+?(?=.txt.*)" 
    $result = [Regex]::Match($_.Name, $pattern)  
    return $result.Value  
}

$oldpath = "NONE" 


function Create-Dir($name){ 
   if( -Not (Test-Path -Path $name ) ){ 
     New-Item -ItemType directory -Path "$name" > $null 
   }
   else { 'ok!'} 
}

$ACK = "FALSE" 
while ($ACK -eq "FALSE"){ 
    $choix = (Read-Host "Nouvelle install/Copy ? [n/c]") 
    if ($choix -like "n"){ $ACK = 'TRUE'; continue } 
    elseif ($choix -like "c"){ $ACK = 'TRUE'; continue } 
    else {$ACK = "FALSE"} 
}
$result1 = Get-ADOrganizationalUnit -filter * -SearchBase ("ou=Classes,"+$ADpath) 

$f = 0 
foreach($item in $result1){ 
           if ($item.name -ne $classe){ 
                        if($item.name -eq "Classes"){continue}
						
						
						$v = Get-ADGroupMember  $item.name  | Measure-Object 
						$v = $v.count 
						$e = 0 
                        $f++ 
                        $z = ($f / 65)*100
                        if($z -le 100){
                            $Activity1 = "Creation des Arborescences"
                            $StepText1   = "Creation de la classe $item "
                            $StatusText1 = "Classe $f sur 65 | $StepText1"
                            Write-Progress -Id 1 -Activity $Activity1 -Status ($StatusText1) -CurrentOperation $item.name  -PercentComplete ($z)
                        }
						
						$ACK= "FALSE"
 
						
						
                        
                        while ($ACK -eq "FALSE"){ 
                            $classe = $item.name 
                            $profs = ($classe+"Prof") 
                            $profp = Read-Host "Rentré le nom d'utilisateur du prof lecteur de la classe $classe [NULL Si pas de prof]" 
                            if(!$profp){$ACK = "TRUE"; break} 
                            if( -Not (Get-ADUser -Filter {SamAccountName -like $profp})){"Pas d'utilisateur avec ce nom!"; continue } 
                            else { $ACK = "TRUE" } 
                        }
            
                        cd $newpath 

                        $result = Get-ADGroupMember $classe 
                        
                        Create-Dir($classe) 
                        Disable-NTFSAccessInheritance -Path $classe 
                        Remove-NTFSAccess –Path $classe -Account "Utilisateurs" -AccessRights FullControl 
                        Add-NTFSAccess -Path $classe -Account ($classe+$ADname) -AccessRights ReadAndExecute 
                        Add-NTFSAccess -Path $classe -Account ($profs+$ADname) -AccessRights ReadAndExecute 

                        cd $classe 
                        Create-Dir('DataEleves') 
                        Disable-NTFSAccessInheritance -Path 'DataEleves'  
                        if($profp){Add-NTFSAccess -Path 'DataEleves' -Account $profp -AccessRights ReadAndExecute } 
                        Remove-NTFSAccess –Path 'DataEleves' -Account "Utilisateurs" -AccessRights FullControl 
                        Remove-NTFSAccess –Path 'DataEleves' -Account $profs -AccessRights Modify 
                        Remove-NTFSAccess –Path 'DataEleves' -Account $classe  -AccessRights ReadAndExecute 
                        cd 'DataEleves' 
                        

                        
                        foreach ($row in $result){ 

                            
                            
                            
                            $y = ($e / $v)*100
                            if($y -le 100){
                                $Activity = "Creation de l'Utilisateur"
                                $StepText   = "Creation du dossier personnel  de : $name de $classe"
                                $StatusText = "Utilisateur $($e.ToString().PadLeft($v.Count.ToString().Length)) sur $v | $StepText"
                                $Task        = "Ajout aux groupes"
                                Write-Progress -Id 2 -Activity $Activity -Status ($StatusText) -CurrentOperation $name -PercentComplete ($y) -ParentId 1
                                
                            } 
                                                       
                            $name = $row.name 
                            $samName = $row.SamAccountName 
                            $name = $name -replace ' ', '.' 
                            $name = $name.ToLower() 
                            Create-Dir($name) 
     
                            Disable-NTFSAccessInheritance -Path $name 
                            Add-NTFSAccess -Path "$name" -Account ($samName+$ADname) -AccessRights Modify 
                            if ($profp){Add-NTFSAccess -Path "$name" -Account ($profp+$ADname) -AccessRights ReadAndExecute} 
                            Set-NTFSOwner  -Path "$name" -Account ($samName+$ADname) 

                            
                            Remove-NTFSAccess –Path $name -Account "Utilisateurs" -AccessRights FullControl 
                            Remove-NTFSAccess –Path $name -Account $profs -AccessRights Modify 
                            Remove-NTFSAccess –Path $name -Account $classe  -AccessRights ReadAndExecute 

                            if($choix -like "c"){ 
                            $name 
                                if((Test-Path -Path ($oldpath + $name) -IsValid ) -AND (-Not(Test-Path -Path ($newpath + $name)))){ 
                                        ROBOCOPY /E /256 /R:1 /W:2  /COPY:D ($oldpath + "$name") ($newpath + "$classe\DataEleves\$name") > $null  ; 
                                         "copy!" 
                                } else{"pas de dossier"} 
                            }
                            $e++ 

                         }

                        cd  ($newpath + $classe) 

                        

                        Create-Dir("Echanges") 
                        Create-Dir("Ressources") 
                        Create-Dir("Devoirs") 

                        
                        Disable-NTFSAccessInheritance -Path "Echanges" 
                        Add-NTFSAccess -Path "Echanges" -Account ($classe+$ADname) -AccessRights Modify 
                        Add-NTFSAccess -Path "Echanges" -Account ($profs+$ADname) -AccessRights Modify 

                        
                        Disable-NTFSAccessInheritance -Path "Ressources" 
                        Add-NTFSAccess -Path "Ressources" -Account ($classe+$ADname) -AccessRights ReadAndExecute 
                        Add-NTFSAccess -Path "Ressources" -Account ($profs+$ADname) -AccessRights Modify 

                        
                        Disable-NTFSAccessInheritance -Path "Devoirs" 
                        Add-NTFSAccess -Path "Devoirs" -Account ($classe+$ADname) -AccessRights Write 
                        Add-NTFSAccess -Path "Devoirs" -Account ($profs+$ADname) -AccessRights Modify 
                        Remove-NTFSAccess –Path "Devoirs" -Account $classe  -AccessRights Read 
                    }
             }

cd $PSScriptRoot