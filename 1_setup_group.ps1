# Baptiste PELLARIN - 2017 
# swano (at) swano-lab (dot) net
# This project is licensed under the MIT License - see the LICENSE file for details

Param(
    [string] $choix # Pour utiliser le script uniquement avec un ligne de commande (.\1_setup_group.ps1 [p/e])
 )

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
$protection = 1 # Protection des OU contre la suppression accidentelle (0 = Non, 1 = OUI)

# Expert 

$prE = "Etudiants" # Groupe global eleves
$prP = "Enseignants" # Groupe global profs


# DEBUT

if((!$path) -or (!$ADpath) -or (!$prE) -or (!$prP)){"Manque une ou plusieures variable(s)"; exit(1)}

$ACK = "FALSE" 
while ($ACK -eq "FALSE"){
if(!$choix) { $choix = (Read-Host "Eleves ou Profs ? [e/p]")}  
    if ($choix -eq "p"){ set-location $path"Profs"; $ACK = 'TRUE'; $pr = "Enseignants"; continue } 
    elseif ($choix -eq "e"){  $ACK = 'TRUE'; $pr = "Etudiants"; continue } 
    else {$ACK = "FALSE";  Remove-Variable choix} 
}
function Get-ClassName($_){  
	$result = [System.IO.Path]::GetFileNameWithoutExtension($_)
	$result = $result -replace 'PROFS_', '' 
	return $result  
}

function Get-UserP($samname){ 
    try{ 
      if(Get-ADUser -Filter {SamAccountName -like $samname}){$FIND = "TRUE"}else{$FIND = "FALSE"; Write-Host "Not Found!"} 
    } catch { $FIND = "FALSE" } 
    return $FIND 
}

function Set-SAMNAME($name){  
        if(-Not (Test-Path $path"Scripts\coresp.csv")){Add-Content -Path $path"Scripts\coresp.csv"  -Value '"Name","SamName"' } 
        
        $FIND = Get-UserP($name) 

        while ($FIND -eq "FALSE"){ 
             $c = "FALSE" 
             $nameold = $name 
             $corespcsv =  Import-Csv $path"Scripts\coresp.csv" | where {$_.name -like "$name" } 
             if($corespcsv.SamName){$name = $corespcsv.SamName; $c = "TRUE"; $FIND = "TRUE"} 
             
                 if($c -eq "FALSE"){
                     $name = (Read-Host "NOM UTILISATEUR : (NOM.PRENOM) ['NULL' SI BUG]") 
                     if($name -eq "NULL"){ Write-Host "CancelUser"; $c = "TRUE"; $FIND = "TRUE"} 
                     else { $FIND = Get-UserP($name) } 
                     if($FIND -eq "TRUE" ){ @($nameold+","+$name) | Add-Content -Path  $path"Scripts\coresp.csv" } 
                 } 
         }

         return $name
}

function Remove-StringLatinCharacters # Retire les accent des noms # http://www.lazywinadmin.com/2015/05/powershell-remove-diacritics-accents.html
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

$classe = "null" 
try{
    $v = Get-ADGroupMember $pr  | Measure-Object 
    $v = $v.count  
    $e = 0 
}catch{$count = 1}


if($choix -eq "e"){
    $result1 = Get-AdUser -filter * -SearchBase ("ou=eleves,"+$ADpath) -Properties Division 
    forEach($item in $result1){ 

  
                $name = $item.name 
                if ($item.division -ne $classe){ 
                    $classe = $item.division    
                    $classeI = $classe 
                    $pr = $prE 
        
                     }

            if((!$count) -and ($y -le 100)){
                ++$e
                $y = ($e / $v)*100
                $Activity = "Creation de l'ActiveDirectory"
                $StepText   = "Ajout de l'utilisateur : $name au groupe $classe"
                $StatusText = "Utilisateur $($e.ToString().PadLeft($v.Count.ToString().Length)) sur $v | $StepText"
                $Task        = "Ajout aux groupes"
                Write-Progress -Id 1 -Activity $Activity -Status ($StatusText) -CurrentOperation $name -PercentComplete ($y)
            }

            $name = Remove-StringLatinCharacters -String "$name" # Retier les accents /!\ Fichier encodé en UNICODE /!\
            $name = $name -replace ' ', '.' # Remplacer les espaces par des points
            $name = $name.ToUpper() # Nom en majuscule 
        
            $name = Set-SAMNAME($name)
            $name 
        
                if( -Not ( Get-ADOrganizationalUnit -Filter {Name -eq "Classes"} )){ 
                   New-ADOrganizationalUnit -Name "Classes" -ProtectedFromAccidentalDeletion $protection -Path $ADpath 
                }
                if( -Not ( Get-ADOrganizationalUnit -Filter {Name -like $classeI} )){ 
                   New-ADOrganizationalUnit -Name $classeI -ProtectedFromAccidentalDeletion $protection -Path ("OU=Classes,"+$ADpath) 
                }
                if( -Not (Get-ADGroup  -Filter {Name -like $classe}) ){ 
                        New-ADGroup -name $classe –groupscope DomainLocal -Path ("OU=$classeI,OU=Classes," + $ADpath) 
                    }
                if( -Not (Get-ADGroup  -Filter {Name -eq $pr}) ){ 
                        New-ADGroup -name $pr –groupscope Global -Path $ADpath 
                    }
                else { "OK!"} 

                if( -Not (Get-ADPrincipalGroupMembership $name | Select-String $classe ) ){ 
                        Add-ADGroupMember -Identity $classe -Member $name 
                    }
                if( -Not (Get-ADPrincipalGroupMembership $name | Select-String $pr ) ){
                        Add-ADGroupMember -Identity $pr -Member $name 
                    }

                else { "OK!"} 
            }

}
if ($choix -eq "p"){ 
$e = 0
    Get-ChildItem .\*.txt | Foreach-Object { 

           if (Get-ClassName($_) -ne $classe){ 
             try{$x = Get-ClassName($_)} 
             catch {"error"; exit 1} 
             $classe = ($x + "Prof")  
             $classeI = Get-ClassName($_) 
             $pr = $prP  
         }
        $csvImport = $_ | ConvertTo-Csv 
        $csvImport =  import-csv $_ -encoding  UTF8 
        ForEach ($item in $csvImport) 
        { 
                
                $name = $item.nom
                $name = Remove-StringLatinCharacters -String "$name" # Retier les accents /!\ Fichier encodé en UNICODE
                $name = $name -replace ' ', '.' # Remplacer les espaces par des points
                $name = $name.ToUpper() # Nom en majuscule 
                $name # Echo nom
                $name = Set-SAMNAME($name)
                
        
                    if( -Not ( Get-ADOrganizationalUnit -Filter {Name -eq "Classes"} )){
                       New-ADOrganizationalUnit -Name "Classes" -ProtectedFromAccidentalDeletion $protection -Path $ADpath 
                    }
                    if( -Not ( Get-ADOrganizationalUnit -Filter {Name -like $classeI} )){ 
                       New-ADOrganizationalUnit -Name $classeI -ProtectedFromAccidentalDeletion $protection -Path ("OU=Classes,"+$ADpath) 
                    }
                    if( -Not (Get-ADGroup  -Filter {Name -like $classe}) ){ 
                            New-ADGroup -name $classe –groupscope DomainLocal -Path ("OU=$classeI,OU=Classes," + $ADpath) 
                        }
                    if( -Not (Get-ADGroup  -Filter {Name -eq $pr}) ){ 
                            New-ADGroup -name $pr –groupscope Global -Path $ADpath 
                        }
                    else { "OK!"} 

                    if( -Not (Get-ADPrincipalGroupMembership $name | Select-String $classe ) ){ 
                            Add-ADGroupMember -Identity $classe -Member $name 
                        }
                    if( -Not (Get-ADPrincipalGroupMembership $name | Select-String $pr ) ){ 
                            Add-ADGroupMember -Identity $pr -Member $name 
                        }

                    else { "OK!"} 
                }



    }
} 


cd $PSScriptRoot 