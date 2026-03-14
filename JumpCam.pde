// ============================================================
// Jump Cam - Photo automatique quand quelqu'un saute
// ------------------------------------------------------------
// Reçoit les données UDP de la Balance Board (Python)
// et déclenche une photo webcam lors d'un saut détecté
//
// Prérequis : installer les librairies dans Processing
//   1. "UDP" de Stephane Cousot
//   2. "Video" de Processing Foundation (pour la webcam)
// ============================================================

import hypermedia.net.*;
import processing.video.*;

// ── Configuration ─────────────────────────────────────────────
final int   UDP_PORT          = 5005;
final int   SAUT_SEUIL        = 32000;   // total en dessous = saut détecté
final int   POIDS_MIN         = 38000;   // total minimum pour considérer qu'une personne est présente
final int   DELAI_PHOTO_MS    = 200;    // délai après détection du saut avant de prendre la photo (ms)
final int   DELAI_ENTRE_SAUTS = 3000;  // délai minimum entre deux photos (ms)
final String DOSSIER_PHOTOS   = "/Users/juliendevriendt/Desktop/photos/";

// ── Variables UDP ─────────────────────────────────────────────
UDP udp;
int tr = 0, br = 0, tl = 0, bl = 0, total = 0;
int lastReceived = 0;

// ── Variables détection de saut ───────────────────────────────
boolean personnePresente  = false;
boolean sautDetecte       = false;
boolean photoEnAttente    = false;
int     tempsDebutSaut    = 0;
int     dernierePhoto     = -DELAI_ENTRE_SAUTS;
int     nombrePhotos      = 0;

// ── Variables webcam ──────────────────────────────────────────
Capture webcam;
PImage  derniereCapture = null;
boolean webcamOk        = false;

// ── Variables affichage ───────────────────────────────────────
String  messageStatut = "En attente...";
int     couleurStatut = 0xFFAAAAAA;
float   flashAlpha    = 0;   // effet flash lors de la photo

// ── Setup ─────────────────────────────────────────────────────
void setup() {
  size(960, 600);
  textFont(createFont("Monospaced", 13));

  // Crée le dossier de photos si nécessaire
  File dir = new File(DOSSIER_PHOTOS);
  if (!dir.exists()) dir.mkdirs();

  // Initialise la webcam
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("Aucune webcam détectée !");
    messageStatut = "⚠ Aucune webcam détectée";
  } else {
    println("Webcams disponibles :");
    for (String c : cameras) println("  " + c);
    webcam = new Capture(this, 640, 480, cameras[0]);
    webcam.start();
    webcamOk = true;
    println("Webcam démarrée : " + cameras[0]);
  }

  // Initialise UDP
  udp = new UDP(this, UDP_PORT);
  udp.listen(true);
  println("En écoute UDP sur le port " + UDP_PORT); 

  messageStatut = "En attente de données... (montez sur la Balance Board)";
}

// ── Réception UDP ─────────────────────────────────────────────
void receive(byte[] data, String ip, int port) {
  String msg = new String(data).trim();
  String[] parts = split(msg, ',');

  if (parts.length == 4) {
    tr    = int(parts[0]);
    br    = int(parts[1]);
    tl    = int(parts[2]);
    bl    = int(parts[3]);
    total = tr + br + tl + bl;
    lastReceived = millis();
    detecterSaut();
  }
}

// ── Détection de saut ─────────────────────────────────────────
void detecterSaut() {
  int maintenant = millis();

  // Une personne est-elle sur la board ?
  if (total >= POIDS_MIN) {
    if (!personnePresente) {
      personnePresente = true;
      sautDetecte      = false;
      messageStatut    = "Personne détectée — Prêt ! Sautez !";
      couleurStatut    = color(100, 220, 100);
      println("Personne montée sur la board (total=" + total + ")");
    }
  }

  // Saut détecté : la personne était présente et le total chute sous le seuil
  if (personnePresente && !sautDetecte && total < SAUT_SEUIL) {
    // Vérifie le délai minimum entre deux photos
    if (maintenant - dernierePhoto > DELAI_ENTRE_SAUTS) {
      sautDetecte    = true;
      photoEnAttente = true;
      tempsDebutSaut = maintenant;
      messageStatut  = "SAUT DÉTECTÉ ! Photo dans " + DELAI_PHOTO_MS + "ms...";
      couleurStatut  = color(255, 200, 50);
      println("Saut détecté ! (total=" + total + ")");
    }
  }

  // La personne est redescendue
  if (personnePresente && total < POIDS_MIN / 2 && !photoEnAttente) {
    personnePresente = false;
    sautDetecte      = false;
    messageStatut    = "En attente... (montez sur la Balance Board)";
    couleurStatut    = color(170);
  }
}

// ── Prise de photo ────────────────────────────────────────────
void prendrePhoto() {
  if (!webcamOk || webcam == null) {
    println("Impossible de prendre une photo : pas de webcam");
    return;
  }

  // Capture l'image actuelle
  derniereCapture = webcam.get();

  // Génère le nom de fichier avec horodatage
  String timestamp = year() + nf(month(), 2) + nf(day(), 2)
                   + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
  String chemin = DOSSIER_PHOTOS + "saut_" + timestamp + ".png";

  derniereCapture.save(chemin);
  nombrePhotos++;

  flashAlpha    = 255;
  dernierePhoto = millis();
  messageStatut = "📸 Photo #" + nombrePhotos + " sauvegardée !";
  couleurStatut = color(100, 180, 255);

  println("Photo sauvegardée : " + chemin);

  // Réinitialise pour la prochaine détection
  sautDetecte      = false;
  photoEnAttente   = false;
  personnePresente = false;
}

// ── Mise à jour webcam ────────────────────────────────────────
void captureEvent(Capture c) {
  c.read();
}

// ── Draw ──────────────────────────────────────────────────────
void draw() {
  background(25);

  // Déclenche la photo après le délai
  if (photoEnAttente && millis() - tempsDebutSaut >= DELAI_PHOTO_MS) {
    photoEnAttente = false;
    prendrePhoto();
  }

  // ── Colonne gauche : flux webcam ──
  if (webcamOk && webcam != null) {
    // Affiche le flux webcam en direct
    image(webcam, 10, 10, 640, 480);

    // Effet flash blanc lors de la photo
    if (flashAlpha > 0) {
      fill(255, flashAlpha);
      noStroke();
      rect(10, 10, 640, 480);
      flashAlpha = max(0, flashAlpha - 12);
    }
  } else {
    fill(50);
    noStroke();
    rect(10, 10, 640, 480);
    fill(150);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("Pas de webcam", 330, 250);
  }

  // ── Colonne droite : infos ────────
  int px = 670;

  // Statut connexion Balance Board
  boolean connectee = (millis() - lastReceived) < 1000;
  fill(connectee ? color(100, 220, 100) : color(200, 80, 80));
  noStroke();
  ellipse(px + 8, 25, 14, 14);
  fill(connectee ? color(100, 220, 100) : color(200, 80, 80));
  textSize(12);
  textAlign(LEFT);
  text(connectee ? "Balance Board connectée" : "Balance Board déconnectée", px + 20, 30);

  // Valeurs capteurs
  fill(180);
  textSize(12);
  text("── Capteurs ──────────────", px, 65);
  fill(220);
  textSize(13);
  text("TL : " + tl, px, 90);
  text("TR : " + tr, px, 108);
  text("BL : " + bl, px, 126);
  text("BR : " + br, px, 144);

  // Barre de poids total
  fill(180);
  textSize(12);
  text("── Poids total ───────────", px, 172);
  float barW  = 260;
  float ratio = constrain(map(total, 0, 80000, 0, barW), 0, barW);
  stroke(80);
  strokeWeight(1);
  noFill();
  rect(px, 182, barW, 18, 4);
  noStroke();
  fill(total < SAUT_SEUIL ? color(255, 80, 80) : total < POIDS_MIN ? color(255, 200, 50) : color(100, 220, 100));
  rect(px, 182, ratio, 18, 4);
  fill(255);
  textSize(11);
  textAlign(CENTER);
  text(total, px + barW / 2, 196);
  textAlign(LEFT);

  // Seuils
  fill(150);
  textSize(11);
  text("Seuil saut    < " + SAUT_SEUIL, px, 218);
  text("Seuil présence > " + POIDS_MIN, px, 233);

  // Statut principal
  fill(180);
  textSize(12);
  text("── Statut ────────────────", px, 260);
  fill(couleurStatut);
  textSize(13);
  text(messageStatut, px, 280);

  // Miniature dernière photo
  if (derniereCapture != null) {
    fill(180);
    textSize(12);
    textAlign(LEFT);
    text("── Dernière photo ────────", px, 320);
    image(derniereCapture, px, 330, 260, 195);
  }

  // Compteur photos
  fill(150);
  textSize(12);
  textAlign(LEFT);
  text("Photos prises : " + nombrePhotos, px, 548);
  text("Dossier : " + DOSSIER_PHOTOS, px, 565);
  text("Port UDP : " + UDP_PORT, px, 582);
}
