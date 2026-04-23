#!/bin/bash
set -euo pipefail

if [ ! -f "$HOME/.config/xfce4/.desktop_setup_done" ]; then

# ==========================================
# 1. ユーザーディレクトリの確実な生成
# ==========================================
xdg-user-dirs-update

# ==========================================
# 2. xfce4-panel の完全な初期化を待機
# ==========================================
READY=false
for i in {1..20}; do
    if pgrep -x "xfce4-panel" > /dev/null && xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids >/dev/null 2>&1; then
        READY=true
        sleep 2
        break
    fi
    sleep 1
done

if [ "$READY" = false ]; then
    echo "Error: xfce4-panel did not initialize in time." >&2
    exit 1
fi

# ==========================================
# 3. パネル設定の書き換え (xfconf-query)
# ==========================================

CLOCK_PLUGIN=$(xfconf-query -c xfce4-panel -l -v | grep -w "clock" | awk '{print $1}' || true)
if [ -n "$CLOCK_PLUGIN" ]; then
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/mode -n -t uint -s 2
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/digital-format -n -t string -s "%Y/%m/%d %H:%M"
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/digital-time-format -n -t string -s "%R"
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/digital-layout -n -t uint -s 0
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/tooltip-format -n -t string -s "%x %A"
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/show-seconds -n -t bool -s false
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/flash-separators -n -t bool -s false
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/show-meridiem -n -t bool -s false
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/show-inactive -n -t bool -s false
    xfconf-query -c xfce4-panel -p $CLOCK_PLUGIN/digital-date-format -n -t string -s "%Y/%m/%d"
fi

ACTIONS_PLUGIN=$(xfconf-query -c xfce4-panel -l -v | grep -w "actions" | awk '{print $1}' || true)
if [ -n "$ACTIONS_PLUGIN" ]; then
    xfconf-query -c xfce4-panel -p $ACTIONS_PLUGIN -s "pulseaudio"
    xfconf-query -c xfce4-panel -p $ACTIONS_PLUGIN/enable-keyboard-shortcuts -n -t bool -s true
fi

xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -s 1 -s 2 -s 3 -s 4 -s 5 -s 10 -s 6 -s 7 -s 8 -s 9

PANEL_IDS=$(xfconf-query -c xfce4-panel -p /panels | tail -n +3 || true)

for panel_id in $PANEL_IDS; do
    PLUGIN_IDS=$(xfconf-query -c xfce4-panel -p /panels/panel-${panel_id}/plugin-ids | tail -n +3 || true)
    
    DELETED_IDS=""
    KEEP_IDS=""
    
    for id in $PLUGIN_IDS; do
        PLUGIN_TYPE=$(xfconf-query -c xfce4-panel -p /plugins/plugin-${id} -v 2>/dev/null || true)
        
        if [ "$PLUGIN_TYPE" = "launcher" ]; then
            ITEMS_OUTPUT=$(xfconf-query -c xfce4-panel -p /plugins/plugin-${id}/items -v 2>/dev/null || true)
            if echo "$ITEMS_OUTPUT" | grep -q "0 items"; then
                DELETED_IDS="$DELETED_IDS $id"
                continue
            fi
        fi
        KEEP_IDS="$KEEP_IDS $id"
    done
    
    if [ -n "$DELETED_IDS" ]; then
        CMD="xfconf-query -c xfce4-panel -p /panels/panel-${panel_id}/plugin-ids -n"
        for id in $KEEP_IDS; do
            CMD="$CMD -t int -s $id"
        done
        eval $CMD
    fi
done

# ==========================================
# 4. 壁紙とコンポジットの無効化
# ==========================================
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -n -t string -s ""
xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false

# ==========================================
# 5. 完了処理とパネルの確実な再起動
# ==========================================
touch "$HOME/.config/xfce4/.desktop_setup_done"
pkill -9 -x xfce4-panel || true
fi
