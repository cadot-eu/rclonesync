#!/bin/bash

# Définition des valeurs par défaut
WATCH_DIR="$HOME/cloud"
REMOTE_DIR="gdrive:cloud"

BASEDIR=$(dirname "$0")
# Fichier temporaire pour les logs de rclone
LOG_FILE=${BASEDIR}/rclone_logs.txt

xfconf-query -c xfce4-notifyd -p /notification-log -s true

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

# Fonction de synchronisation et envoi de notifications
sync() {
    echo "Démarrage de la synchronisation avec rclone..."

    # Synchronisation avec rclone et redirection des logs vers un fichier temporaire
    rclone copy "$WATCH_DIR" "$REMOTE_DIR" --log-level=INFO --stats-one-line --checksum --fast-list --transfers 16 > "$LOG_FILE" 2>&1
    rclone copy "$REMOTE_DIR" "$WATCH_DIR" --log-level=INFO --stats-one-line --checksum --fast-list --transfers 16 >> "$LOG_FILE" 2>&1

    echo "Synchronisation avec rclone terminée."

    # Filtrer les logs pour supprimer les lignes indésirables
    filtered_logs=$(grep -v -E '^Transferred:|^Checks:|^Deleted:|^Elapsed time:|^.*There was nothing to transfer$' "$LOG_FILE" | grep -v -E '^.*INFO\s*:\s*$')

    # Écho des logs filtrés au terminal
    echo "Logs filtrés :"
    echo "$filtered_logs"

    # Envoi de notification avec les logs filtrés
    if [ -n "$filtered_logs" ]; then
        notify-send "Synchronisation rclone" "$filtered_logs"
    fi

}
# on lance pas le sync si on a un processus en cours qui s'appele rcloneSync.sh
if ! pgrep -x "rcloneSync.sh" > /dev/null
then
    sync
else    
    echo "rcloneSync.sh est en cours d'exécution. Merci de patienter..."
fi