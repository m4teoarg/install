#!/bin/env bash
			
clear
loadkeys la-latin1			

#          Verificación de conexión a la red

network(){
testping=$(ping -q -c 1 -W 1 archlinux.org >/dev/null)

if $testping ; then
   ipx=$(curl -s www.icanhazip.com)
   isp=$(lynx -dump https://www.iplocation.net | grep "ISP:" | cut -d ":" -f 2- | cut -c 2-200)
   echo -e "IP: \e[32m$ipx\e[0m ISP: \e[32m$isp\e[0m"
else
echo -e "\e[31mProblema de red o desconectado\e[0m"
fi
pingx=$(ping -c 1 archlinux.org | head -n2 )
echo -e "\e[90m$pingx\e[0m"
echo ""
}

echo -e "\e[33mEstado de conexión\e[0m"

if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  network
else
 echo -e "\e[31mSistema desconectado\e[0m"
fi

echo ""

CRE=$(tput setaf 1)
CYE=$(tput setaf 3)
CGR=$(tput setaf 2)
CBL=$(tput setaf 4)
CBO=$(tput bold)
CNC=$(tput sgr0)
CHROOT="arch-chroot /mnt"

okie() {
	printf "\n%s OK...%s\n" "$CGR" "$CNC"
	sleep 2
}

titleopts () {
	
	local textopts="${1:?}"
	printf " \n%s>>>%s %s%s%s\n" "${CBL}" "${CNC}" "${CYE}" "${textopts}" "${CNC}"
}

logo() {
	
	local text="${1:?}"
	printf ' %s%s[%s %s %s]%s\n\n' "$CBO" "$CRE" "$CYE" "${text}" "$CRE" "$CNC"
}
	
logo "Modo de arranque"

	if [ -d /sys/firmware/efi/efivars ]; then	
			bootmode="uefi"
			printf " \e[31mEl escript se ejecutara en modo EFI\e[0m"
			sleep 2
			clear			
		else		
			bootmode="mbrbios"
			printf " \e[32mEl escript se ejecutara en modo BIOS/MBR\e[0m"
			sleep 2
			clear
	fi

#          Obteniendo información usuario, root, Hostname 


logo "Ingresa la informacion Necesaria"

while true; do
	read -rp "Ingresa tu usuario: " USR
		if [[ "${USR}" =~ ^[a-z][_a-z0-9-]{0,30}$ ]]; then
			break
		else
			printf "\n%sIncorrecto!! Solo se permiten minúsculas.%s\n\n" "$CRE" "$CNC"
		fi 		
done 

while true; do
    read -rsp "Ingresa tu password: " PASSWD
    echo
    read -rsp "Confirma tu password: " CONF_PASSWD

    if [ "$PASSWD" != "$CONF_PASSWD" ]; then
        printf "\n%sLas contraseñas no coinciden. Intenta nuevamente.!!%s\n\n" "$CRE" "$CNC"
    else
        printf "\n\n%sContraseña confirmada correctamente.\n\n%s" "$CGR" "$CNC"
        break
    fi
done

while true; do
    read -rsp "Ingresa tu password para ROOT: " PASSWDR
    echo
    read -rsp "Confirma tu password: " CONF_PASSWDR

    if [ "$PASSWDR" != "$CONF_PASSWDR" ]; then
        printf "\n%sLas contraseñas no coinciden. Intenta nuevamente.!!%s\n\n" "$CRE" "$CNC"
    else
        printf "\n\n%sContraseña confirmada correctamente.%s\n\n" "$CGR" "$CNC"
        break
    fi
done

while true; do
    read -rp "Ingresa el nombre de tu máquina: " HNAME
    
    if [[ "$HNAME" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]; then
        break
    else
        printf "%sIncorrecto!! El nombre no puede incluir mayúsculas ni símbolos especiales.%s\n\n" "$CRE" "$CNC"
    fi
done

clear



#          Seleccionar DISCO


logo "Selecciona el disco para la instalacion"

# Mostrar información de los discos disponibles
echo "Discos disponibles:"
lsblk -d -e 7,11 -o NAME,SIZE,TYPE,MODEL
echo "----"
echo

# Seleccionar el disco para la instalación de Arch Linux

PS3="Escoge el DISCO (NO la particion) donde Arch Linux se instalara: "
	select drive in $(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk') 
		do
			if [ "$drive" ]; then
				break
			fi
		done
clear


#          Creando y Montando particion raiz

logo "Creando Particiones"

			cfdisk "${drive}"
			clear
			
logo "Formatenado y Montando Particiones"

			lsblk "${drive}" -I 8 -o NAME,SIZE,FSTYPE,PARTTYPENAME
			echo
			
PS3="Escoge la particion raiz que acabas de crear donde Arch Linux se instalara: "
	select partroot in $(fdisk -l "${drive}" | grep Linux | cut -d" " -f1) 
		do
			if [ "$partroot" ]; then
				printf " \n Formateando la particion RAIZ %s\n Espere..\n" "${partroot}"
				sleep 2
				mkfs.ext4 -L Arch "${partroot}" >/dev/null 2>&1
				mount "${partroot}" /mnt
				sleep 2
				break
			fi
		done
					
			okie
			clear
			
		

#          Creando y Montando SWAP

logo "Configurando SWAP"

PS3="Escoge la particion SWAP: "
	select swappart in $(fdisk -l | grep -E "swap" | cut -d" " -f1) "No quiero swap" "Crear archivo swap"
		do
			if [ "$swappart" = "Crear archivo swap" ]; then
				
				printf "\n Creando archivo swap..\n"
				sleep 2
				fallocate -l 2048M /mnt/swapfile
				chmod 600 /mnt/swapfile
				mkswap -L SWAP /mnt/swapfile >/dev/null
				printf " Montando Swap, espera..\n"
				swapon /mnt/swapfile
				sleep 2
				okie
				break
					
			elif [ "$swappart" = "No quiero swap" ]; then
					
				break
					
			elif [ "$swappart" ]; then
				
				echo
				printf " \nFormateando la particion swap, espera..\n"
				sleep 2
				mkswap -L SWAP "${swappart}" >/dev/null 2>&1
				printf " Montando Swap, espera..\n"
				swapon "${swappart}"
				sleep 2
				okie
				break
			fi
		done
clear
	

#          Información
	
		printf "\n\n%s\n\n" "--------------------"
		printf " User:      %s%s%s\n" "${CBL}" "$USR" "${CNC}"
		printf " Hostname:  %s%s%s\n" "${CBL}" "$HNAME" "${CNC}"
	
	if [ "$swappart" = "Crear archivo swap" ]; then
			printf " Swap:      %sSi%s se crea archivo swap de 2G\n" "${CGR}" "${CNC}"
	elif [ "$swappart" = "No quiero swap" ]; then
			printf " Swap:      %sNo%s\n" "${CRE}" "${CNC}"
	elif [ "$swappart" ]; then
			printf " Swap:      %sSi%s en %s[%s%s%s%s%s]%s\n" "${CGR}" "${CNC}" "${CYE}" "${CNC}" "${CBL}" "${swappart}" "${CNC}" "${CYE}" "${CNC}"
	fi
		
			echo		
			printf "\n Arch Linux se instalara en el disco %s[%s%s%s%s%s]%s en la particion %s[%s%s%s%s%s]%s\n\n\n" "${CYE}" "${CNC}" "${CRE}" "${drive}" "${CNC}" "${CYE}" "${CNC}" "${CYE}" "${CNC}" "${CBL}" "${partroot}" "${CNC}" "${CYE}" "${CNC}"
		
	while true; do
			read -rp " ¿Deseas continuar? [s/N]: " sn
		case $sn in
			[Ss]* ) break;;
			[Nn]* ) exit;;
			* ) printf " Error: solo necesitas escribir 's' o 'n'\n\n";;
		esac
	done
clear

#          Pacstrap base system

logo "Instalando sistema base"
    pacstrap /mnt base base-devel linux linux-firmware mkinitcpio networkmanager git	         
	okie
clear

#          Generating FSTAB
    
logo "Generando FSTAB"

		genfstab -U /mnt >> /mnt/etc/fstab
		okie
clear

#          Timezone, Lang & Keyboard
	
logo "Configurando Timezone y Locales"
		
	$CHROOT ln -sf /usr/share/zoneinfo/America/Argentina/Buenos_Aires /etc/localtime
	$CHROOT hwclock --systohc
	echo
	echo "es_AR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	$CHROOT locale-gen
	echo "LANG=es_AR.UTF-8" >> /mnt/etc/locale.conf
	echo "KEYMAP=la-latin1" >> /mnt/etc/vconsole.conf
	export LANG=es_AR.UTF-8
	okie
clear

#          Hostname & Hosts

logo "Configurando Internet"

	echo "${HNAME}" >> /mnt/etc/hostname
	cat >> /mnt/etc/hosts <<- EOL		
		127.0.0.1   localhost
		::1         localhost
		127.0.1.1   ${HNAME}.localdomain ${HNAME}
	EOL
	okie
clear

#          Users & Passwords
    
logo "Usuario Y Passwords"

	echo "root:$PASSWDR" | $CHROOT chpasswd
	$CHROOT useradd -m -g users -G wheel "${USR}"
	echo "$USR:$PASSWD" | $CHROOT chpasswd
	sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/; /^root ALL=(ALL:ALL) ALL/a '"${USR}"' ALL=(ALL:ALL) ALL' /mnt/etc/sudoers
	echo "Defaults insults" >> /mnt/etc/sudoers
	printf " %sroot%s : %s%s%s\n %s%s%s : %s%s%s\n" "${CBL}" "${CNC}" "${CRE}" "${PASSWDR}" "${CNC}" "${CYE}" "${USR}" "${CNC}" "${CRE}" "${PASSWD}" "${CNC}"
	okie
	sleep 8
clear

logo "Instalando GRUB"

	if [ "$bootmode" == "uefi" ]; then
	
			$CHROOT pacman -S grub efibootmgr os-prober ntfs-3g --noconfirm >/dev/null
			$CHROOT grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch
		else		
			$CHROOT pacman -S grub os-prober ntfs-3g --noconfirm >/dev/null
			$CHROOT grub-install --target=i386-pc "$drive"
	fi
	
	sed -i 's/quiet/zswap.enabled=0 mitigations=off nowatchdog/; s/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /mnt/etc/default/grub
	sed -i "s/MODULES=()/MODULES=(${cpu_atkm})/" /mnt/etc/mkinitcpio.conf
	echo
	$CHROOT grub-mkconfig -o /boot/grub/grub.cfg
	okie
clear

#          Refreshing Mirrors

logo "Refrescando mirros en la nueva Instalacion"

	$CHROOT reflector --verbose --latest 5 --country 'United States' --age 6 --sort rate --save /etc/pacman.d/mirrorlist
	$CHROOT pacman -Syy
	okie
clear

#		Instalando gnome y servicios
logo "Instalando gnome y gdm"
# 		Instala GNOME, GDM y NetworkManager
		$CHROOT pacman -S \
						 gnome gdm \
						 mesa mesa-demos xorg-server xorg-xinit xf86-video-intel xorg-xinput xorg-xrdb xorg-xsetroot xorg-xwininfo xorg-xkill \
						 pipewire pipewire-pulse \
						 firefox git nano neovim gimp \
						 gvfs gvfs-nfs gvfs-mtp \
						 dosfstools usbutils net-tools \
						 xdg-user-dirs gtk-engine-murrine \
						 ffmpeg ffmpegthumbnailer aom libde265 x265 x264 libmpeg2 xvidcore libtheora libvpx sdl \
						 jasper openjpeg2 libwebp webp-pixbuf-loader \
						 unarchiver lha lrzip lzip p7zip lbzip2 arj lzop cpio unrar unzip zip unarj xdg-utils \
						 papirus-icon-theme ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-joypixels ttf-inconsolata ttf-ubuntu-mono-nerd ttf-terminus-nerd \		 
						 --noconfirm
		clear

logo "Activando Servicios"

	$CHROOT systemctl enable NetworkManager.service 
	$CHROOT systemctl enable gdm.service
	#$CHROOT systemctl enable zramswap.service
	#echo "systemctl --user enable mpd.service" | $CHROOT su "$USR"

	echo "xdg-user-dirs-update" | $CHROOT su "$USR"
	#echo "timeout 1s librewolf --headless" | $CHROOT su "$USR"
	#echo "export __GLX_VENDOR_LIBRARY_NAME=amber" >> /mnt/etc/profile
	#sed -i 's/20/30/' /mnt/etc/zramswap.conf
logo "Instalando PARU"
	sleep 2
		echo "cd && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm && cd" | $CHROOT su "$USR"
	clear

#          Xorg conf only intel

		
cat >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf <<EOL
Section "InputClass"
		Identifier	"system-keyboard"
		MatchIsKeyboard	"on"
		Option	"XkbLayout"	"latam"
EndSection
EOL
		printf "%s00-keyboard.conf%s generated in --> /etc/X11/xorg.conf.d\n" "${CGR}" "${CNC}"		

clear
	

#          Reversión de privilegios sin contraseña

	sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /mnt/etc/sudoers

		
	while true; do
			read -rp " Quieres reiniciar ahora? [s/N]: " sn
		case $sn in
			[Ss]* ) umount -R >/dev/null 2>&1;reboot;;
			[Nn]* ) exit;;
			* ) printf "Error: solo escribe 's' o 'n'\n\n";;
		esac
	done