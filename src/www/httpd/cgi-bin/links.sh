#!/bin/sh

# 0.4.1j

CONF_FILE="etc/system.conf"

YI_HACK_PREFIX="/tmp/sd/yi-hack-v5"

get_config()
{
    key=$1
    grep -w $1 $YI_HACK_PREFIX/$CONF_FILE | cut -d "=" -f2 | awk 'NR==1 {print; exit}'
}

LOCAL_IP_WLAN=$(ifconfig wlan0 | awk '/inet addr/{print substr($2,6)}')
LOCAL_IP_ETH=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')

if [[ $LOCAL_IP_WLAN != "" ]] ; then
    LOCAL_IP=$LOCAL_IP_WLAN
elif [[ $LOCAL_IP_ETH != "" ]] ; then
    LOCAL_IP=$LOCAL_IP_ETH
elif [[ $LOCAL_IP_WLAN == "" ]] && [[ $LOCAL_IP_ETH == "" ]] ; then
    LOCAL_IP="127.0.0.1"
fi

case $(get_config RTSP_PORT) in
    ''|*[!0-9]*) RTSP_PORT=554 ;;
    *) RTSP_PORT=$(get_config RTSP_PORT) ;;
esac
case $(get_config HTTPD_PORT) in
    ''|*[!0-9]*) HTTPD_PORT=80 ;;
    *) HTTPD_PORT=$(get_config HTTPD_PORT) ;;
esac

if [[ $RTSP_PORT != "554" ]] ; then
    D_RTSP_PORT=:$RTSP_PORT
fi
if [[ $HTTPD_PORT != "80" ]] ; then
    D_HTTPD_PORT=:$HTTPD_PORT
fi

printf "Content-type: application/json\r\n\r\n"
printf "{\n"

if [[ $(get_config RTSP) == "yes" ]] ; then
    if [[ $(get_config RTSP_STREAM) == "low" ]] ; then
        printf "\"%s\":\"%s\",\n" "low_res_stream"        "rtsp://$LOCAL_IP$D_RTSP_PORT/ch0_1.h264"
    elif [[ $(get_config RTSP_STREAM) == "high" ]] ; then
        printf "\"%s\":\"%s\",\n" "high_res_stream"       "rtsp://$LOCAL_IP$D_RTSP_PORT/ch0_0.h264"
    elif [[ $(get_config RTSP_STREAM) == "both" ]] ; then
        printf "\"%s\":\"%s\",\n" "low_res_stream"        "rtsp://$LOCAL_IP$D_RTSP_PORT/ch0_1.h264"
        printf "\"%s\":\"%s\",\n" "high_res_stream"       "rtsp://$LOCAL_IP$D_RTSP_PORT/ch0_0.h264"
    fi
    if [[ $(get_config RTSP_AUDIO) != "no" ]] && [[ $(get_config RTSP_AUDIO) != "none" ]] ; then
        printf "\"%s\":\"%s\",\n" "audio_stream"        "rtsp://$LOCAL_IP$D_RTSP_PORT/ch0_2.h264"
    fi
fi

printf "\"%s\":\"%s\",\n" "low_res_snapshot"      "http://$LOCAL_IP$D_HTTPD_PORT/cgi-bin/snapshot.sh?res=low&watermark=yes"
printf "\"%s\":\"%s\"\n" "high_res_snapshot"      "http://$LOCAL_IP$D_HTTPD_PORT/cgi-bin/snapshot.sh?res=high&watermark=yes"

printf "}"
