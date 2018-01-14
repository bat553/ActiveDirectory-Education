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
#                        |-> PROFS_~CLASSE~.txt # Liste des profs pour chaque salles. RETIEZ LES ESPACES ENTRE LES COLONNES ET REMPLACEZ LES " ; " PAR DES " , "

# A MODIFIER
$path = "C:\Users\Administrateur\Documents\" # Dossier ou sont stockés les dossiers Scripts, Eleves, Profs AVEC LE " \ " à la fin (C:\Users\Administrateur\Documents\)
$ADpath = "OU=Membres,DC=server,DC=local" # Chemin vers la racine de l'annuaire active directory (OU=Membres,DC=exemple,DC=local)
$ADname = "@server.local" # Nom DNS de l'AD (SRV1)$newpath = "E:\UsersData\Classes\" # Chemin vers le nouveau dossier (E:\Data\NewFolder\)
$servername = "SERVER1" # Nom NETBIOS du serveur (SRV1)
$letter = "H:" # Lettre du lecteur réseau (H:)

# Expert 

$prE = "Etudiants" # Groupe global eleves
$prP = "Enseignants" # Groupe global profs
$oldpath = "NONE"

if((!$path) -or (!$ADpath) -or (!$newpath) -or (!$oldpath) -or (!$servername) -or (!$ADname) -or (!$letter) -or (!$prE) -or (!$prP) ){"Manque une ou plusieures variable(s)"; exit(1)}

# Creation des paratge AD

try { 
$e = 0 
$v = Get-ADGroupMember $prE  | Measure-Object 
$v = $v.count 
}catch{$count = 1}

$result = Get-ADGroupMember $prE  
        ForEach ($item in $result) 
            {
                $r = Get-ADUser -Filter {name -like $item.name} -Properties Division | Select-Object SamAccountName,Division 
                
                if($r.division -ne $classe){ 
                      $classe = $r.division 
                      if( -Not ( Get-SmbShare -Name  $classe -ea 0  )){ 
                            New-SmbShare -Name $classe -Path ($newpath + "$classe") -FullAccess ($classe + $ADname), ($classe +"Prof"+$ADname)
                         } 
                      else { 
                         Remove-SmbShare -Name $classe -Force 
                         New-SmbShare -Name $classe -Path ($newpath+$classe) -FullAccess ($classe+$ADname), ($classe +"Prof" + $ADname) 
                         }
                 }
                
                $name = $r.SamAccountName 
                $filename = $name 
                $samnamed = $name+"$" 
                if((!$count) -AND ($y -le 100)){
                    
                    ++$e
                    $y = ($e / $v)*100
                    $Activity = "Creation de l'ActiveDirectory"
                    $StepText   = "Creation du dossier personnel  de : $name de $classe"
                    $StatusText = "Utilisateur $($e.ToString().PadLeft($v.Count.ToString().Length)) sur $v | $StepText"
                    $Task        = "Ajout aux groupes"
                    Write-Progress -Id 1 -Activity $Activity -Status ($StatusText) -PercentComplete ($y)
                    

                }
                $name

             try{  
                 if( -Not ( Get-SmbShare -Name "$samnamed" -ea 0 )){ 
                   try{ New-SmbShare -Name $samnamed -Path ($newpath + "$classe\DataEleves\$filename") -FullAccess ($name+$ADname) } catch{$name; "bug"} 
                    Set-ADuser -Identity $name -HomeDrive $letter -HomeDirectory "\\$servername\$samnamed" 
                    } else { 
                    try{
                        "exist"
                        Remove-SmbShare -Name $samnamed -Force 
                        New-SmbShare -Name $samnamed -Path ($newpath + "$classe\DataEleves\$filename") -FullAccess ($name+$ADname)  } catch{$name; "bug"}
                        Set-ADuser -Identity $name -HomeDrive $letter -HomeDirectory "\\$servername\$samnamed" 
                
                    }

              }catch {"error"}


           }
        
cd $PSScriptRoot 