# ActiveDirectory-Education

#### Script powershell pour créer l'ActiveDirectory simple (Groupe classe, dossier personnel élève, partages classes, permission dossiers....). 

Ce script est destiné à la création d'un serveur ActiveDirectory fonctionnel pour un établissement scolaire

---

## INSTALLATION

### REQUIREMENT

Un Windows Serveur 2008 R2 mini (testé sur windows server 2012)

Le module powershell [NTFSSecurity](https://www.powershellgallery.com/packages/NTFSSecurity)

#### Arborescences


Dans le dossier de votre choix. Ex.:C:\Users\Administrateur\Documents\

      → Scripts 
        → *Listes des scripts*

      → Eleves
        → ELEVES.txt (Suivre la syntaxe de l'exemple)

      → Profs
        → PROFS_*CLASSE*.txt (La liste des profs pour chaque classe. Ref.: Profs_exemple.txt)
        
---

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

---

### Utilisation

Le script ce déroule en 4 parties indépendantes 

* 0_setup_user.ps1 → Crée les utilisateurs à partir des fichiers dans l'arborescence 
* 1_setup_group.ps1 → Ajoute les utilisateurs aux groupes classes
* 2_setup_folders.ps1 → Crée l'arborescence
* 3_setup_smb.ps1 → Crée les partages windows et ajoute les dossiers personnels à l'utilisateur



## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details



