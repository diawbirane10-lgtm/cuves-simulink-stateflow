# Proposition de reprise de l'exercice sous MATLAB/Simulink

**Étudiant :** Birane Diaw - 4GESI-G1, EMSI Rabat.  
**Enseignant :** M. Brahim Najimi.  
**Objet :** Commande séquentielle de deux cuves, échange d'E/S déportées et supervision.

## Objectif

Reprendre le fonctionnement de l'exercice CPU 1516-3 PN/DP - ET200M sous MATLAB/Simulink et Stateflow, avec visualisation des cuves, boutons de départ, vannes, agitation, pompe, niveaux et diagnostics.

## Réalisation proposée

Le chart Stateflow `Sequence` représente le GRAFCET de la CPU : VA-01 pendant 10 s, VA-02 pendant 5 s, agitation pendant 15 s, puis transfert autorisé par la position ouverte de VA-03 et par le niveau haut non atteint de B. La fin du transfert est donnée par le niveau bas de A.

Le chart Stateflow `DP_Control` représente l'automate d'états de la liaison : attente, paramétrage, configuration, échange cyclique et défaut. Il commande réellement l'émulateur d'octets. L'ET200M est une station d'E/S déportées, et non une seconde CPU qui exécute un GRAFCET.

Le procédé virtuel calcule les volumes et la position de vanne. L'émulateur DP transporte les données utilisateur des modules DI/DQ 16 dans deux octets par sens, avec cycle choisi de 20 ms et watchdog choisi de 100 ms. L'IHM MATLAB lit les sorties du modèle en cours de simulation et permet d'injecter des défauts.

## Portée de la communication

Il s'agit d'une **émulation fonctionnelle du service cyclique PROFIBUS-DP**, et non d'une pile de protocole conforme ou d'une communication matérielle avec un ET200M. Les états de paramétrage/configuration sont schématiques. Le débit de 1,5 Mbit/s et la distance de 150 m sont repris comme données d'architecture, sans simulation électrique.

## Validation

Le modèle a été généré et compilé sous MATLAB R2024a sur le poste de l'étudiant. Le script `validate_cuves` a exécuté huit essais sur le modèle Simulink : fonctionnement nominal, bouton maintenu, départ distant, cuve B pleine, perte de liaison pendant le transfert ou le remplissage, vanne bloquée et reset pendant le remplissage. Les huit essais ont réussi ; les traces CSV/MAT et le rapport JSON sont dans `results/`. L'IHM a été vérifiée en cours de simulation : le bouton DCY1 active le remplissage après mise en ligne du bus DP. Les résultats Python restent une référence indépendante complémentaire.

## Documents remis

1. Le modèle `.slx` généré par MATLAB et les sources `.m`.
2. Le rapport `results/validation_matlab.json` et les courbes CSV/MAT.
3. Cette note, la cartographie des E/S et les hypothèses du modèle.
4. Les captures réelles de l'IHM au transfert et au défaut dans `results/ihm_transfert.png` et `results/ihm_defaut_bus.png`, des images des charts et un rejeu MP4 des traces de perte de liaison.

## Texte d'accompagnement proposé

Bonjour Monsieur Najimi,

Je vous transmets une reprise de l'exercice des deux cuves sous MATLAB/Simulink et Stateflow. L'objectif est de relier le GRAFCET, l'adressage des E/S déportées et une IHM de supervision, puis d'étudier les réactions du système aux défauts.

La partie PROFIBUS-DP est représentée par une émulation fonctionnelle des échanges cycliques et des diagnostics. Elle ne remplace pas une interface PROFIBUS matérielle.

Le dossier contient le modèle `.slx`, l'IHM et les traces des huit essais MATLAB réussis. Je souhaite vous présenter le modèle et discuter de son prolongement éventuel sur matériel Siemens.

Bien cordialement,  
Birane Diaw  
4GESI-G1 - EMSI Rabat  
Portfolio : https://b-diaw.com
