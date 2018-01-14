# Baptiste PELLARIN - 2017 
# swano (at) swano-lab (dot) net
# This project is licensed under the MIT License - see the LICENSE file for details

Param (
    [string] $choix # Pour utiliser le script uniquement avec une ligne de commande (.\0_setup_user.ps1 -choix [e/p])
 )

# VARIABLES
# Arborescence .\
#               |-> Scripts 
#                          |-> ~Liste des scripts~
#               |-> Eleves
#                        |-> ELEVES.txt # Liste des eleves formats CSV UTF-8. Delimiteur : " , "
#               |-> Profs
#                        |-> PROFS_~CLASSE~.txt # Liste des profs pour chaque salles. RETIEZ LES ESPACES ENTRE LES COLONNES ET REMPLACEZ " ; " PAR DES " , "

# A MODIFIER
$path = "C:\Users\Administrateur\Documents\" # Dossier ou sont stockés les dossiers Scripts, Eleves, Profs AVEC LE " \ " à la fin (C:\Users\Administrateur\Documents\)
$ADpath = "OU=Membres,DC=server,DC=local" # Chemin vers la racine de l'annuaire active directory (OU=Membres,DC=exemple,DC=local)
$ADname = "@server.local" # Nom DNS de l'AD (SRV1)
$protection = 0 # Protection des OU contre la suppression accidentelle (0 = Non, 1 = OUI)

# Expert ONLY 

# Soit l'un soit l'autre
$change = 1 # ChangePasswordAtLogon
$expire = 0 # PasswordNeverExpires

# DEBUT
 
if((!$path) -or (!$ADpath) -or (!$ADname)){"Manque une ou plusieures variable(s)"; exit(1)}


$ACK = "FALSE" 
while ($ACK -eq "FALSE"){  
    if(!$choix) { $choix = (Read-Host "Eleves ou Profs ? [e/p]")} 
    if (($choix -eq "p" )){ set-location $path"Profs"; $ACK = 'TRUE'; $ou= "Profs"; continue } 
    elseif (($choix -eq "e") ){ set-location $path"Eleves"; $ACK = 'TRUE'; $ou= "Eleves"; continue } 
    else {$ACK = "FALSE"; Remove-Variable choix}
	}

function Get-SAMNAME($name, $ou, $change, $expire, $pass){ 
             $FIND = "FALSE" 
             $corespcsv =  Import-Csv $path"Scripts\coresp.csv" | where {$_.name -like "$name" }
             if($corespcsv.SamName){$name = $corespcsv.SamName; $FIND = "TRUE"} 
             Write-Host "OK!"
             if($FIND -eq "TRUE"){New-ADUser -Name $name -SamAccountName $name  -ChangePasswordAtLogon $change -PasswordNeverExpires $expire -UserPrincipalName $name  -Enabled $True -AccountPassword (ConvertTo-SecureString  "$pass" -AsPlainText -Force) -Division $classe -Path ("OU=$ou," + $ADpath) } 
             return $FIND 
}

function Remove-StringLatinCharacters # Retire les accents des noms # http://www.lazywinadmin.com/2015/05/powershell-remove-diacritics-accents.html
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}


if(-Not (Test-Path $path"Scripts\coresp.csv")){Add-Content -Path $path"Scripts\coresp.csv"  -Value '"Name","SamName"' } 

if ($choix -like "e") {$name = $item.nom +" "+ $item.prenom; $classe = $item.classe; $u = "eleves"; $m = "Etudiants"} 
else {$name = $item.nom; $classe = "Prof"; $u ="profs"; $m = "Enseignants"} 

try{
    $v = Get-ADGroupMember $m  | Measure-Object 
    $v = $v.count
    $e = 0 
}catch{$count = 1}
Get-ChildItem .\*.txt | Foreach-Object { 
    
    $csvImport =  import-csv $_ -encoding  UTF8 
    ForEach ($item in $csvImport)
    {

        if ($choix -like "e") {$name = $item.nom +" "+ $item.prenom; $classe = $item.classe; $pass = $item.'Ne(e) le'} 
        else {$name = $item.nom; $classe = "Prof"; $pass = $item.'Ne(e) le'} 
        
        if(!$count){
            ++$e
            $y = ($e / $v)*100
            $Activity = "Creation de l'ActiveDirectory"
            $Task     = "Creation des utilisateurs : $u"
            $StepText   = "Utilisateur : $name"
            $StatusText = "Utilisateur $($e.ToString().PadLeft($v.Count.ToString().Length)) sur $v | $StepText"
            Write-Progress -Id 1 -Activity $Activity -Status ($StatusText) -PercentComplete ($y)
        }
        
        $samname = $name -replace ' ', '.' # Remplacer les espaces par des points
        $samname = $samname.ToUpper() # Mettre le nom en majuscule 
        $samname # Ecrire le nom sur la console

            if( -Not ( Get-ADOrganizationalUnit -Filter {Name -eq $ou} )){ 
                 New-ADOrganizationalUnit -Name $ou -ProtectedFromAccidentalDeletion $protection -Path $ADpath 
             }
            if( -Not (Get-ADUser -Filter {(Name -like $name) -and (division -eq $classe)})){ 
                try{  
                     New-ADUser -Name $name -SamAccountName $samname -ChangePasswordAtLogon $change -PasswordNeverExpires $expire -UserPrincipalName ($samname+$ADname)  -Enabled $True -AccountPassword (ConvertTo-SecureString  "$pass" -AsPlainText -Force) -Division $classe -Path ("OU=$ou,"+$ADpath) 
                   }
                    catch{ "error" 
                        $nameold = $samname 
                        $ACK = Get-SAMNAME $samname $ou $change $expire $pass
                        while ($ACK -eq "FALSE"){ 
                            $samname = (Read-Host "NOM UTILISATEUR : (NOM.PRENOM) [ENTER SI DEJA CREE]")   
                            if ($samname){ New-ADUser -Name $samname -ChangePasswordAtLogon $change -PasswordNeverExpires $expire -SamAccountName $samname -UserPrincipalName ($samname+$ADname) -Enabled $True -AccountPassword (ConvertTo-SecureString  "$pass" -AsPlainText -Force) -Division $classe -Path ("OU=$ou,"+$ADpath); $ACK = "TRUE"; @($nameold+","+$samname) | Add-Content -Path  $path"Scripts\coresp.csv"; continue } 
                            else {$ACK = "FALSE"} 
                        }
                    } 
                    
                     
             }
             else { 
             "Utilisateur déja créer"
               
             }
             
           

     }
}

cd $PSScriptRoot 

        