#!/bin/bash

# Définition des valeurs par défaut
WATCH_DIR="$HOME/cloud"
REMOTE_DIR="gdrive:cloud"

BASEDIR=$(dirname "$0")
# Fichier temporaire pour les logs de rclone
LOG_FILE="${BASEDIR}/rclone_logs.txt"

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

    # Vérification de la phrase "There was nothing to transfer" dans les logs
    count=$(grep -o "There was nothing to transfer" "$LOG_FILE" | wc -l)

    if [ "$count" -eq 2 ]; then
        echo "Rien à faire. Fin du script."
        exit 0
    fi

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

# Fonction pour vérifier si le processus est en cours d'exécution
is_process_running() {
    local pid=$1
    if ps -p "$pid" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

script_name=$(basename "$0")

# Vérifie si le processus est déjà en cours d'exécution
pids=$(pgrep -f "$script_name")

# Filtrer pour exclure le PID de ce script en cours d'exécution
current_pid=$$
pids=$(echo "$pids" | grep -vw "$current_pid")

if [ -n "$pids" ]; then
    for pid in $pids; do
        if is_process_running "$pid"; then
            echo "Le processus $script_name est en cours d'exécution avec PID $pid."
            echo "$script_name est en cours d'exécution. Merci de patienter..."
            exit 1
        fi
    done
else
    echo "Aucun processus $script_name trouvé. Lancement de la synchronisation."
    sync
fi

