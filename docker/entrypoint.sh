#!/bin/bash
set -euo pipefail 

# ==========================================
# 1. テンプレートから設定ファイルを作る関数
# ==========================================
generate_config_file() {
    TEMPLATE=$1
    OUT_DIR=$2
    OUT="$OUT_DIR/"$3

    if [[ ! -f "$TEMPLATE" ]]; then
        echo "ERROR: template file '$TEMPLATE' not found." >&2
        return 1
    fi

    mkdir -p "$OUT_DIR"

    TMP="$(mktemp "${OUT}.tmp.XXXXXX")"
    trap 'rm -f "$TMP"' EXIT

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line//\$USER_NAME/$USER_NAME}"
        line="${line//\$USER_PASSWORD/$USER_PASSWORD}"
        line="${line//\$USER_UID/$USER_UID}" 
        printf '%s\n' "$line" >> "$TMP"
    done < "$TEMPLATE"

    if grep -q '\$USER_' "$TMP"; then
        echo "Warning: Template still contains unsubstituted \$USER_ variables." >&2
    fi

    chmod 600 "$TMP"
    mv "$TMP" "$OUT"
    trap - EXIT
}

# ==========================================
# 2. 環境変数のバリデーション (UID/GIDを必須化)
# ==========================================
if [ -z "$USER_NAME" ] ||[ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
    echo "ERROR: USER_NAME, USER_UID, or USER_GID environment variable is not set. Container stopped."
    exit 1
fi

# ==========================================
# 3. tmpfs 実体ディレクトリの作成
# ==========================================
mkdir -p /tmp/log /tmp/xrdp_lib /tmp/tomcat_work /tmp/tomcat_temp /tmp/tomcat_logs 
mkdir -p /tmp/tomcat_catalina/localhost /tmp/run/xrdp
mkdir -p /tmp/run/dbus /tmp/run/pulse /tmp/guacamole /tmp/extrausers

chown xrdp:xrdp /tmp/run/xrdp
chown messagebus:messagebus /tmp/run/dbus
chmod 0755 /tmp/run/dbus

touch /tmp/log/xrdp.log /tmp/log/xrdp-sesman.log
chown xrdp:adm /tmp/log/xrdp.log /tmp/log/xrdp-sesman.log

rm -f /tmp/run/dbus/pid /tmp/run/dbus/system_bus_socket

# ==========================================
# 4. ユーザーの動的作成 (libnss-extrausers を使用)
# ==========================================
if ! id -u "$USER_NAME" >/dev/null 2>&1; then
    echo "$USER_NAME:x:$USER_UID:$USER_GID::/home/$USER_NAME:/bin/bash" > /tmp/extrausers/passwd
    
    SUDO_GID=$(getent group sudo | cut -d: -f3)
    echo "$USER_NAME:x:$USER_GID:" > /tmp/extrausers/group
    echo "sudo:x:$SUDO_GID:$USER_NAME" >> /tmp/extrausers/group
    
    if [ -z "$USER_PASSWORD" ]; then
        echo "$USER_NAME::19000:0:99999:7:::" > /tmp/extrausers/shadow
    else
        HASH=$(openssl passwd -6 "$USER_PASSWORD")
        echo "$USER_NAME:$HASH:19000:0:99999:7:::" > /tmp/extrausers/shadow
    fi
    
    chmod 0644 /tmp/extrausers/passwd /tmp/extrausers/group
    chmod 0640 /tmp/extrausers/shadow
    chown root:shadow /tmp/extrausers/shadow
fi

HOME_DIR="/home/$USER_NAME"

if [ ! -d "$HOME_DIR" ]; then
    sudo -u "$USER_NAME" mkdir -p "$HOME_DIR"
fi

mkdir -p /tmp/run/user/$USER_UID
chown $USER_UID:$USER_GID /tmp/run/user/$USER_UID
chmod 0700 /tmp/run/user/$USER_UID

# ==========================================
# 5. Guacamole 認証情報の動的生成
# ==========================================
cat <<EOF > /tmp/guacamole/guacamole.properties
guacd-hostname: 127.0.0.1
guacd-port: 4822
user-mapping: /etc/guacamole/user-mapping.xml
EOF

generate_config_file "/usr/local/etc/user-mapping-template.xml" "/tmp/guacamole" "user-mapping.xml"

# ==========================================
# 6. ユーザー環境セットアップ
# ==========================================
if [ ! -f "$HOME_DIR/.xsessionrc" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee "$HOME_DIR/.xsessionrc" > /dev/null
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TZ=Asia/Tokyo
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export NO_AT_BRIDGE=1
EOF
fi

if [ ! -f "$HOME_DIR/.bashrc" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee -a "$HOME_DIR/.bashrc" > /dev/null
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TZ=Asia/Tokyo
export DISPLAY=:10.0
export XDG_RUNTIME_DIR=/run/user/$USER_UID
EOF
fi

mkdir -p /tmp/.ICE-unix
chmod 1777 /tmp/.ICE-unix

sudo -u "$USER_NAME" mkdir -p "$HOME_DIR/.config/autostart" "$HOME_DIR/.config/fcitx5" "$HOME_DIR/.config/gtk-3.0" "$HOME_DIR/.config/xfce4"

if [ ! -f "$HOME_DIR/.config/autostart/fcitx5.desktop" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee "$HOME_DIR/.config/autostart/fcitx5.desktop" > /dev/null
[Desktop Entry]
Name=Fcitx 5
Exec=fcitx5 -d
Type=Application
EOF
fi

if [ ! -f "$HOME_DIR/.config/fcitx5/profile" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee "$HOME_DIR/.config/fcitx5/profile" > /dev/null
[Groups/0]
Name=Default
Default Layout=jp
DefaultIM=keyboard-jp

[Groups/0/Items/0]
Name=keyboard-jp

[Groups/0/Items/1]
Name=mozc

[GroupOrder]
0=Default
EOF
fi

if [ ! -f "$HOME_DIR/.config/gtk-3.0/bookmarks" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee "$HOME_DIR/.config/gtk-3.0/bookmarks" > /dev/null
file://$HOME_DIR/Documents
file://$HOME_DIR/Music
file://$HOME_DIR/Pictures
file://$HOME_DIR/Videos
file://$HOME_DIR/Downloads
EOF
fi

if [ ! -f "$HOME_DIR/.config/xfce4/helpers.rc" ]; then
cat <<EOF | sudo -u "$USER_NAME" tee "$HOME_DIR/.config/xfce4/helpers.rc" > /dev/null
WebBrowser=firefox
TerminalEmulator=xfce4-terminal
EOF
fi

if [ ! -f "$HOME_DIR/.config/xfce4/.desktop_setup_done" ]; then
cat << 'EOF' | sudo -u "$USER_NAME" tee "$HOME_DIR/.config/autostart/desktop-setup.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=XFCE Setup
Exec=bash -c "/usr/local/bin/desktop-setup.sh"
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
fi

CS_USER_DIR="/home/$USER_NAME/.local/share/code-server/User"
if  [ ! -f "$CS_USER_DIR/settings.json" ]; then
    sudo -u "$USER_NAME" mkdir -p "$CS_USER_DIR"
    sudo -u "$USER_NAME" cp /usr/local/etc/settings.json "$CS_USER_DIR/settings.json"
fi
CS_DATA_DIR="$HOME_DIR/.local/share/code-server"
sudo -u "$USER_NAME" mkdir -p "$CS_DATA_DIR"

if [ -f "/usr/local/bin/custom-setup.sh" ]; then
    echo "Running custom setup script..."
    /usr/local/bin/custom-setup.sh
fi

# ==========================================
# 7. Supervisor の起動
# ==========================================
generate_config_file "/usr/local/etc/supervisord-template.conf" "/tmp" "supervisord.conf"
if [ -z "$SUPERVISOR_LOG" ]; then
    echo "ERROR: SUPERVISOR_LOG environment variable is not set. Container stopped."
    exit 1
fi
SUPERVISOR_LOG="-s"
if [ "$SUPERVISOR_LOG" = "on" ] || [ "$SUPERVISOR_LOG" = "ON" ]; then
    SUPERVISOR_LOG=""
fi
exec supervisord $SUPERVISOR_LOG -n -c /tmp/supervisord.conf