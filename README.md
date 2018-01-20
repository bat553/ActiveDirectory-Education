# ActiveDirectory-Education

#### Script powershell pour créer un annuaire ActiveDirectory ainsi que ses recsources annexes (Groupe classe, dossier personnel élève, partages classes, permission NTFS des dossiers....). 

Ce script est destiné à la création d'un serveur ActiveDirectory fonctionnel pour un établissement scolaire

---

## INSTALLATION

#### REQUIREMENT

Un Windows Serveur 2012 R2 mini (testé sur windows server 2012)

**Le module powershell [NTFSSecurity](https://www.powershellgallery.com/packages/NTFSSecurity)**

**L'OU 'Membres' crée à la racine de votre annuaire**

**Désactiver les stratégies de complexité des mots de passe** 

#### Arborescence


Dans le dossier de votre choix. Ex.:C:\Users\Administrateur\Documents\

      → Scripts 
        → *Listes des scripts*

      → Eleves
        → ELEVES.txt (Suivre la syntaxe de l'exemple)

      → Profs
        → PROFS_*CLASSE*.txt (La liste des profs pour chaque classe. Ref.: Profs_exemple.txt)
        

#### FORMATAGE DES LISTES

##### Syntaxe listes élèves 

###### Nom du fichier  → ELEVES.txt

```
Nom,Prenom,Ne(e) le,Classe
Dupont,Kevin,05/12/2000,TSTMG1
```

##### Syntaxe listes profs

###### Nom du fichier → PROFS_*Classe*.txt

```
Nom,Ne(e) le
"Karl Marx",05/05/1818
```

#### VARIABLES (en début de fichier)

* $path → Dossier racine de l'arborescence. Ex.:  C:\Users\Administrateur\Documents\
* $ADpath → Chemin vers la racine de l'annuaire Active-Directory (OU=Membres,DC=exemple,DC=local)
* $ADname → Nom DNS de l'AD (SRV1)
* $protection → Protection des OU contre la suppression (0 = Non, 1 = OUI)
* $newpath → Chemin vers le nouveau dossier (E:\Data\NewFolder\)
* $oldpath → Chemin vers l'ancien dossier (D:\Data\OldFolder\)
* $servername → Nom NETBIOS du serveur (SRV1)
* $letter → Lettre du lecteur réseau (H:)

---

## Utilisation

Le script se déroule en 4 parties indépendantes 

* 0_setup_user.ps1 → Crée les utilisateurs à partir des fichiers dans l'arborescence 
* 1_setup_group.ps1 → Ajoute l'utilisateur a son groupe classe
* 2_setup_folders.ps1 → Crée l'arborescence
* 3_setup_smb.ps1 → Crée le partage windows et ajoute le dossier personnel à l'utilisateur

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details


---

Ce script a été crée dans le cadre de mon stage dans un établissement scolaire. 
Il s'agit de mon premier vrai travail avec PowerShell. La qualité du code est sans doute à revoir :-)

