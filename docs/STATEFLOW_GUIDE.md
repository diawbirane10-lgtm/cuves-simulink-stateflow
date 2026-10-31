# Les automates d'états Stateflow

Le modèle `generated/Cuves_PROFIBUS_Stateflow.slx` contient deux charts exécutés toutes les 10 ms.

## `Sequence` : programme de la CPU 1516

| État | Sortie `phase` | Condition de sortie |
|---|---:|---|
| ATTENTE | 0 | Front montant DCY1 ou DCY2, niveau bas A et bus disponible |
| REMPLISSAGE_P1 | 1 | 10 s écoulées |
| REMPLISSAGE_P2 | 2 | 5 s écoulées |
| AGITATION | 3 | 15 s écoulées |
| TRANSFERT | 4 | Niveau bas A atteint |
| DEFAUT_BUS | 9 | Reset et bus à nouveau disponible |

Dans les phases actives, la perte du bus provoque `DEFAUT_BUS`. Les commandes sont mises à zéro par les interverrouillages. Pendant le transfert, la pompe dépend aussi du retour d'ouverture VA-03 et du niveau haut de B.

## `DP_Control` : machine d'états du maître DP

| État | Sortie `dpMode` | Rôle |
|---|---:|---|
| ATTENTE | 0 | Liaison indisponible |
| PARAMETRAGE | 1 | Étape pédagogique d'initialisation |
| CONFIGURATION | 2 | Étape pédagogique d'initialisation |
| ECHANGE | 3 | Échanges cycliques des octets I4/I5 et Q4/Q5 |
| DEFAUT_LIAISON | 4 | Coupure ou données âgées de 100 ms |

Les trois premières étapes durent chacune environ 20 ms. En `ECHANGE`, le bloc `DP_Emulator` transfère les octets toutes les 20 ms et publie `busOK` après le premier échange. En défaut, il met la commande distante VA-03 en repli. Au retour de la liaison, `DP_Control` recommence son initialisation. Le chart `Sequence` exige ensuite une réinitialisation pour quitter `DEFAUT_BUS`.

L'ET200M est une station d'E/S déportées, pas une seconde CPU programmable. Ces deux charts représentent le programme de la CPU et le comportement de la communication. Ils n'implémentent pas des télégrammes PROFIBUS matériels.

## À montrer pendant la soutenance

1. Lancer `demarrer_projet` dans MATLAB depuis le dossier du projet.
2. Double-cliquer sur `Sequence`, puis sur `DP_Control` dans Simulink.
3. Dans l'IHM, démarrer la simulation : le diagnostic passe par les états DP jusqu'à `ECHANGE`.
4. Cliquer sur DCY1 ou DCY2 et suivre les phases et les niveaux.
5. Couper le bus pendant le transfert : `DP_Control` passe à `DEFAUT_LIAISON`, `Sequence` à `DEFAUT_BUS` et les commandes s'arrêtent.
6. Rétablir le bus, attendre `ECHANGE`, puis réinitialiser le défaut CPU.

Le bouton **Stateflow** de l'IHM ouvre les deux charts. **Capture** enregistre la supervision dans `results/`. Les étapes temporisées affichent le temps restant estimé.

Pour reproduire les sept essais enregistrés, exécuter `addpath('matlab'); validate_cuves` depuis le dossier du projet. Les deux derniers essais déclenchent une perte de liaison et un reset pendant le remplissage. Les colonnes `phase`, `etatDP`, `busOK`, `tx0` et `rx0` sont dans les CSV de `results/`.

`generer_presentation` produit des images des deux charts, une synthèse des traces et un rejeu MP4 accéléré de la perte de liaison. Ce rejeu utilise les valeurs simulées et ne prétend pas être une capture de l'IHM.

`capturer_demo_ihm` rejoue DCY1 en accéléré dans la vraie IHM, enregistre une image pendant le transfert puis une autre après coupure du bus. Le script ferme l'IHM à la fin.
