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
![Bascules](images/bascume.png)
Les deux bascules D mémorisent le signal A à deux cycles d’horloge différents :
- La première contient la valeur actuelle de A,
- La seconde contient la valeur précédente.
En comparant ces deux valeurs :
--> Si A passe de 0 à 1, on détecte un front montant,
--> Si A passe de 1 à 0, on détecte un front descendant.

### Contrôleur HDMI
Le contrôleur HDMI (`hdmi_controler.vhd`) est responsable de la génération des signaux de synchronisation nécessaires pour l'affichage sur un écran. Il génère les signaux de synchronisation horizontale (`HSYNC`), verticale (`VSYNC`) et de données actives (`DE`) pour une résolution de 720x480. Il fournit également en sortie l'adresse du pixel en cours de balayage, ce qui permet de lire la bonne donnée depuis la mémoire vidéo.

### Déplacement d’un pixel                                                                                     
Le déplacement du curseur est géré dans le fichier principal `telecran.vhd`. Deux instances du composant `encoder` sont utilisées, une pour l'axe X (encodeur gauche) et une pour l'axe Y (encodeur droit).                │
 - Chaque encodeur fournit un signal d'incrémentation et de décrémentation.                                      
 - Deux compteurs, `s_x_counter` et `s_y_counter`, mémorisent la position actuelle du curseur.                   
 - À chaque impulsion d'un encodeur, le compteur correspondant est mis à jour.                                   
 - La position du curseur est ensuite utilisée pour écrire dans la mémoire vidéo.
voici le test du déplacement du pixel:
![Deplacement](images/Deplacement_pixel.gif)                               
                                                                                                                 
 ### Mémorisation du tracé et effacement de l’écran                                                              
 La mémorisation du tracé est réalisée à l'aide d'une mémoire double port (`dpram.vhd`).                         
 - **Écriture (Port A) :** La position actuelle du curseur (`s_x_counter`, `s_y_counter`) est convertie en une adresse linéaire, et la valeur '1' est écrite à cette adresse dans la RAM. Cela a pour effet de "dessiner" un pixel blanc à la position du curseur.                                                                             
- **Lecture (Port B) :** Le contrôleur HDMI lit en continu la RAM à l'adresse correspondant au pixel actuellement affiché à l'écran. Si la valeur lue est '1', un pixel blanc est affiché, sinon un pixel noir.        
 voici le test de la mémorisation:
![memo](images/memorisation.gif)                                                                                                                  
 L'effacement de l'écran est déclenché par une pression sur le bouton poussoir de l'encodeur gauche. Un processus dédié parcourt alors toute la mémoire et écrit la valeur '0' dans chaque case, remettant ainsi l'écran au noir.
voici le test de l'effacement:
![effacement](images/effacement.gif)   
