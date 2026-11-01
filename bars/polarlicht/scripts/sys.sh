#!/bin/sh
# Liefert Systemwerte zeilenweise für Hub.qml
awk '/^cpu /{print "cpu", $2+$3+$4+$5+$6+$7+$8+$9, $5+$6}' /proc/stat
awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print "mem", t, a}' /proc/meminfo
awk '{print "up", $1}' /proc/uptime
awk '{print "load", $1, $2, $3}' /proc/loadavg
for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name" 2>/dev/null)" in
        k10temp|coretemp|zenpower) [ -r "$h/temp1_input" ] && echo "cpuT $(cat "$h/temp1_input")" ;;
        amdgpu|nouveau) [ -r "$h/temp1_input" ] && echo "gpuT $(cat "$h/temp1_input")" ;;
    esac
done
df -Pk / | awk 'NR==2{print "disk", $3, $2}'
