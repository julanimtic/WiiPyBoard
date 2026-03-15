// ============================================================
// WiiPyCercle - Déplace un cercle à l'aide de la Wii Balance Board
// ------------------------------------------------------------
// Reçoit les données UDP de la Balance Board (Python)
// et déplace le cercle à l'écran
//
// ============================================================

import hypermedia.net.*;

// ── Configuration ─────────────────────────────────────────────
int UDP_PORT = 5005;

// ── Variables UDP ─────────────────────────────────────────────
UDP udp;
int tr = 0, br = 0, tl = 0, bl = 0, total = 0;
int lastReceived = 0;

// ── Variables détection de déplacement ───────────────────────────────
float bougeX = 0;
float bougeY = 0;
float totalX = 0;
float totalY = 0;

// ── Setup ─────────────────────────────────────────────────────
void setup() {
  size(1280, 1080);
  textFont(createFont("Monospaced", 13));

  // Initialise UDP
  udp = new UDP(this, UDP_PORT);
  udp.listen(true);
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
    totalX = tr + br + (-tl) + (-bl);
    totalY = tr + (-br) + tl + (-bl);
  
  }
}

// ── Déplacement Cercle ─────────────────────────────────────────
void draw() {
  frameRate (30);
  background(0);
  fill (225, 173, 115);
  square (10, 10, 1060);

// les valeurs ajoutées à bougeX et bougeY sont là pour centrer le cercle. elles sont à adapter en fonction de la configuration
bougeX = 42 + map(totalX, -15030, 1700, 10, 1060);
bougeY = -20 + map(totalY, 16500, -800, 10, 1060);

  noStroke();
  fill(190, 204, 179);
  circle(bougeX, bougeY, 200);

  // Valeurs capteurs
  int px = width-200;
  int py = 90;

  fill(180);
  textSize(12);
  text("── Capteur ──", px, 65);
  fill(220);
  textSize(20);
  text("bougeX : " + bougeX, px, 90);
  text("bougeY : " + bougeY, px, py+40);
  text("tr : " + tr, px, py+80);
  text("tl : " + tl, px, py+120);
  text("br : " + br, px, py+160);
  text("bl : " + bl, px, py+200);
}
