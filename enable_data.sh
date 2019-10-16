#!/usr/bin/bash

#
# Script for Huawei E3372 USB LTE modem
# Connects to admin panel and enables mobile data
# 
# Home: https://github.com/Pernat1y/Huawei-E3372-scripts/
# 
# Tested on:
#    Device name: E3372
#    Hardware version: CL2E3372HM
#    Software version: 22.329.63.01.965
#

# Check for dependencies
if ! which curl &>/dev/null; then
    echo 'I need curl to work. Exiting.'
    exit 1
fi
if ! which usb_modeswitch &>/dev/null; then
    echo 'You may need usb_modeswitch to work properly.'
fi

# Check for modem
if lsusb | grep -e '12d1:14dc' -e '12d1:1f01' &>/dev/null; then
    # 12d1:14dc Huawei Technologies Co., Ltd. E33372 LTE/UMTS/GSM HiLink Modem/Networkcard
    # 12d1:1f01 Huawei Technologies Co., Ltd. E353/E3131 (Mass storage mode)
    echo 'Modem found.'
else
    echo 'Modem not found. Exiting.'
    exit 1
fi

# Switch modem mode
usb_modeswitch --default-vendor 12d1 --default-product 14dc --huawei-new-mode &>/dev/null

# Test web interface
if curl "http://192.168.8.1" --silent; then
    echo 'Connection to web interface successful'
else
    echo 'Unable to connect to web interface. Exiting.'
    exit 1
fi

# Obtain SessionID and __RequestVerificationToken
SesTokInfo=$(curl "http://192.168.8.1/api/webserver/SesTokInfo" --silent)
SessionID=$(echo "$SesTokInfo" | grep "SessionID=" | cut -b 20-147)
__RequestVerificationToken=$(echo "$SesTokInfo" | grep "TokInfo" | cut -b 10-41)

# Enable data
curl "http://192.168.8.1/api/dialup/mobile-dataswitch" \
     -H "Cookie: SessionID=$SessionID" \
     -H 'Origin: http://192.168.8.1' \
     -H 'Accept-Encoding: gzip, deflate' \
     -H 'Accept-Language: en-US,en;q=0.9,uk;q=0.8,ru;q=0.7' \
     -H 'User-Agent: Mozilla/5.0' \
     -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: */*' \
     -H 'Referer: http://192.168.8.1/html/mobileconnection.html' \
     -H 'X-Requested-With: XMLHttpRequest' \
     -H 'Connection: keep-alive' \
     -H "__RequestVerificationToken: $__RequestVerificationToken" \
     -H 'DNT: 1' \
     --data '<?xml version="1.0" encoding="UTF-8"?><request><dataswitch>1</dataswitch></request>' \
     --compressed \
     --insecure \
     --silent
curl "http://192.168.8.1/api/dialup/mobile-dataswitch" \
     -H "Cookie: SessionID=$SessionID" \
     -H 'DNT: 1' \
     -H 'Accept-Encoding: gzip, deflate' \
     -H 'Accept-Language: en-US,en;q=0.9,uk;q=0.8,ru;q=0.7' \
     -H 'User-Agent: Mozilla/5.0' \
     -H 'Accept: */*' \
     -H 'Referer: http://192.168.8.1/html/mobileconnection.html' \
     -H 'X-Requested-With: XMLHttpRequest' \
     -H 'Connection: keep-alive' \
     --compressed \
     --insecure \
     --silent

# Check status
# <ConnectionStatus>900</ConnectionStatus> - connecting
# <ConnectionStatus>901</ConnectionStatus> - connected
# <ConnectionStatus>902</ConnectionStatus> - disconnected
# <ConnectionStatus>903</ConnectionStatus> - disconnecting
curl "http://192.168.8.1/api/monitoring/status" \
     -H "Cookie: SessionID=$SessionID" \
     -H 'DNT: 1' \
     -H 'Accept-Encoding: gzip, deflate' \
     -H 'Accept-Language: en-US,en;q=0.9,uk;q=0.8,ru;q=0.7' \
     -H 'User-Agent: Mozilla/5.0' \
     -H 'Accept: */*' \
     -H 'Referer: http://192.168.8.1/html/mobileconnection.html' \
     -H 'X-Requested-With: XMLHttpRequest' \
     -H 'Connection: keep-alive' \
     --compressed \
     --insecure \
     --silent

