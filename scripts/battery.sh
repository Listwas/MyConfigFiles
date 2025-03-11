#!/bin/bash
BATTERY="/sys/class/power_supply/BAT0"
capacity=$(cat "$BATTERY/capacity")
status=$(cat "$BATTERY/status")

case "$status" in
    "Charging")
        echo "%{F#00FF00} $capacity% ↑%{F-}"  
        ;;
    "Discharging")
        if [ "$capacity" -eq 60 ]; then
            echo "%{F#FFFF00} 60% =%{F-}"  
        else
            echo "%{F#FF0000} $capacity% ↓%{F-}" 
        fi
        ;;
    "Full")
        echo "%{F#FFFFFF} 100%%{F-}"  
        ;;
    *)
        echo "Battery: $capacity%"  
        ;;
esac
