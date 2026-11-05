#!/usr/bin/env bash
# Installa Traincal per l'utente corrente (nessun sudo richiesto):
#   - compila la versione release
#   - copia l'app in ~/.local/opt/traincal
#   - crea il comando ~/.local/bin/traincal
#   - aggiunge la voce nel menu delle applicazioni con l'icona
#
# Uso: tool/install_linux.sh            installa o aggiorna
#      tool/install_linux.sh --remove   disinstalla (i dati restano in
#                                       ~/.local/share/it.traincal.traincal)
set -euo pipefail

APP_ID="it.traincal.traincal"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.local/opt/traincal"
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/512x512/apps"

if [[ "${1:-}" == "--remove" ]]; then
  rm -rf "$DEST" "$BIN/traincal" "$APPS/$APP_ID.desktop" "$ICONS/$APP_ID.png"
  update-desktop-database "$APPS" >/dev/null 2>&1 || true
  echo "Traincal disinstallato."
  exit 0
fi

FLUTTER="${FLUTTER:-$(command -v flutter || echo "$HOME/development/flutter/bin/flutter")}"
cd "$ROOT"
"$FLUTTER" build linux --release

# Sostituisce l'installazione precedente solo a build riuscita.
rm -rf "$DEST"
mkdir -p "$DEST" "$BIN" "$APPS" "$ICONS"
cp -r build/linux/x64/release/bundle/. "$DEST/"
cp assets/icon/traincal.png "$ICONS/$APP_ID.png"
ln -sf "$DEST/traincal" "$BIN/traincal"

cat > "$APPS/$APP_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Traincal
Comment=Allenamenti, fabbisogno calorico e meal prep
Exec=$DEST/traincal
Icon=$APP_ID
Terminal=false
Categories=Utility;Sports;
StartupWMClass=$APP_ID
EOF

update-desktop-database "$APPS" >/dev/null 2>&1 || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true

echo "Traincal installato in $DEST"
echo "Avvialo dal menu delle applicazioni o con: traincal"
