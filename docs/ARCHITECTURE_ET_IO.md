# Architecture et interfaces

## Chaîne de calcul

Les entrées de scénario ou d'IHM alimentent l'adaptation CPU. Le chart Stateflow `Sequence` décide de l'étape du programme CPU. La logique de sorties applique les interverrouillages. Les commandes locales atteignent le procédé ; VA-03 traverse l'émulateur DP. Le chart Stateflow `DP_Control` décide de l'état du maître DP et autorise les échanges d'octets. Le procédé produit niveaux et position. Les capteurs distants traversent le DP avant de revenir à la CPU.

Dans `Sequence`, les quatre étapes productives sont regroupées sous l'état parent `CYCLE_CPU`. Une transition du parent traite la perte du bus et une autre le reset, quelle que soit l'étape active. Dans `DP_Control`, les trois étapes d'initialisation et d'échange sont regroupées sous `SERVICE_DP`. Cette hiérarchie rend les interverrouillages communs explicites et les charts plus faciles à lire.

Deux blocs Unit Delay séparent les états physiques et les états reçus du calcul de la prochaine itération. Ils évitent les boucles algébriques et représentent une discrétisation de 10 ms ; ce délai ne représente pas une propriété garantie de PROFIBUS.

## Adressage de l'exercice

| Station | Signal | Adresse |
|---|---|---|
| CPU unité 1 | DCY1 | I0.0 |
| CPU unité 1 | NIV_BAS_CA | I0.1 |
| CPU unité 1 | CMD_VA01 | Q0.0 |
| CPU unité 1 | CMD_VA02 | Q0.1 |
| CPU unité 1 | CMD_AGT | Q0.2 |
| CPU unité 1 | CMD_PMP01 | Q0.3 |
| ET200M unité 2 | DCY2 | I4.0 |
| ET200M unité 2 | FDCO_VA03 | I4.1 |
| ET200M unité 2 | NIV_HAUT_CB | I4.2 |
| ET200M unité 2 | CMD_VA03 | Q4.0 |

Les désignations I/Q sont des repères conservés de TIA Portal : dans Simulink, il s'agit de signaux, pas d'adresses mémoire Siemens exécutables.

## Données cycliques représentées

- Image de sortie esclave : 2 octets, comme le module DQ 16. Octet Q4, bit 0 : ouverture VA-03. Les autres bits de Q4 et l'octet Q5 valent zéro.
- Image d'entrée esclave : 2 octets, comme le module DI 16. Octet I4, bit 0 : DCY2 ; bit 1 : VA-03 ouverte ; bit 2 : niveau haut B. Les autres bits et I5 valent zéro.
- Station maître : adresse 2 ; esclave : adresse 3 (documentation de configuration).
- La programmation manipule réellement des `uint8`, `bitset` et `bitget`. L'IHM affiche les premiers octets en hexadécimal.
- Les deux octets utilisateur ne constituent pas une trame PROFIBUS complète.

## État de service DP simplifié

Le chart `DP_Control` produit 0 : attente ; 1 : paramétrage représenté ; 2 : configuration représentée ; 3 : échange ; 4 : défaut de liaison. La disponibilité CPU n'est vraie qu'après un premier échange de données. Une coupure de liaison ou un âge de données de 100 ms fait entrer dans le défaut. La commande distante est mise à zéro. Après rétablissement, le chart refait la séquence d'initialisation. Les données de capteur restent mémorisées mais `busOK=0` interdit leur utilisation pour autoriser la pompe.

L'ET200M est une station d'E/S déportées et non une seconde CPU programmable. Stateflow représente donc le programme de la CPU et la machine d'états de la communication. Le bloc `DP_Emulator` réalise le codage et le décodage des octets uniquement lorsque `DP_Control` autorise l'échange.

Aucune émission de télégrammes normalisés, aucun FCS, aucun mécanisme FDL ou test de conformité n'est implémenté.

## Hypothèses physiques ajoutées

| Paramètre | Valeur | Justification |
|---|---|---|
| Capacité A / B | 100 L / 100 L | Choix pédagogique, non fourni par l'énoncé |
| A initial | 0 L | Niveau bas atteint |
| B initial | 0 L, ou 85 L dans high_B | Situation d'essai |
| Niveau bas A | <= 2 L | Seuil pédagogique |
| Niveau haut B | >= 90 L | Réserve sous le débordement |
| Débit P1 | 2 L/s | 20 L en 10 s |
| Débit P2 | 3 L/s | 15 L en 5 s |
| Débit pompe nominal | 4 L/s × ouverture VA-03 | Modèle simplifié |
| Dynamique VA-03 | premier ordre, constante 0,4 s | Attendre un retour réel |
| Retour vanne ouverte | position >= 95 % | Fin de course modélisé |
| Vidange pédagogique B | 3 L/s | Essai de reprise |

La proportion des deux produits n'est pas une simulation chimique ; l'agitation est une commande temporisée. Le mélange ne change pas le volume.

## Extensions par rapport à l'énoncé

- Surveillance continue de la confirmation d'ouverture et du niveau haut B.
- Perte du bus : commandes à zéro après watchdog et étape défaut mémorisée ; restauration puis réinitialisation requises.
- Reset d'essai : réinitialise aussi les volumes et la vanne du procédé virtuel.
- Vidange B et blocage de vanne : injections d'essai, pas actionneurs de l'énoncé.
- L'exercice d'origine est conservé à 10 s, 5 s et 15 s. La variante avec un seul temporisateur de 10 s n'est pas activée dans cette version.
