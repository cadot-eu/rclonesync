#!/bin/bash
export DISPLAY=:0
# Définition des valeurs par défaut
WATCH_DIR="$HOME/cloud"
REMOTE_DIR="gdrive:cloud"
LOCK_FILE="/tmp/rcloneSync.lock"

BASEDIR=$(dirname "$0")
# Fichier temporaire pour les logs de rclone
LOG_FILE="${BASEDIR}/rclone_logs.txt"

# on active les notifications
xfconf-query -c xfce4-notifyd -p /notification-log --create > /dev/null
xfconf-query -c xfce4-notifyd -p /notification-log -s true > /dev/null

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
    # Création du fichier de verrouillage
    touch "$LOCK_FILE"
    echo "Démarrage de la synchronisation avec rclone..."
    # on vérifie l'absence de ~/.cache/rclone/bisync que bisync 
    if [ ! -d ~/.cache/rclone/bisync ]; then
    rclone bisync "$WATCH_DIR" "$REMOTE_DIR" --log-level=INFO --stats-one-line  --resync >> "$LOG_FILE" 2>&1
    else
    rclone bisync "$WATCH_DIR" "$REMOTE_DIR" --log-level=INFO --stats-one-line  --checksum --fast-list --transfers 16 > "$LOG_FILE" 2>&1
    fi
# on vérifie la présence dans le fichier log de cannot find prior et dans ce cas on relance la commande avec --resync
if grep -q "cannot find prior" "$LOG_FILE"; then
    rclone bisync "$WATCH_DIR" "$REMOTE_DIR" --log-level=INFO --stats-one-line  --resync >> "$LOG_FILE" 2>&1
fi

    echo "Synchronisation avec rclone terminée."

    # Filtrer les logs pour supprimer les lignes indésirables
filtered_logs=$(grep -v -E '^Transferred:|^Checks:|^Deleted:|^Elapsed time:|^.*There was nothing to transfer$|^.*INFO\s*:\s*$|0 B / 0 B|-|0 B/s|ETA -|bisync is EXPERIMENTAL|Synching Path1|checking for diffs|Applying changes|Updating listings|Validating listings|Do queued|Path1:|Path2:|, ETA|No changes found|Bisync successful' "$LOG_FILE" )


    # Écho des logs filtrés au terminal
    echo "$filtered_logs"

    # Envoi de notification avec les logs filtrés
    if [ -n "$filtered_logs" ]; then
        notify-send "Synchronisation rclone" "$filtered_logs"
    fi

    # Suppression du fichier de verrouillage
    rm -f "$LOCK_FILE"
    echo "Verrouillage supprimé."
}

# Fonction pour vérifier si le lock existe
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        echo "Le verrouillage existe. Fin du script."
        exit 0
    else
        sync
    fi
}

    check_lock
   

