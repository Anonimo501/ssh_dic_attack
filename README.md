# ssh_dic_attack

Este es un script bash que realiza un ataque de diccionario a un rango de ip /24 o /16 y en cada ip con ssh activo prueba las contraseñas del archivo que le pasemos por el protocolo ssh, si la contraseña es correcta mostrara en color rojo, si la ip no tiene ssh salta a la siguiente ip o si la ip rechaza la conexion tambien salta a la ip siguiente, esta por colores para que se entienda facilmente lo que hace esta haciendo el script.

![ssh dic attack](https://github.com/Anonimo501/ssh_dic_attack/assets/67207446/af61fb77-34fc-4d32-85a3-6170b5446ffd)

git clone https://github.com/Anonimo501/ssh_dic_attack.git

cd ssh_dic_attack

chmod +x ssh_dic_attack.sh

./ssh_dic_attack.sh
