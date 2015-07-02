# biblio.pl

## Description
Script perl pour checker l'état 'à renouveller' des livres empruntés avec les bibliothèques de Montréal.

En le placant dans une tache CRON, plus de soucie avec le renouvellement !

## Usage
Editer le fichier config.pl : 
* code de la carte de bilbiotheque
* mot de passe associé, choisi en bilbiothèque
* partie ou totalité du nom de famille, telle que affiché sur la page web du compte.

Puis lancer le script :
```
perl biblio.pl
```
