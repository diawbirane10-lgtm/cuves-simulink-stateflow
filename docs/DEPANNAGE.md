# Dépannage sur le poste MATLAB

## Dossier courant

Le fichier `demarrer_projet.m` doit être dans le dossier courant de MATLAB. Extraire l'archive entièrement ; ne pas lancer les fichiers depuis l'aperçu du ZIP.

## Produits et version

```matlab
version
ver
license('test','Simulink')
license('test','Stateflow')
```

La compilation est volontairement demandée par `build_cuves`. Si MATLAB ne reconnaît pas un paramètre/API, conserver le message exact et la version ; la compatibilité doit être ajustée et retestée, pas supposée.

Si le diagnostic signale l'absence d'un compilateur pris en charge, configurer le compilateur requis par cette version de MATLAB avec `mex -setup` et suivre les indications MathWorks. Ce besoin dépend du poste et de la version.

## Contrôle des fichiers source

```matlab
files = dir(fullfile(pwd,'matlab','**','*.m'));
for k=1:numel(files)
    checkcode(fullfile(files(k).folder,files(k).name));
end
```

Ces contrôles statiques ne remplacent pas `validate_cuves`.

## Lecture de l'IHM

Utiliser le mode normal de simulation. Le générateur désactive la réduction de blocs et la réutilisation mémoire des sorties, et ajoute des blocs de mesure dédiés. Un RuntimeObject n'existe que pendant une simulation active ou en pause. Une erreur de lecture apparaît dans la zone de diagnostic de l'IHM.

Les mesures IHM sont des échantillons de supervision, environ toutes les 150 ms ; les CSV de `validate_cuves` contiennent les données de simulation au pas de 10 ms.

## Retour du bus et reset

Après une coupure, retirer la coupure et attendre que le bus soit disponible. Appuyer ensuite sur Réinitialiser. Le reset réinitialise également l'émulateur et le procédé ; pendant son impulsion, la disponibilité DP peut brièvement retomber. Le système reste à l'attente et demande un nouveau départ.

## Régénération

`build_cuves` reconstruit le modèle depuis les sources : une modification manuelle du `.slx` ne sera pas conservée lors d'une reconstruction. Pour garder une variante manuelle, utiliser Enregistrer sous avec un autre nom avant de relancer le générateur.
