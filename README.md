# WiiPyBoard
Python script for connecting a Wii Balance Board to a PC via a Raspberry Pi zero 2W using UDP protocol.

## Pré-requis
- Une Wii Balance Board
- Un Raspberry Pi zero 2W

Le script se lance sur un raspberry Pi zero 2w, il n'a pas été testé sur d'autres cartes.

Avant de lancer le script assurez-vous que votre Wii Balance Board se connecte en bluetooth à votre Raspberry Pi Zero 2W. Celle-ci devrait apparaitre sous le nom "Nintendo RVL-WBC-01". Profitez-en pour récupérer l'adresse MAC de la Wii Balance Board. pour appairer votre Wii Balance Board, il faudra appuyez sur le bouton rouge d'appairage situé dans le compartiment des piles.

## Configuration  
Avant de lancer le script modifiez la configuration du script lignes 13 à 16 :

Indiquez l'adresse MAC de la Wii Balance Board : 
- BALANCE_BOARD_ADDR = "XX:XX:XX:XX:XX:XX"

Indiquez l'adresse IP du PC sur lequel vous souhaitez envoyer les données via UDP : 
- UDP_IP = "192.168.XXX.XXX"

Indiquez le port UDP que vous souhaitez utiliser : 
- UDP_PORT = 10000

indiquez l'emplacement où vous souhaitez enregistrer les logs de connexion
- LOG_FILE = "/home/pi/Desktop/WiiPyBoard.log"

## Lancement

Appuyez sur le bouton rouge d'appairage de votre Wii Balance Board.
La lumière de la Wii Balance Board clignote rapidement.
Sur le Raspberry Pi Zero, lancez le script WiiPyBoard.py dans votre terminal.
Le script affiche dans le terminal les données récupérées par les capteurs de pression : TR, BR, TL, BL
- TR = Top Right
- BR = Bottom Right
- TL = Top Left
- BL = Bottom Left

  ## Utilisation

Sur votre PC, il vous faudra ensuite une application capable de récupérer et d'interpréter le flux de données via le protocole UDP. 
Dans le dossier applications vous trouverez deux exemples programmés via Processing : 
- le premier "WiiPyCercle" permet de déplacer un cercle en déplaçant son centre de gravité sur la Wii Balance Board.
- le second "WiiPyJumpCam" est un photomaton permettant de prendre une photo via la Webcam de votre PC lorsque vous sautez depuis la WiiBalanceBoard.
