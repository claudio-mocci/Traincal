#!/usr/bin/env bash
# Aggiorna Traincal su un telefono Android senza disinstallarlo (i dati
# restano: database locale, login, preferenze).
#
#   1. aumenta il numero di build in pubspec.yaml (1.0.0+1 -> 1.0.0+2)
#   2. compila l'APK release
#   3. lo installa sopra la versione esistente con `adb install -r`
#
# Uso: tool/install_android.sh [--no-bump] [--no-install] [--device SERIALE]
#   --no-bump      non cambia il numero di versione
#   --no-install   compila soltanto (APK da copiare a mano sul telefono)
#   --device S     dispositivo da usare se ce n'è più di uno (vedi `adb devices`)
#
# Non usare `flutter install`: disinstalla prima la versione vecchia e su
# Android cancella i dati dell'app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBSPEC="$ROOT/pubspec.yaml"
APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
KEYSTORE="$HOME/.android/debug.keystore"
FLUTTER="${FLUTTER:-$(command -v flutter || echo "$HOME/development/flutter/bin/flutter")}"
ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"

BUMP=1
INSTALL=1
DEVICE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-bump) BUMP=0 ;;
    --no-install) INSTALL=0 ;;
    --device) DEVICE="${2:?manca il seriale dopo --device}"; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Opzione sconosciuta: $1" >&2; exit 2 ;;
  esac
  shift
done

# L'APK release è firmato con la chiave di debug di questo PC: senza la stessa
# chiave Android rifiuta l'aggiornamento.
if [[ ! -f "$KEYSTORE" ]]; then
  echo "Attenzione: $KEYSTORE non esiste. Flutter ne creerà una nuova e" >&2
  echo "l'APK non potrà aggiornare quello già installato sul telefono." >&2
  read -r -p "Continuare comunque? [s/N] " ans
  [[ "$ans" == [sSyY]* ]] || exit 1
fi

# --- Versione -------------------------------------------------------------
ORIGINAL_VERSION="$(grep -E '^version:' "$PUBSPEC")"
if [[ $BUMP -eq 1 ]]; then
  if [[ ! "$ORIGINAL_VERSION" =~ ^version:\ ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
    echo "Formato di versione non riconosciuto: $ORIGINAL_VERSION" >&2
    exit 1
  fi
  NEW_VERSION="version: ${BASH_REMATCH[1]}+$((BASH_REMATCH[2] + 1))"
  sed -i "s/^version:.*/$NEW_VERSION/" "$PUBSPEC"
  # Se la compilazione fallisce, la versione torna com'era.
  trap 'sed -i "s/^version:.*/$ORIGINAL_VERSION/" "$PUBSPEC"; echo "Versione ripristinata." >&2' ERR
  echo "Versione: ${ORIGINAL_VERSION#version: } -> ${NEW_VERSION#version: }"
fi

# --- Compilazione ---------------------------------------------------------
cd "$ROOT"
"$FLUTTER" build apk --release
trap - ERR
echo "APK pronto: $APK"

if [[ $INSTALL -eq 0 ]]; then
  echo "Copialo sul telefono e aprilo: Android proporrà \"Aggiorna\"."
  exit 0
fi

# --- Installazione --------------------------------------------------------
if [[ ! -x "$ADB" ]]; then
  ADB="$(command -v adb || true)"
  [[ -n "$ADB" ]] || { echo "adb non trovato: installa l'APK a mano." >&2; exit 1; }
fi
ADB_ARGS=()
[[ -n "$DEVICE" ]] && ADB_ARGS=(-s "$DEVICE")

DEVICES="$("$ADB" devices | awk 'NR > 1 && $2 == "device" {print $1}')"
if [[ -z "$DEVICES" ]]; then
  echo "Nessun telefono collegato (o debug USB non autorizzato)."
  echo "Collegalo e rilancia con --no-bump, oppure copia l'APK sul telefono e aprilo."
  exit 0
fi
if [[ -z "$DEVICE" && $(wc -l <<< "$DEVICES") -gt 1 ]]; then
  echo "Più dispositivi collegati, scegline uno con --device:" >&2
  echo "$DEVICES" >&2
  exit 1
fi

# -r: sostituisce l'app installata mantenendo i dati. Mai disinstallare qui.
if OUT="$("$ADB" "${ADB_ARGS[@]}" install -r "$APK" 2>&1)"; then
  echo "$OUT" | tail -1
  echo "Traincal aggiornato sul telefono, dati conservati."
else
  echo "$OUT" >&2
  if grep -q "INSTALL_FAILED_UPDATE_INCOMPATIBLE" <<< "$OUT"; then
    echo >&2
    echo "La versione sul telefono è firmata con un'altra chiave (compilata altrove" >&2
    echo "o prima di questo PC): non si può aggiornare sopra. Disinstallala a mano" >&2
    echo "una volta (i dati locali andranno persi, quelli dell'account tornano col" >&2
    echo "login), poi rilancia con --no-bump." >&2
  elif grep -q "INSTALL_FAILED_VERSION_DOWNGRADE" <<< "$OUT"; then
    echo >&2
    echo "Sul telefono c'è una versione più recente: aumenta il numero dopo il '+'" >&2
    echo "in pubspec.yaml oltre a quello installato e rilancia." >&2
  fi
  exit 1
fi
