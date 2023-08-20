#!/bin/env bash
			
clear
loadkeys la-latin1			
#----------------------------------------
#          Setting some vars
#----------------------------------------

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
	

#----------------------------------------
#          Getting Information   
#----------------------------------------

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

#----------------------------------------
#          Select DISK
#----------------------------------------

logo "Selecciona el disco para la instalacion"

# Mostrar información de los discos disponibles
echo "Discos disponibles:"
lsblk -d -e 7,11 -o NAME,SIZE,TYPE,MODEL
echo "------------------------------"
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

#----------------------------------------
#          Creando y Montando particion raiz
#----------------------------------------

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
			
		
#----------------------------------------
#          Creando y Montando SWAP
#----------------------------------------

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
	
#----------------------------------------
#          Info
#----------------------------------------
	
		printf "\n\n%s\n\n" "--------------------"
		printf " User:      %s%s%s\n" "${CBL}" "$USR" "${CNC}"
		printf " Hostname:  %s%s%s\n" "${CBL}" "$HNAME" "${CNC}"
	
	if [ "$swappart" = "Crear archivo swap" ]; then
			printf " Swap:      %sSi%s se crea archivo swap de 4G\n" "${CGR}" "${CNC}"
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


#----------------------------------------
#          Pacstrap base system
#----------------------------------------

logo "Instalando sistema base"

	#sed -i 's/#Color/Color/; s/#ParallelDownloads = 5/ParallelDownloads = 5/; /^ParallelDownloads =/a ILoveCandy' /etc/pacman.conf
	pacstrap /mnt \
	         base base-devel \
	         linux-zen linux-firmware \
	         dhcpcd \
	         intel-ucode \
	         mkinitcpio \
	         reflector \
	         git
	         
	okie
	clear

#----------------------------------------
#          Generating FSTAB
#----------------------------------------
    
logo "Generando FSTAB"

		genfstab -U /mnt >> /mnt/etc/fstab
		okie
	clear

#----------------------------------------
#          Timezone, Lang & Keyboard
#----------------------------------------
	
logo "Configurando Timezone y Locales"
		
	$CHROOT ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
	$CHROOT hwclock --systohc
	echo
	echo "es_AR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
	$CHROOT locale-gen
	echo "LANG=es_AR.UTF-8" >> /mnt/etc/locale.conf
	echo "KEYMAP=la-latin1" >> /mnt/etc/vconsole.conf
	export LANG=es_AR.UTF-8
	okie
	clear

#----------------------------------------
#          Hostname & Hosts
#----------------------------------------

logo "Configurando Internet"

	echo "${HNAME}" >> /mnt/etc/hostname
	cat >> /mnt/etc/hosts <<- EOL		
		127.0.0.1   localhost
		::1         localhost
		127.0.1.1   ${HNAME}.localdomain ${HNAME}
	EOL
	okie
	clear

#----------------------------------------
#          Users & Passwords
#----------------------------------------
    
logo "Usuario Y Passwords"

	echo "root:$PASSWDR" | $CHROOT chpasswd
	$CHROOT useradd -m -g users -G wheel -s /usr/bin/zsh "${USR}"
	echo "$USR:$PASSWD" | $CHROOT chpasswd
	sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/; /^root ALL=(ALL:ALL) ALL/a '"${USR}"' ALL=(ALL:ALL) ALL' /mnt/etc/sudoers
	echo "Defaults insults" >> /mnt/etc/sudoers
	printf " %sroot%s : %s%s%s\n %s%s%s : %s%s%s\n" "${CBL}" "${CNC}" "${CRE}" "${PASSWDR}" "${CNC}" "${CYE}" "${USR}" "${CNC}" "${CRE}" "${PASSWD}" "${CNC}"
	okie
	sleep 3
	clear

#----------------------------------------
#          Refreshing Mirrors
#----------------------------------------

logo "Refrescando mirros en la nueva Instalacion"

	$CHROOT reflector --verbose --latest 5 --country 'United States' --age 6 --sort rate --save /etc/pacman.d/mirrorlist >/dev/null 2>&1
	$CHROOT pacman -Syy
	okie
	clear

#----------------------------------------
#          Install GRUB
#----------------------------------------

logo "Instalando GRUB"

	$CHROOT pacman -S grub os-prober ntfs-3g --noconfirm >/dev/null
	$CHROOT grub-install --target=i386-pc "$drive"
	
	sed -i 's/quiet/zswap.enabled=0 mitigations=off nowatchdog/; s/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /mnt/etc/default/grub
	#sed -i "s/MODULES=()/MODULES=(intel_agp i915)/" /mnt/etc/mkinitcpio.conf
	echo
	$CHROOT grub-mkconfig -o /boot/grub/grub.cfg
	okie
	clear  

#----------------------------------------
#          Optimizations
#----------------------------------------

#logo "Aplicando optmizaciones.."

#	titleopts "Editando pacman. Se activan descargas paralelas, el color y el easter egg ILoveCandy"
#	sed -i 's/#Color/Color/; s/#ParallelDownloads = 5/ParallelDownloads = 5/; /^ParallelDownloads =/a ILoveCandy' /mnt/etc/pacman.conf
#	okie
    
#   titleopts "Optimiza y acelera ext4 para SSD"
#    sed -i '0,/relatime/s/relatime/noatime,commit=120,barrier=0/' /mnt/etc/fstab
#	$CHROOT tune2fs -O fast_commit "${partroot}" >/dev/null
#	okie
    
#    titleopts "Optimizando las make flags para acelerar tiempos de compilado"
#	printf "\nTienes %s%s%s cores\n" "${CBL}" "$(nproc)" "${CNC}"
#	sed -i 's/march=x86-64/march=native/; s/mtune=generic/mtune=native/; s/-O2/-O3/; s/#MAKEFLAGS="-j2/MAKEFLAGS="-j'"$(nproc)"'/' /mnt/etc/makepkg.conf
#	okie
    
#    titleopts "Configurando CPU a modo performance"
#	$CHROOT pacman -S cpupower --noconfirm >/dev/null
#	sed -i "s/#governor='ondemand'/governor='performance'/" /mnt/etc/default/cpupower
#	okie
    
#    titleopts "Cambiando el scheduler del kernel a mq-deadline"
#	cat >> /mnt/etc/udev/rules.d/60-ssd.rules <<- EOL
#		ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
#	EOL
#	okie

#	titleopts "Modificando swappiness"
#	cat >> /mnt/etc/sysctl.d/99-swappiness.conf <<- EOL
#		vm.swappiness=10
#		vm.vfs_cache_pressure=50
#	EOL
#	okie

#	titleopts "Deshabilitando Journal logs.."
#	sed -i 's/#Storage=auto/Storage=none/' /mnt/etc/systemd/journald.conf
#	okie
    
    titleopts "Desabilitando modulos del kernel innecesarios"
	cat >> /mnt/etc/modprobe.d/blacklist.conf <<- EOL
		blacklist iTCO_wdt
		blacklist mousedev
		blacklist mac_hid
		blacklist uvcvideo
	EOL
	okie
	
	titleopts "Deshabilitando servicios innecesarios"
	echo
	$CHROOT systemctl mask lvm2-monitor.service systemd-random-seed.service
	okie
	
#	titleopts "Acelerando internet con los DNS de Cloudflare"
#	if $CHROOT pacman -Qi dhcpcd > /dev/null ; then
#	cat >> /mnt/etc/dhcpcd.conf <<- EOL
#		noarp
#		static domain_name_servers=1.1.1.1 1.0.0.1
#	EOL
#		else
#	cat >> /mnt/etc/NetworkManager/conf.d/dns-servers.conf <<- EOL
#		[global-dns-domain-*]
#		servers=1.1.1.1,1.0.0.1
#	EOL
#	fi
#	okie

#	titleopts "Configurando almacenamiento personal"
#	cat >> /mnt/etc/fstab <<-EOL		
#	# My sTuFF
#	UUID=01D3AE59075CA1F0		/run/media/$USR/windows 	ntfs-3g		auto,rw,users,uid=1000,gid=984,dmask=022,fmask=133,big_writes,hide_hid_files,windows_names,noatime	0 0
#	EOL
	
#	okie
#	clear
	
#----------------------------------------
#          Installing Packages
#----------------------------------------

#logo "Instalando Audio & Video"

#    mkdir /mnt/dots
#	mount -U 6bca691d-82f3-4dd5-865b-994f99db54e1 -w /mnt/dots
		
	$CHROOT pacman -S \
					  mesa-amber xorg-server xf86-video-intel xorg-xinput xorg-xrdb xorg-xsetroot xorg-xwininfo xorg-xkill \
					  --noconfirm
					  	
	$CHROOT pacman -S \
					  pipewire pipewire-pulse \
					  --noconfirm
	clear
	
logo "Instalando codecs multimedia y utilidades"

	$CHROOT pacman -S \
                      ffmpeg ffmpegthumbnailer aom libde265 x265 x264 libmpeg2 xvidcore libtheora libvpx sdl \
                      jasper openjpeg2 libwebp webp-pixbuf-loader \
                      unarchiver lha lrzip lzip p7zip lbzip2 arj lzop cpio unrar unzip zip unarj xdg-utils \
                      --noconfirm
	clear
	
logo "Instalando soporte para montar volumenes y dispositivos multimedia extraibles"

	$CHROOT pacman -S \
					  libmtp gvfs-nfs gvfs gvfs-mtp \
					  dosfstools usbutils net-tools \
					  xdg-user-dirs gtk-engine-murrine \
					  --noconfirm
	clear

#logo "Instalando todo el entorno bspwm"

#	$CHROOT pacman -S \
#					  bspwm sxhkd polybar picom rofi dunst \
#					  alacritty ranger maim lsd feh polkit-gnome \
#					  mpd ncmpcpp mpc pamixer playerctl pacman-contrib \
#					  thunar thunar-archive-plugin tumbler xarchiver jq \
#					  zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting \
#					  --noconfirm
#	clear
	
logo "Instalando apps que yo uso"

	$CHROOT pacman -S \
					  bleachbit gcolor3 geany xdotool physlock ly \
					  htop ueberzug viewnior zathura zathura-pdf-poppler neovim \
					  retroarch retroarch-assets-xmb retroarch-assets-ozone libxxf86vm \
					  pass xclip yt-dlp minidlna grsync \
					  firefox firefox-i18n-es-mx pavucontrol \
					  papirus-icon-theme ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-joypixels ttf-inconsolata ttf-ubuntu-mono-nerd ttf-terminus-nerd \
					  --noconfirm
	clear
		
#----------------------------------------
#          AUR Packages
#----------------------------------------
	
	echo "cd && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm && cd" | $CHROOT su "$USR"
	
	#echo "cd && paru -S eww-x11 simple-mtpfs tdrop-git --skipreview --noconfirm --removemake" | $CHROOT su "$USR"
	#echo "cd && paru -S zramswap stacer --skipreview --noconfirm --removemake" | $CHROOT su "$USR"
	#echo "cd && paru -S spotify spotify-adblock-git mpv-git popcorntime-bin --skipreview --noconfirm --removemake" | $CHROOT su "$USR"
	#echo "cd && paru -S whatsapp-nativefier telegram-desktop-bin simplescreenrecorder --skipreview --noconfirm --removemake" | $CHROOT su "$USR"
	#echo "cd && paru -S cmatrix-git transmission-gtk3 qogir-icon-theme --skipreview --noconfirm --removemake" | $CHROOT su "$USR"

#----------------------------------------
#          Enable Services & other stuff
#----------------------------------------

logo "Activando Servicios"

	$CHROOT systemctl enable NetworkManager.service ly.service cpupower systemd-timesyncd.service
	$CHROOT systemctl enable zramswap.service
	echo "systemctl --user enable mpd.service" | $CHROOT su "$USR"

	echo "xdg-user-dirs-update" | $CHROOT su "$USR"
	echo "timeout 1s librewolf --headless" | $CHROOT su "$USR"
	#echo "export __GLX_VENDOR_LIBRARY_NAME=amber" >> /mnt/etc/profile
	sed -i 's/20/30/' /mnt/etc/zramswap.conf

#----------------------------------------
#          Xorg conf only intel
#----------------------------------------

	
#logo "Generating my XORG config files"
	
#	cat >> /mnt/etc/X11/xorg.conf.d/20-intel.conf <<EOL		
#Section "Device"
#	Identifier	"Intel Graphics"
#	Driver		"Intel"
#	Option		"AccelMethod"	"sna"
#	Option		"DRI"		"3"
#	Option		"TearFree"	"true"
#	Option 		"TripleBuffer" "true"
#EndSection
#EOL
#		printf "%s20-intel.conf%s generated in --> /etc/X11/xorg.conf.d\n" "${CGR}" "${CNC}"
		  
#	cat >> /mnt/etc/X11/xorg.conf.d/10-monitor.conf <<EOL
#Section "Monitor"
#	Identifier	"HP"
#	Option		"DPMS"	"true"
#EndSection

#Section "ServerFlags"
#	Option	"StandbyTime"	"120"
#	Option	"SuspendTime"	"120"
#	Option	"OffTime"	"120"
#	Option	"BlankTime"	"0"
#EndSection
	
#Section "ServerLayout"
#	Identifier	"ServerLayout0"
#EndSection
#EOL
#		printf "$%s10-monitor.conf$%s generated in --> /etc/X11/xorg.conf.d\n" "${CGR}" "${CNC}"
		
	cat >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf <<EOL
Section "InputClass"
		Identifier	"system-keyboard"
		MatchIsKeyboard	"on"
		Option	"XkbLayout"	"latam"
EndSection
EOL
		printf "%s00-keyboard.conf%s generated in --> /etc/X11/xorg.conf.d\n" "${CGR}" "${CNC}"
		
#	cat >> /mnt/etc/drirc <<EOL
#<driconf>

#	<device driver="i915">
#		<application name="Default">
#			<option name="stub_occlusion_query" value="true" />
#			<option name="fragment_shader" value="true" />
#		</application>
#	</device>
	
#</driconf>
#EOL
#		printf "%sdrirc%s generated in --> /etc" "${CGR}" "${CNC}"
#		sleep 2
		clear
	
#----------------------------------------
#          Reverting No Pasword Privileges
#----------------------------------------

	sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /mnt/etc/sudoers

		
	while true; do
			read -rp " Quieres reiniciar ahora? [s/N]: " sn
		case $sn in
			[Ss]* ) umount -a >/dev/null 2>&1;reboot;;
			[Nn]* ) exit;;
			* ) printf "Error: solo escribe 's' o 'n'\n\n";;
		esac
	done