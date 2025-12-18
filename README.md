# TP FPGA Ecran magique réalisé par Soltani Ezer et BEN TEKFA Maram

## Introduction: 
Ce projet de TP consiste à réaliser une version numérique du télécran sur FPGA, en utilisant la sortie HDMI de la carte DE10-Nano. Le déplacement du pixel est contrôlé par les deux encodeurs rotatifs de la carte mezzanine.

Le projet est réalisé en plusieurs étapes : 
- Gestion des encodeurs.
- Affichage HDMI.
- Déplacement d’un pixel. 
- Mémorisation du tracé et effacement de l’écran.

### Gestion des encodeurs
Dans cette partie, nous avons travaillé uniquement sur deux encodeurs A et B: 
L'objectif est d'incrémenter la valeur d'un registre lorsque l'on tourne l'encodeur vers la droite, et de le décrémenter lorsqu'on le tourne vers la gauche

Les deux bascules D mémorisent le signal A à deux cycles d’horloge différents :
- La première contient la valeur actuelle de A,
- La seconde contient la valeur précédente.
En comparant ces deux valeurs :
--> Si A passe de 0 à 1, on détecte un front montant,
--> Si A passe de 1 à 0, on détecte un front descendant.

### Contrôleur HDMI
