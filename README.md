

Readme · MD
Projet A1 : feu tricolore avec passage piéton
Automatisme d'un carrefour simple : un feu voiture (vert, orange, rouge), un feu piéton (vert, rouge) et un bouton d'appel piéton. Le programme est écrit deux fois, avec la même logique : en Ladder (LD) et en Structured Text (ST), sous OpenPLC Editor V4.

Cahier des charges
Grafcet
Structure du dépôt
Version Ladder
Version ST
Simulation du bouton
Utilisation
Simulation visuelle
Tests
Choix de conception
Limites connues
Pistes d'amélioration
Cahier des charges
Entrées / sorties
Variable	Adresse	Type	Rôle
BP_PIETON	%IX0.0	Entrée	Bouton piéton
V_VERT	%QX0.0	Sortie	Feu voiture : vert
V_ORANGE	%QX0.1	Sortie	Feu voiture : orange
V_ROUGE	%QX0.2	Sortie	Feu voiture : rouge
P_VERT	%QX0.3	Sortie	Feu piéton : vert
P_ROUGE	%QX0.4	Sortie	Feu piéton : rouge
Comportement attendu
Au démarrage, tout est au rouge pendant 2 s (initialisation).
Sans appel piéton, le feu reste au vert voiture.
Le vert voiture dure 10 s minimum. Une demande piéton déclenche le cycle une fois ces 10 s écoulées.
Une demande piéton est mémorisée : un appui bref suffit.
Une demande faite pendant le passage piéton est gardée pour le cycle suivant.
Grafcet
Étape	Feux	Durée	Sortie de l'étape
0	Tout rouge	2 s	Après 2 s, vers l'étape 1
1	Vert voiture, rouge piéton	10 s minimum	Après 10 s et demande mémorisée, vers l'étape 2
2	Orange voiture, rouge piéton	3 s	Après 3 s, vers l'étape 3 (la demande est effacée à l'entrée de l'étape 3)
3	Rouge voiture, vert piéton	8 s	Après 8 s, vers l'étape 4
4	Tout rouge	2 s	Après 2 s, retour à l'étape 1
2 s écoulées
10 s écoulées ET demande
3 s écoulées, demandeeffacée
8 s écoulées
2 s écoulées
Étape 0 : tout rouge (2 s)
Étape 1 : vert voiture (10 smin)
Étape 2 : orange (3 s)
Étape 3 : vert piéton (8 s)
Étape 4 : tout rouge (2 s)
Table de vérité des sorties
Étape	V_VERT	V_ORANGE	V_ROUGE	P_VERT	P_ROUGE
0	0	0	1	0	1
1	1	0	0	0	1
2	0	1	0	0	1
3	0	0	1	1	0
4	0	0	1	0	1
Les deux feux ne sont jamais verts en même temps.

Structure du dépôt
.
├── README.md
├── .gitignore
├── ladder/      Projet OpenPLC Editor : version Ladder
├── st/          Projet OpenPLC Editor : version Structured Text
└── simulation/  Simulation visuelle du feu (page web : index.html)
Chaque dossier est un projet OpenPLC Editor complet. Le dossier build/ est généré à chaque compilation : il n'est pas versionné (voir .gitignore).

Version Ladder
Principe
Une variable booléenne par étape (E0 à E4). Une seule est vraie à la fois. E0 est initialisée à TRUE.
Une transition = un rung : contact de l'étape, puis bloc TON, puis, si besoin, un contact de condition, puis deux bobines en parallèle :
une bobine Reset (R) sur l'étape quittée ;
une bobine Set (S) sur l'étape suivante.
Les sorties sont déduites des étapes, dans des rungs placés en dernier.
Le jeton passe d'une étape à l'autre dans le même rung : il n'y a jamais deux étapes actives en même temps.

Ordre des rungs
Rungs	Rôle
1 à 5	Transitions 0→1, 1→2, 2→3, 3→4, 4→1, chacune avec son TON
6	Simulation du bouton (T_SIM)
7	Mémorisation de la demande (Set sur demande)
8 à 12	Sorties : V_VERT, V_ORANGE, V_ROUGE, P_VERT, P_ROUGE
Deux rungs de transition ont un comportement particulier :

Transition 1→2 : le contact demande est placé après la sortie Q du TON (10 s). Le TON compte toujours ses 10 s, mais la transition n'a lieu que si une demande est mémorisée.
Transition 2→3 : une troisième bobine, Reset sur demande, efface la demande à l'entrée de l'étape 3.
Variables
Nom	Type	Classe	Remarque
BP_PIETON	BOOL	Input	%IX0.0
V_VERT, V_ORANGE, V_ROUGE	BOOL	Output	%QX0.0 à %QX0.2
P_VERT, P_ROUGE	BOOL	Output	%QX0.3, %QX0.4
E0 à E4	BOOL	Local	Étapes du Grafcet, E0 = TRUE au départ
demande	BOOL	Local	Demande piéton mémorisée
bouton_sim	BOOL	Local	Impulsion du bouton simulé
TON (un par étape et un pour la simulation)	TON	Local	Temporisations
Version ST
Principe
Une seule variable entière etape (0 à 4) contient le numéro de l'étape active.
Le programme se lit de haut en bas en cinq blocs : simulation du bouton, mémorisation de la demande, temporisations, transitions (CASE), sorties.
Correspondance Ladder ↔ ST
Ladder	ST
Contact E1	etape = 1
Bobines R E1 + S E2	etape := 2;
Un rung de transition	Une branche du CASE
Bobine S demande	demande := TRUE;
Bobine R demande	demande := FALSE;
Contact demande en série	AND demande
Rungs de sortie	V_VERT := (etape = 1);
Code
pascal
(* ===== 1. Simulation du bouton (impulsion toutes les 25 s) ===== *)
T_SIM(IN := NOT T_SIM.Q, PT := T#25s);
bouton_sim := T_SIM.Q;

(* ===== 2. Mémorisation de la demande ===== *)
IF BP_PIETON OR bouton_sim THEN demande := TRUE; END_IF;

(* ===== 3. Temporisations (appelées à chaque cycle) ===== *)
T_INIT(IN := (etape = 0), PT := T#2s);
T_VERT(IN := (etape = 1), PT := T#10s);
T_ORANGE(IN := (etape = 2), PT := T#3s);
T_PIETON(IN := (etape = 3), PT := T#8s);
T_DEGAGE(IN := (etape = 4), PT := T#2s);

(* ===== 4. Transitions du Grafcet ===== *)
CASE etape OF
  0: IF T_INIT.Q THEN etape := 1; END_IF;
  1: IF T_VERT.Q AND demande THEN etape := 2; END_IF;
  2: IF T_ORANGE.Q THEN
       etape := 3;
       demande := FALSE;
     END_IF;
  3: IF T_PIETON.Q THEN etape := 4; END_IF;
  4: IF T_DEGAGE.Q THEN etape := 1; END_IF;
END_CASE;

(* ===== 5. Sorties déduites de l'étape ===== *)
V_VERT   := (etape = 1);
V_ORANGE := (etape = 2);
V_ROUGE  := (etape = 0) OR (etape = 3) OR (etape = 4);
P_VERT   := (etape = 3);
P_ROUGE  := (etape = 0) OR (etape = 1) OR (etape = 2) OR (etape = 4);
Variables
Nom	Type	Classe	Adresse / valeur initiale
BP_PIETON	BOOL	Input	%IX0.0
V_VERT, V_ORANGE, V_ROUGE	BOOL	Output	%QX0.0 à %QX0.2
P_VERT, P_ROUGE	BOOL	Output	%QX0.3, %QX0.4
etape	INT	Local	0
demande, bouton_sim	BOOL	Local	FALSE
T_INIT, T_VERT, T_ORANGE, T_PIETON, T_DEGAGE, T_SIM	TON	Local	
Simulation du bouton
Le projet est testé sans bouton physique. Une temporisation génère une impulsion d'un seul cycle toutes les 25 s :

le TON T_SIM compte tant que sa propre sortie Q est fausse ;
au bout de 25 s, Q passe à 1, ce qui coupe aussitôt IN : Q retombe au cycle suivant et le décompte repart ;
bouton_sim vaut donc 1 pendant un cycle, ce qui suffit puisque demande mémorise l'appui.
Avec un vrai bouton, BP_PIETON déclenche déjà la mémorisation (condition OU avec bouton_sim). Il suffit alors de supprimer la simulation : le rung T_SIM en Ladder, les deux premières lignes en ST.

Utilisation
Prérequis : OpenPLC Editor V4. Les noms exacts des boutons peuvent varier d'une version à l'autre.

Ouvrir le projet voulu (ladder/ ou st/) dans OpenPLC Editor.
Vérifier que la carte sélectionnée est OpenPLC Simulator.
Dans la table des variables, cocher la colonne Debug pour etape (ou E0 à E4), demande et les cinq sorties.
Cliquer sur Start Simulator (bouton Play de la barre d'activité). L'éditeur compile puis lance le programme.
Ouvrir le Debugger (icône bug) pour voir les variables évoluer sur un graphique.
Le Debugger ne conserve pas l'historique d'avant son ouverture : l'ouvrir juste après le démarrage.

Simulation visuelle
Le dossier simulation/ contient une page web interactive qui reproduit l'aspect d'un vrai feu tricolore : boîtier, lampes qui s'allument, bonhomme piéton rouge ou vert.

Démo en ligne (GitHub Pages) : https://abrahamwotto.github.io/projet-a1-feu-tricolore/simulation/

La page propose :

un bouton qui joue le rôle de BP_PIETON ;
les deux feux, avec les mêmes étapes et les mêmes durées que le Grafcet ;
l'étape active, une barre de progression, l'état de demande, les cinq sorties avec leurs adresses et un journal des transitions ;
une option « bouton simulé » (impulsion toutes les 25 s) et une vitesse ×5 ou ×10 pour tester plus vite.
Cette page est une réécriture en JavaScript de la même logique : elle n'est pas reliée à OpenPLC. Elle sert à visualiser et à démontrer le comportement du programme. Pour l'ouvrir en local, il suffit de double-cliquer sur simulation/index.html.

Tests
Ces tests s'appliquent aux deux versions (Ladder et ST) et ont été validés avec le simulateur OpenPLC. Les instants sont approximatifs et dépendent de la vitesse du simulateur.

#	Test	Réglage de T_SIM	Résultat attendu	Statut
1	Sans demande, le feu reste au vert voiture	T#1000s	À partir de 2 s, V_VERT reste allumé (étape 1)	✅
2	Une demande avant 10 s fait attendre la fin des 10 s	T#15s	Impulsion à ≈ 30 s, 2 s après le retour au vert : l'orange n'arrive qu'à ≈ 38 s	✅
3	Une demande après 10 s déclenche le cycle	T#25s	Orange à ≈ 25 s, juste après l'impulsion	✅
4	Une demande pendant les étapes 3 ou 4 est gardée pour le cycle suivant	T#15s	demande revient à 1 vers 45 s (étape 3) et reste à 1 pendant l'étape 4 (≈ 49 à 51 s)	✅
Chronologie attendue avec T#25s :

Instant	Étape	Feux allumés
0 s	0	Tout rouge
2 s	1	Vert voiture, rouge piéton
≈ 25 s	2	Orange, rouge piéton
≈ 28 s	3	Rouge voiture, vert piéton
≈ 36 s	4	Tout rouge
≈ 38 s	1	Retour au vert voiture
≈ 50 s	2	Orange (impulsion suivante)
Pour les tests 2 et 4, observer demande plutôt que bouton_sim : ce dernier ne dure qu'un cycle (20 ms) et reste presque invisible sur le graphique.

Choix de conception
Sorties déduites de l'étape. Chaque sortie est recalculée (ST) ou commandée par un rung dédié (Ladder) à partir de l'étape active. Aucune transition ne commande une sortie directement : une sortie ne peut pas rester allumée par erreur.
Temporisations appelées à chaque cycle. En ST, les TON sont en dehors du CASE. Appelés dans les branches, ils ne verraient jamais leur entrée IN retomber et ne se remettraient pas à zéro.
Set / Reset dans le même rung (Ladder). Le changement d'étape est instantané : pas de cycle intermédiaire où deux étapes seraient actives.
Mémorisation séparée des étapes. La demande est enregistrée à chaque cycle, quelle que soit l'étape active. C'est ce qui permet de garder un appui fait pendant le passage piéton.
Une même logique, deux langages. Le tableau de correspondance Ladder ↔ ST facilite la comparaison des deux versions.
Limites connues
Cas limite en ST. La mémorisation est placée avant le CASE. Un appui qui tombe exactement au cycle où l'étape 3 démarre est mémorisé puis effacé aussitôt. Avec un cycle de 20 ms, c'est très improbable. Pour l'éviter, déplacer le IF de mémorisation juste après le END_CASE. La version Ladder n'a pas ce défaut : la mémorisation est placée après les transitions.
Appel piéton pendant l'orange. Un appui pendant l'étape 2 est effacé à l'entrée de l'étape 3 : la demande est considérée comme déjà prise en compte, conformément au cahier des charges.
Simulation visuelle indépendante. La page web réimplémente la logique en JavaScript. Si le programme PLC change, la page doit être mise à jour à la main.
Durées fixes. Elles sont écrites en dur dans le programme (aucune configuration externe).
Pas de gestion de défaut. Une panne de lampe ou un mode dégradé (clignotement orange) ne sont pas traités.
Pistes d'amélioration
Passer les durées dans des variables constantes, pour les modifier à un seul endroit.
Ajouter un anti-rebond sur le bouton piéton réel.
Ajouter un mode nuit ou de défaut (orange clignotant).
Ajouter un feu piéton clignotant en fin de vert piéton.
Ajouter un second sens de circulation.


Auteur

Nom: WOTTO Abraham Miracle
Contact: wottoabrahammiracle@gmail.com

