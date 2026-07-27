#!/bin/bash

function create_watchdogServ(){
    cat << EOF > /etc/systemd/system/wifi_watchdog.service
[Unit]
Description=Monitor and restart NetworkManager on connectivity loss
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wifi_watchdog.sh
EOF
return 0
}

function create_watchdogTimer(){
    cat << EOF > /etc/systemd/system/wifi_watchdog.timer
[Unit]
Description=Run the network watchdog every 6 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=6min

[Install]
WantedBy=timers.target
EOF
return 0
}

function create_wifi_watchdogscript(){
    cat << EOF > /usr/local/bin/wifi_watchdog.sh
#!/bin/bash
if ! ping -c 4 8.8.8.8 > /dev/null 2>&1 ; then
    echo "\$(date) -- No internet connection detected. Restarting NetworkManager" >> /var/log/wifi_watchdog.log
    systemctl restart NetworkManager
else
    exit 0
fi
EOF

    chmod +x /usr/local/bin/wifi_watchdog.sh

    return 0
}

function system_watchdog_enable(){
    if ! systemctl daemon-reload; then
        return 1
    fi
    if ! systemctl enable --now wifi_watchdog.timer ; then
        return 1
    fi
    return 0
}

create_wifi_watchdogscript
create_watchdogServ
create_watchdogTimer
system_watchdog_enable
