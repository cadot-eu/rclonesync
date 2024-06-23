#!/bin/bash

# Définition des valeurs par défaut
WATCH_DIR="$HOME/cloud"
REMOTE_DIR="gdrive:cloud"

BASEDIR=$(dirname "$0")
# Fichier temporaire pour les logs de rclone
LOG_FILE=${BASEDIR}/rclone_logs.txt
HTML_FILE=${BASEDIR}/rclone_logs.html

rm -f "$HTML_FILE"
touch "$HTML_FILE"

# Fonction d'affichage de l'aide
usage() {
    echo "Usage: $0 [-w <WATCH_DIR>] [-r <REMOTE_DIR>]"
    exit 1
}

# Lire les options de ligne de commande
while getopts ":w:r:" opt; do
    case ${opt} in
        w )
            WATCH_DIR=$OPTARG
            ;;
        r )
            REMOTE_DIR=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Fonction de synchronisation et mise à jour du fichier HTML des logs
sync() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Démarrage de la synchronisation avec rclone..."

    # Synchronisation avec rclone et redirection des logs vers un fichier temporaire
    rclone sync "$WATCH_DIR" "$REMOTE_DIR" --delete-during --ignore-existing --log-level=INFO --checksum --fast-list --transfers 16 > "$LOG_FILE" 2>&1

    echo "$(date +'%Y-%m-%d %H:%M:%S') - Synchronisation avec rclone terminée."

    # Filtrer les logs pour supprimer les lignes indésirables
filtered_logs=$(grep -v -E '^Transferred:|^Checks:|^Deleted:|^Elapsed time:|^.*There was nothing to transfer$' "$LOG_FILE" | grep -v -E '^.*INFO\s*:\s*$')

 

    # Vérifier s'il y a des nouveaux logs
    if [ -n "$filtered_logs" ]; then
        # Générer le contenu HTML pour les nouveaux logs
        new_logs="<div class=\"log-entry\"><pre>$(echo "$filtered_logs" | sed 's/</\&lt;/g; s/>/\&gt;/g')</pre></div>"

        # Vérifier si le fichier HTML existe déjà
        if [ -f "$HTML_FILE" ]; then
            # Lire le contenu actuel du fichier HTML sans la balise de fin </body> et </html>
            current_content=$(sed '/<\/body>/,$d' "$HTML_FILE")
        else
            # Si le fichier HTML n'existe pas, initialiser le contenu
            current_content=""
        fi

        # Générer le nouveau contenu HTML avec rafraîchissement automatique
        echo "<html>
<head>
  <title>Logs de Synchronisation rclone</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      padding: 20px;
    }
    .log-entry {
      border-bottom: 1px solid #ccc;
      padding: 10px;
      margin-bottom: 10px;
    }
    .log-time {
      font-weight: bold;
    }
    .log-message {
      color: #333;
    }
  </style>
  <meta http-equiv=\"refresh\" content=\"3\">
</head>
<body>
$new_logs
$current_content
</body>
</html>" > "$HTML_FILE"

        echo "Fichier HTML des logs mis à jour : $HTML_FILE"
    fi
}

# Appel initial de la fonction sync pour générer le fichier HTML des logs
sync

# Surveiller les modifications dans le répertoire $WATCH_DIR
echo "Surveillance des modifications dans le répertoire $WATCH_DIR..."

while inotifywait -r -e modify,create,delete,move "$WATCH_DIR"; do
    echo "Changement détecté, démarrage de la synchronisation..."
    sync
done
