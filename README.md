# biblio.pl

## Description
Script perl pour checker l'état 'à renouveller' des livres empruntés avec les bibliothèques de Montréal.

En le placant dans une tache CRON, plus de souci avec le renouvellement !

## Usage
1. Cloner le dépot.
2. diter le fichier config.pl : 
 * code de la carte de bilbiotheque
 * mot de passe associé, choisi en bilbiothèque
 * partie ou totalité du nom de famille, telle que affiché sur la page web du compte.
3. Puis lancer le script :
```
perl biblio.pl
```
