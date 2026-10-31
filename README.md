# Deux cuves : Simulink, Stateflow et supervision

Projet pédagogique de Birane Diaw, 4GESI-G1, EMSI Rabat.
Reprise de l'exercice de B. Najimi : CPU 1516-3 PN/DP et ET200M séparés de 150 m.

## Démarrer dans MATLAB

Produits requis : MATLAB, Simulink et Stateflow. Projet généré et validé avec MATLAB R2024a sur le poste de l'étudiant. Aucun Simscape, Industrial Communication Toolbox ou Simulink Real-Time n'est nécessaire pour l'émulation.

1. Dans MATLAB, choisir le dossier extrait ou cloné de ce dépôt comme dossier courant.
2. Vérifier que Simulink et Stateflow sont disponibles.
3. Exécuter :

```matlab
demarrer_projet
```

La commande reconstruit le modèle depuis les sources `.m`, le sauvegarde dans `generated/Cuves_PROFIBUS_Stateflow.slx`, ouvre Simulink et lance l'IHM native MATLAB. Le modèle validé est également présent dans ce dossier.

4. Dans l'IHM, cliquer **Démarrer simulation**, attendre la disponibilité DP, puis **DCY1** ou **DCY2**.
5. Voir les niveaux, commandes, retour de position, étape, octets et diagnostics changer avec la simulation.

## Validation MATLAB réalisée

```matlab
addpath('matlab')
rapport = validate_cuves;
```

Sept simulations et leurs assertions ont été exécutées avec succès sur le modèle Simulink sous MATLAB R2024a, directement depuis ce dossier. Les résultats CSV, MAT et JSON sont sauvegardés dans `results/`. Les deux essais supplémentaires couvrent une coupure du bus et une réinitialisation pendant le remplissage. L'IHM a été vérifiée en direct : DCY1 lance le remplissage, puis les captures `results/ihm_transfert.png` et `results/ihm_defaut_bus.png` montrent le transfert et la réaction à une coupure. Relancer la commande ci-dessus pour reproduire les essais.

**Statut du projet** : le modèle `.slx` a été généré, compilé et simulé sous MATLAB R2024a ; les sept scénarios passent. Les résultats Python indépendants sont conservés comme référence complémentaire.

## Ce que le projet représente

- Chart Stateflow `Sequence` : programme séquentiel de la CPU 1516, avec attente, VA-01 10 s, VA-02 5 s, agitation 15 s, transfert et défaut bus.
- Chart Stateflow `DP_Control` : états du maître DP, attente, paramétrage, configuration, échange et défaut de liaison. Il pilote réellement l'émulateur d'octets et son retour à l'état sûr.
- Procédé discret à pas 10 ms : volumes de deux cuves, bilan de débits et ouverture progressive de VA-03.
- Émulateur fonctionnel DP : services d'initialisation simplifiés, échange cyclique, codage/décodage des octets, maintien des dernières entrées et watchdog.
- Départ DCY2, position VA-03 et niveau haut B lus depuis les octets reçus, pas depuis les capteurs physiques directement.
- Commande physique de VA-03 lue depuis l'octet reçu par l'esclave, pas directement depuis la CPU.
- IHM MATLAB reliée aux sorties en cours de simulation : tendances, temps restant dans les étapes temporisées, accès direct aux charts, capture PNG et export CSV.
- Défauts : liaison coupée, VA-03 bloquée fermée, cuve B pleine et vidange de B.

## Ce que ce projet ne fait pas

Il ne constitue pas une pile PROFIBUS conforme, n'émet pas de trames FDL sur RS-485 et ne se connecte pas réellement à une CPU ou un ET200M. Les transitions d'initialisation sont une représentation pédagogique, pas une implémentation certifiée des télégrammes Set_Prm/Chk_Cfg. L'IHM est une supervision de simulation, pas un SCADA industriel déployé.

Le cycle d'échange de 20 ms et le watchdog de 100 ms sont des paramètres choisis pour la démonstration ; ils ne sont pas déduits du débit 1,5 Mbit/s. La distance et le débit sont documentés, pas simulés au niveau électrique.

Pour un PROFIBUS matériel, il faut une interface maître/esclave et des pilotes compatibles. Une voie documentée existe via Simulink Real-Time et une cible Speedgoat équipée d'un module PROFIBUS adapté. Une liaison PC-automate par OPC UA serait une autre couche de supervision ; ce n'est pas une connexion PROFIBUS directe.

## Dossiers

- `matlab/build_cuves.m` : construction du modèle et des deux charts Stateflow.
- `matlab/cuves_hmi.m` : IHM native.
- `matlab/blocks/` : procédé, échange DP logique, adaptation des E/S et commandes.
- `matlab/cuves_scenario.m` : stimuli automatiques.
- `matlab/validate_cuves.m` : essais MATLAB/Simulink à exécuter localement.
- `matlab/generer_presentation.m` : export du schéma, des charts, des courbes et d'un rejeu vidéo accéléré.
- `matlab/capturer_demo_ihm.m` : démarre l'IHM, teste le transfert et la coupure du bus, puis enregistre deux captures réelles.
- `docs/rapport_court_latex/` : rapport court `rapport_court_deux_cuves.pdf` et source `main.tex`, texte noir et blanc, captures en couleurs, sans pied de page.
- `docs/` : note pour le professeur, guide des deux charts Stateflow, architecture, cartographie, sources et limites.
- `validation/reference_model.py` : modèle indépendant sans dépendance Python externe.
- `validation/reference_results/` : traces et vérifications Python, identifiées comme telles.
- `results/` : résultats des sept scénarios, captures des charts, courbes, aperçu de l'IHM et rejeu MP4.
- `generated/` : modèle `.slx` réellement produit par MATLAB R2024a.

## Démonstration conseillée, environ 5 minutes

1. Ouvrir le modèle puis les charts `Sequence` et `DP_Control` : expliquer les 10 / 5 / 15 secondes et l'initialisation DP.
2. Démarrer via DCY2 : montrer son bit dans I4.
3. Observer VA-03 commandée, son ouverture progressive, puis le démarrage de la pompe.
4. Injecter une perte de liaison pendant le transfert : arrêt et défaut mémorisé.
5. Rétablir le bus ; attendre son retour disponible, puis réinitialiser (extension : remise à zéro du procédé simulé).
6. Montrer le scénario `high_B` et la reprise après vidange.
7. Ouvrir le rapport MATLAB et les CSV avant remise au professeur.

Pour régénérer les images et la vidéo depuis les traces MATLAB :

```matlab
addpath('matlab')
generer_presentation
```

`results/rejeu_perte_liaison.mp4` est une animation accélérée des résultats `link_loss.csv`, et non une captation de l'écran de l'IHM. Le bouton **Capture** de l'IHM enregistre une image réelle de la supervision dans `results/`.

Pour refaire automatiquement les deux captures de l'IHM : `addpath('matlab'); capturer_demo_ihm`. Le script ferme l'IHM après les captures.

La réinitialisation de l'IHM remet les volumes simulés à leurs valeurs initiales. Cela sert à recommencer un essai : ce n'est pas une vidange physique de l'installation.

## Serveur MCP MATLAB

Le serveur MCP officiel de MathWorks est disponible sur [matlab/matlab-mcp-server](https://github.com/matlab/matlab-mcp-server). Il a été installé et vérifié sur le poste de développement avec MATLAB R2024a. Son installation est propre à chaque machine et n'est pas embarquée dans ce dépôt. Le projet fonctionne aussi sans MCP en lançant les commandes directement dans MATLAB.
