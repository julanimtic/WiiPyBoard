#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import bluetooth
import struct
import socket
import time
import logging

# =============================================
# CONFIGURATION
# =============================================
BALANCE_BOARD_ADDR = "00:24:44:F2:18:DF"
UDP_IP = "192.168.1.75"
UDP_PORT = 5005
LOG_FILE = "/home/wiiboard/Desktop/wiiboard2.log"
# =============================================

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)


def connect_balance_board(addr, retries=3, delay=5):
    for attempt in range(1, retries + 1):
        log.info(f"Tentative de connexion {attempt}/{retries} a {addr}...")
        try:
            ctrl_sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
            data_sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
            ctrl_sock.connect((addr, 17))
            log.info("Canal de controle (port 17) connecte")
            data_sock.connect((addr, 19))
            log.info("Canal de donnees (port 19) connecte")
            return ctrl_sock, data_sock
        except bluetooth.BluetoothError as e:
            log.error(f"Echec connexion : {e}")
            if attempt < retries:
                log.info(f"Appuie sur SYNC ! Nouvelle tentative dans {delay}s...")
                time.sleep(delay)
            else:
                raise


def set_reporting_mode(ctrl_sock):
    """
    Séquence d'initialisation complète :
    1. Désactive les LEDs / rumble
    2. Active le reporting continu en mode Balance Board (0x32)
    """
    try:
        # Desactive le rumble et regle les LEDs (LED 1 allumee)
        ctrl_sock.send(b'\xa2\x11\x10')
        time.sleep(0.1)

        # Active le reporting continu mode 0x32 (Balance Board)
        ctrl_sock.send(b'\xa2\x12\x04\x32')
        time.sleep(0.1)

        log.info("Mode de reporting Balance Board active (0x32)")
    except Exception as e:
        log.error(f"Erreur activation reporting : {e}")
        raise


def parse_balance_board(data):
    """Top-Right, Bottom-Right, Top-Left, Bottom-Left"""
    tr = struct.unpack('>H', data[0:2])[0]
    br = struct.unpack('>H', data[2:4])[0]
    tl = struct.unpack('>H', data[4:6])[0]
    bl = struct.unpack('>H', data[6:8])[0]
    return tr, br, tl, bl


def main():
    log.info("=" * 50)
    log.info("Demarrage Wii Balance Board")
    log.info(f"Balance Board : {BALANCE_BOARD_ADDR}")
    log.info(f"Destination UDP : {UDP_IP}:{UDP_PORT}")
    log.info("=" * 50)

    # Connexion Bluetooth
    try:
        ctrl_sock, data_sock = connect_balance_board(BALANCE_BOARD_ADDR)
    except Exception:
        log.critical("Connexion impossible. Verifie que la Balance Board est allumee.")
        return

    # Socket UDP
    udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    log.info(f"Socket UDP pret -> {UDP_IP}:{UDP_PORT}")

    # Initialisation reporting
    set_reporting_mode(ctrl_sock)

    log.info("Lecture des donnees... (Ctrl+C pour arreter)")

    packet_count = 0
    udp_count = 0

    try:
        while True:
            try:
                raw = data_sock.recv(25)
                packet_count += 1

                log.debug(f"Paquet #{packet_count} ({len(raw)} octets) type={hex(raw[1]) if len(raw) > 1 else '?'} : {raw.hex()}")

                if len(raw) >= 12 and raw[1] == 0x32:
                    tr, br, tl, bl = parse_balance_board(raw[4:12])
                    total = tr + br + tl + bl

                    log.info(f"TR={tr:5d}  BR={br:5d}  TL={tl:5d}  BL={bl:5d} | Total={total:6d}")

                    message = f"{tr},{br},{tl},{bl}"
                    udp_sock.sendto(message.encode(), (UDP_IP, UDP_PORT))
                    udp_count += 1
                    log.debug(f"UDP #{udp_count} envoye : {message}")

                else:
                    # Affiche tous les types de paquets recus pour diagnostic
                    if len(raw) > 1:
                        log.debug(f"Paquet type {hex(raw[1])} ignore")

            except bluetooth.BluetoothError as e:
                log.error(f"Erreur Bluetooth : {e}")
                log.info("Tentative de reconnexion...")
                time.sleep(2)
                try:
                    ctrl_sock, data_sock = connect_balance_board(BALANCE_BOARD_ADDR)
                    set_reporting_mode(ctrl_sock)
                except Exception:
                    log.critical("Reconnexion impossible. Arret.")
                    break

    except KeyboardInterrupt:
        log.info("Arret demande (Ctrl+C)")

    finally:
        log.info(f"Bilan : {packet_count} paquets recus, {udp_count} messages UDP envoyes")
        ctrl_sock.close()
        data_sock.close()
        udp_sock.close()
        log.info("Connexions fermees.")


if __name__ == "__main__":
    main()
