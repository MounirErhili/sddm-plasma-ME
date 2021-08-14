#!/bin/bash

if [[ $UID != 0 ]]; then
    echo "you don't have right permission to, please run this script as super user, use (sudo ./install.sh)!"
    exit 1
fi

err=0
current_dir="$(pwd)"
theme_name=sddm-plasma-ME
themes_dir=/usr/share/sddm/themes/
conf_dirs=(/usr/lib/sddm/sddm.conf.d/ /etc/sddm.conf.d/)
conf_files=

commands=(git egrep ping)
for i in ${commands[@]}; do
    command -v $i >&/dev/null || { err=2 && echo "command ($i) not found!"; }
done

if [[ $err -ne 0 ]]; then exit $err; fi

function cloneSfProFonts() {
    git clone https://github.com/MounirErhili/SF-Pro-Fonts.git
}

if [ ! -d ${themes_dir} ]; then
    echo "create '${themes_dir}'..."
    mkdir -p "${themes_dir}"
fi

if [ -f /etc/sddm.conf ]; then echo -e "found config file : /etc/sddm.conf" && conf_files="${conf_files} /etc/sddm.conf"; fi

for conf_dir in ${conf_dirs[@]}; do
    if [ -d "${conf_dir}" ]; then
        for conf_file in ${conf_dir}*.conf; do
            conf_files="${conf_files} ${conf_file}"
            echo -e "found config file : ${conf_file}"
        done
    fi
done

echo "found themes directory : ${themes_dir}"

if [ -d "${themes_dir}${theme_name}" ]; then rm -rf "${themes_dir}${theme_name}"; fi

echo "installing theme..."

mkdir -p "${themes_dir}${theme_name}"

cp -rf . "${themes_dir}${theme_name}/"

echo "configure theme..."

for conf_file in ${conf_files[@]}; do
    if [ -f "${conf_file}" ]; then
        e=$(egrep '^Current=' "${conf_file}")
        if [ "x${e}" == "x" ]; then continue; fi
        sed -i 's/'$e'/Current='$theme_name'/' "${conf_file}"
    fi
done

echo "installing fonts..."

cd fonts && {
        if find /usr/share/fonts/ -type f -iname "sf-pro-display*"|grep -i "sf-pro-display" >&/dev/null; then
            echo "font 'SF Pro Display' already installed in this system, skip!"
        elif [ -d ~/.fonts/ ] && find ~/.fonts/ -type f -iname "sf-pro-display*"|grep -i "sf-pro-display" >&/dev/null; then
            echo "font 'SF Pro Display' already installed in this system, skip!"
        elif [ -d ~/.local/share/fonts/ ] && find ~/.local/share/fonts/ -type f -iname "sf-pro-display*"|grep -i "sf-pro-display" >&/dev/null; then
            echo "font 'SF Pro Display' already installed in this system, skip!"
        else
            ping -c 2 8.8.8.8 >&/dev/null && {
                if [ -d SF-Pro-Fonts ]; then
                    if [ -d SF-Pro-Fonts/.git ]; then
                        echo "check for updates..."
                        cd SF-Pro-Fonts && git pull
                    else rm -rf SF-Pro-Fonts && echo "Downloading SF-Pro-Fonts..."; cloneSfProFonts; fi
                else echo "Downloading SF-Pro-Fonts..."; cloneSfProFonts; fi
            } || echo "install 'SF-Pro-Fonts' require internet connection, please connect to internet and try again!"
        fi
}

cd "${current_dir}"

cp -rf fonts/* /usr/share/fonts/

echo "update fonts cache..."

fc-cache -f

echo "clean up..."

rm -rf "${themes_dir}${theme_name}/"{fonts,Preview.xcf,components/artwork/background.xcf,install.sh}

echo "${theme_name} theme installed successfully!"
