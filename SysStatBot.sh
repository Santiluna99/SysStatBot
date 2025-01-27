#!/bin/bash

# token del bot de Telegram
TOKEN="7153902856:AAFuyErx3lMEswAmLBBIBbWXIZjHN2-MTEU"
# ID del chat
CHAT_ID="-4173191777"
# URL de la API de Telegram
API_URL="https://api.telegram.org/bot$TOKEN"

# función para obtener mensajes
get_updates() {
  curl -s "$API_URL/getUpdates"
}

# función para enviar respuestas
send_message() {
  local message=$1
  curl -s -X POST "$API_URL/sendMessage" -d chat_id="$CHAT_ID" -d text="$message"
}

# función principal para manejar comandos
handle_command() {
  local command=$1
  local argument=$2

  case "$command" in
    "/filesystem")
      if [ -z "$argument" ]; then
        send_message "Por favor, especifica un filesystem. Ejemplo: /filesystem /dev/sda1"
      else
        # valida si el filesystem existe
        if df | grep -q "$argument"; then

        get_fs_name(){
                df -h $argument --output=source,size,used,avail,pcent  | tail -n 1 | awk '{print $1}'
        }
        get_fs_size(){
                df -h $argument --output=source,size,used,avail,pcent  | tail -n 1 | awk '{print $2}'
        }
        get_fs_used(){
                df -h $argument --output=source,size,used,avail,pcent  | tail -n 1 | awk '{print $3}'
        }
        get_fs_available(){
                df -h $argument --output=source,size,used,avail,pcent  | tail -n 1 | awk '{print $4}'
        }
        get_fs_percent(){
                df -h $argument --output=source,size,used,avail,pcent  | tail -n 1 | awk '{print $5}'
        }
        fs_name=$(get_fs_name)
        fs_size=$(get_fs_size)
        fs_use=$(get_fs_used)
        fs_available=$(get_fs_available)
        fs_percent=$(get_fs_percent)

          filesystem_info=$(df -h "$argument" )
          send_message "📂 Información del sistema de archivos para $argument: El filesystem $fs_name tiene un espacio total de $fs_size se encuentra usando $fs_use hay disponible $fs_available y el porcentaje de uso es $fs_percent"
        else
          send_message "El filesystem '$argument' no existe o no es válido. 😕"
        fi
      fi
      ;;
        "/cpu")
        get_process_name() {
        ps -eo pid,comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $2}'
        }

        get_process_percent() {
        ps -eo pid,comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $3}'
        }

        get_process_id() {
        ps -eo pid,comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $1}'
        }
        process_name=$(get_process_name)
        process_percent=$(get_process_percent)
        process_id=$(get_process_id)
        send_message "El proceso que mas consume es: $process_name con un porcentaje de cpu de $process_percent y su pid es $process_id"
        ;;

        "/ram")
        get_ram_total() {
                free -h | grep Mem | awk '{print $2}'
        }
        get_ram_used() {
                free -h | grep Mem | awk '{print $3}'
        }
        get_ram_available(){
                free -h | grep Mem | awk '{print $7}'
        }

        ram_total=$(get_ram_total)
        ram_used=$(get_ram_used)
        ram_available=$(get_ram_available)
        send_message "La cantidad de RAM total es $ram_total de la cual esta siendo ocupada $ram_used y hay una disponibilidad de $ram_available"
        ;;
        "/uptime")
        get_uptime(){
                uptime | awk '{print $3}'| sed 's/,//'
        }
        uptime=$(get_uptime)
        send_message "🕑El sistema lleva encendido $uptime horas"
        ;;

        "/commands")
                send_message  "Los comandos que puede utilizar son %0A/cpu: Muestra el proceso que mas consume.%0A/ram: Muestra el estado de la memoria RAM.%0A/uptime: Muestra el tiempo de actividad del sistema.%0A/filesystem nombre_filesystem: Muestra informacion de un filesystem."
                ;;
        *)
      send_message "Comando no reconocido. 😕"
      ;;
  esac
}

# bucle principal
last_update_id=0
while true; do
  # obtiene mensajes nuevos
  updates=$(get_updates)
  
  # filtra el ID del último mensaje
  new_update_id=$(echo "$updates" | grep -o '"update_id":[0-9]*' | tail -1 | cut -d':' -f2)

  # si hay un mensaje nuevo
  if [[ "$new_update_id" != "$last_update_id" && "$new_update_id" != "" ]]; then
    # extrae el texto del mensaje
    message_text=$(echo "$updates" | grep -o '"text":"[^"]*"' | tail -1 | cut -d':' -f2 | tr -d '"')
    
    # extrae el comando y el argumento del mensaje
    command=$(echo "$message_text" | awk '{print $1}')
    argument=$(echo "$message_text" | awk '{print $2}')
    
    # procesa el comando
    handle_command "$command" "$argument"
    
    # actualiza el último ID de mensaje
    last_update_id="$new_update_id"
  fi

  # espera 1 segundo antes de la siguiente iteración
  sleep 1
done
