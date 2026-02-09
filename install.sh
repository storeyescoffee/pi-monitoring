#!/bin/bash
set -euo pipefail

#############################################
# PARSE ARGUMENTS
#############################################

INSTALL_CAISSE=false
INSTALL_ALERT=false

while getopts "acb" opt; do
    case $opt in
        a) INSTALL_ALERT=true ;;
        c) INSTALL_CAISSE=true ;;
        b) INSTALL_CAISSE=true; INSTALL_ALERT=true ;;
        *)
            echo "Usage: $0 [-a] [-c] [-b]"
            echo "  -a  Install alert processor monitor"
            echo "  -c  Install caisse monitor"
            echo "  -b  Install both caisse and alert processor monitors"
            exit 1
            ;;
    esac
done

#############################################
# CLEAN UP OLD CRON JOBS
#############################################

echo "🧹 Removing old pi-monitoring cron jobs..."
crontab -l 2>/dev/null | grep -v "pi-monitoring" | crontab - 2>/dev/null || true

#############################################
# INSTALL DEPENDENCIES
#############################################

echo "📦 Installing dependencies..."
sudo apt update
sudo apt install mosquitto-clients jq -y

#############################################
# CAMERA MONITOR (ALWAYS INSTALLED)
#############################################

echo "✅ Setting execute permissions for camera monitor..."
chmod +x camera_monitor.sh

echo "📅 Installing camera monitor cron job..."
CAMERA_CRON="* * * * * $(pwd)/camera_monitor.sh >> /var/log/pi-monitoring.log 2>&1"
(crontab -l 2>/dev/null; echo "$CAMERA_CRON") | crontab -

echo "✅ Camera monitor installed successfully!"

#############################################
# CAISSE MONITOR (OPTIONAL)
#############################################

if [[ "$INSTALL_CAISSE" == "true" ]]; then
    echo ""
    echo "✅ Setting execute permissions for caisse monitor..."
    chmod +x caisse_monitor.sh
    
    echo "📅 Installing caisse monitor cron job..."
    CAISSE_CRON="* * * * * $(pwd)/caisse_monitor.sh >> /var/log/pi-monitoring.log 2>&1"
    (crontab -l 2>/dev/null; echo "$CAISSE_CRON") | crontab -
    
    echo "✅ Caisse monitor installed successfully!"
fi

#############################################
# ALERT PROCESSOR MONITOR (OPTIONAL)
#############################################

if [[ "$INSTALL_ALERT" == "true" ]]; then
    echo ""
    echo "✅ Setting execute permissions for alert processor monitor..."
    chmod +x alert_processor_monitor.sh
    
    echo "📅 Installing alert processor monitor cron job..."
    ALERT_CRON="* * * * * $(pwd)/alert_processor_monitor.sh >> /var/log/pi-monitoring.log 2>&1"
    (crontab -l 2>/dev/null; echo "$ALERT_CRON") | crontab -
    
    echo "✅ Alert processor monitor installed successfully!"
fi

#############################################
# SUMMARY
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Installed monitors:"
echo "  ✓ Camera Monitor"
[[ "$INSTALL_CAISSE" == "true" ]] && echo "  ✓ Caisse Monitor"
[[ "$INSTALL_ALERT" == "true" ]] && echo "  ✓ Alert Processor Monitor"
echo ""

if [[ "$INSTALL_CAISSE" == "false" ]] || [[ "$INSTALL_ALERT" == "false" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Optional monitors not installed:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    [[ "$INSTALL_CAISSE" == "false" ]] && echo "  • Caisse Monitor - run: ./install.sh -c"
    [[ "$INSTALL_ALERT" == "false" ]] && echo "  • Alert Processor Monitor - run: ./install.sh -a"
    echo "  • Install both - run: ./install.sh -b"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 View current cron jobs: crontab -l"
echo "💡 View logs: tail -f /var/log/pi-monitoring.log"
echo ""
