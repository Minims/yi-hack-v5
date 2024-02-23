#!/bin/sh

# 0.4.1j

function print_help {
    echo "configure_wifi.sh"
    echo "will be used on next boot"
}

if [ -f "/tmp/sd/recover/mtdblock2_recover.bin" ]; then
    DATE=$(date '+%Y%m%d%H%M%S')
    dd if=/dev/mtdblock2 of=/tmp/sd/recover/mtdblock2_prerecover_$DATE.bin 2>/dev/null
    dd if=/tmp/sd/recover/mtdblock2_recover.bin of=/dev/mtdblock2 2>/dev/null
    mv /tmp/sd/recover/mtdblock2_recover.bin /tmp/sd/recover/mtdblock2_recover_done.bin
    reboot
fi

CFG_FILE=/tmp/configure_wifi.cfg
if [ ! -f "$CFG_FILE" ]; then
    echo "configure_wifi.cfg not found"
    exit 1
fi

TMP=$(cat $CFG_FILE | grep wifi_ssid=)
SSID=$(echo "${TMP:10}")
TMP=$(cat $CFG_FILE | grep wifi_psk=)
KEY=$(echo "${TMP:9}")

if [ -z "$SSID" ]; then
    echo "error: ssid has not been set"
    print_help
    exit 1
fi
if [ ${#SSID} -gt 63 ]; then
    echo "error: ssid is too long"
    print_help
    exit 1
fi

if [ -z "$KEY" ]; then
    echo "error: key has not been set"
    print_help
    exit 1
fi
if [ ${#KEY} -gt 63 ]; then
    echo "error: key is too long"
    print_help
    exit 1
fi

CURRENT_SSID=$(dd bs=1 skip=28 count=64 if=/dev/mtdblock2 2>/dev/null)
CURRENT_KEY=$(dd bs=1 skip=92 count=64 if=/dev/mtdblock2 2>/dev/null)

echo $SSID ${#SSID} - $CURRENT_SSID ${#CURRENT_SSID}
echo $KEY ${#KEY} - $CURRENT_KEY ${#CURRENT_KEY}

if [ "$SSID" == "$CURRENT_SSID" ] && [ "$KEY" == "$CURRENT_KEY" ]; then
    echo "ssid and key already configured"
    exit
fi

echo "creating partition backup..."
DATE=$(date '+%Y%m%d%H%M%S')
dd if=/dev/mtdblock2 of=/tmp/sd/mtdblock2_$DATE.bin 2>/dev/null

# clear the existing passwords (to ensure we are null terminated)
cat /dev/zero | dd of=/dev/mtdblock2 bs=1 seek=28 count=64 conv=notrunc
cat /dev/zero | dd of=/dev/mtdblock2 bs=1 seek=92 count=64 conv=notrunc
# write SSID
echo -n "$SSID" | dd of=/dev/mtdblock2 bs=1 seek=28 count=64 conv=notrunc
# write key
echo -n "$KEY" | dd of=/dev/mtdblock2 bs=1 seek=92 count=64 conv=notrunc
#write "connected" bit
printf "\00\00\00\00" | dd of=/dev/mtdblock2 bs=1 seek=24 count=4 conv=notrunc

sync
sync
sync
