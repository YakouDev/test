#!/usr/bin/env bash
#
# Description: A Bench Script by Teddysun
#
# Copyright (C) 2015 - 2024 Teddysun <i@teddysun.com>
# Thanks: LookBack <admin@dwhd.org>
# URL: https://teddysun.com/444.html
# https://github.com/teddysun/across/blob/master/bench.sh
#
trap _exit INT QUIT TERM

_red() {
    printf '\033[0;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[0;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[0;31;33m%b\033[0m' "$1"
}

_blue() {
    printf '\033[0;31;36m%b\033[0m' "$1"
}

_exists() {
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

_exit() {
    _red "\nThe script has been terminated. Cleaning up files...\n"
    # clean up
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    local nodeName="$2"
    if [ -z "$1" ];then
        ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr >./speedtest-cli/speedtest.log 2>&1
    else
        ./speedtest-cli/speedtest --progress=no --server-id="$1" --accept-license --accept-gdpr >./speedtest-cli/speedtest.log 2>&1
    fi
    if [ $? -eq 0 ]; then
        local dl_speed up_speed latency
        dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        latency=$(awk '/Latency/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        if [[ -n "${dl_speed}" && -n "${up_speed}" && -n "${latency}" ]]; then
            printf "\033[0;33m%-18s\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" " ${nodeName}" "${up_speed}" "${dl_speed}" "${latency}"
        fi
    fi
}

speed() {
    speed_test '43860' 'Dallas, US'
    speed_test '46143' 'Toronto, CA'
    speed_test '54754' 'Mexico City, MX'
    speed_test '37536' 'London, UK'
    speed_test '23094' 'Amsterdam, NL'
    speed_test '35692' 'Frankfurt, DE'
    speed_test '50686' 'Tokyo, JP'
    speed_test '44340' 'Hong Kong, CN'
    speed_test '4235'  'Singapore, SG' 
    speed_test '13039' 'Jakarta, ID'
}

iotest() {
  echostyle "## IO Test"
  echo "" | tee -a $log

  # start testing
  writemb=$(freedisk)
  if [[ $writemb -gt 512 ]]; then
    writemb_size="$(( writemb / 2 / 2 ))MB"
    writemb_cpu="$(( writemb / 2 ))"
  else
    writemb_size="$writemb"MB
    writemb_cpu=$writemb
  fi

  # CPU Speed test
  echostyle "CPU Speed:"
  echo "    bzip2     :$( cpubench bzip2 $writemb_cpu )" | tee -a $log 
  echo "   sha256     :$( cpubench sha256sum $writemb_cpu )" | tee -a $log
  echo "   md5sum     :$( cpubench md5sum $writemb_cpu )" | tee -a $log
  echo "" | tee -a $log

  # RAM Speed test
  # set ram allocation for mount
  tram_mb="$( free -m | grep Mem | awk 'NR=1 {print $2}' )"
  if [[ tram_mb -gt 1900 ]]; then
    sbram=1024M
    sbcount=2048
  else
    sbram=$(( tram_mb / 2 ))M
    sbcount=$tram_mb
  fi
  [[ -d $benchram ]] || mkdir $benchram
  mount -t tmpfs -o size=$sbram tmpfs $benchram/
  echostyle "RAM Speed:"
  iow1=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  ior1=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  iow2=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  ior2=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  iow3=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  ior3=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  echo "   Avg. write : $(averageio "$iow1" "$iow2" "$iow3") MB/s" | tee -a $log
  echo "   Avg. read  : $(averageio "$ior1" "$ior2" "$ior3") MB/s" | tee -a $log
  rm $benchram/zero
  umount $benchram
  rm -rf $benchram
  echo "" | tee -a $log
  
  # Disk test
  #echostyle "Disk Speed:"
  #if [[ $writemb != "1" ]]; then
  # io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  # echo "   I/O Speed  :$io" | tee -a $log

  # io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test oflag=direct; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
  # echo "   I/O Direct :$io" | tee -a $log
  #else
  # echo "   Not enough space to test." | tee -a $log
  #fi
  #echo "" | tee -a $log
}


write_io() {
  writemb=$(freedisk)
  writemb_size="$(( writemb / 2 ))MB"
  if [[ $writemb_size == "1024MB" ]]; then
    writemb_size="1.0GB"
  fi

  if [[ $writemb != "1" ]]; then
    echostyle "Disk Speed:"
    echo -n "   1st run    : " | tee -a $log
    io1=$( write_test $writemb )
    echo -e "$io1" | tee -a $log
    echo -n "   2nd run    : " | tee -a $log
    io2=$( write_test $writemb )
    echo -e "$io2" | tee -a $log
    echo -n "   3rd run    : " | tee -a $log
    io3=$( write_test $writemb )
    echo -e "$io3" | tee -a $log
    ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
    [ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
    ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
    [ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
    ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
    [ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
    ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
    ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
    echo -e "   -----------------------" | tee -a $log
    echo -e "   Average    : $ioavg MB/s" | tee -a $log
  else
    echo -e " Not enough space!"
  fi
}

geekbench6() {
  if [[ $ARCH = *x86* ]]; then # 32-bit
  echo -e "\nGeekbench 6 cannot run on 32-bit architectures. Skipping the test"
  else
  echo "" | tee -a $log
  echo -e " Performing Geekbench v6 CPU Benchmark test. Please wait..."

  GEEKBENCH_PATH=$HOME/geekbench
  mkdir -p $GEEKBENCH_PATH
  curl -s https://cdn.geekbench.com/Geekbench-6.3.0-Linux.tar.gz | tar xz --strip-components=1 -C $GEEKBENCH_PATH &>/dev/null
  GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench6 2>/dev/null | grep "https://browser")
  GEEKBENCH_URL=$(echo -e $GEEKBENCH_TEST | head -1)
  GEEKBENCH_URL_CLAIM=$(echo $GEEKBENCH_URL | awk '{ print $2 }')
  GEEKBENCH_URL=$(echo $GEEKBENCH_URL | awk '{ print $1 }')
  sleep 15
  GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "div class='score'")
  GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
  GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(<|>)" '{ print $7 }')
  
  if [[ $GEEKBENCH_SCORES_SINGLE -le 400 ]]; then
    grank="(POOR)"
  elif [[ $GEEKBENCH_SCORES_SINGLE -ge 400 && $GEEKBENCH_SCORES_SINGLE -le 660 ]]; then
    grank="(FAIR)"
  elif [[ $GEEKBENCH_SCORES_SINGLE -ge 660 && $GEEKBENCH_SCORES_SINGLE -le 925 ]]; then
    grank="(GOOD)"
  elif [[ $GEEKBENCH_SCORES_SINGLE -ge 925 && $GEEKBENCH_SCORES_SINGLE -le 1350 ]]; then
    grank="(VERY GOOD)"
  elif [[ $GEEKBENCH_SCORES_SINGLE -ge 1350 && $GEEKBENCH_SCORES_SINGLE -le 2000 ]]; then
    grank="(EXCELLENT)"
  elif [[ $GEEKBENCH_SCORES_SINGLE -ge 2000 && $GEEKBENCH_SCORES_SINGLE -le 2600 ]]; then
    grank="(THE BEAST)"
  else
    grank="(MONSTER)"
  fi
  
  echo -ne "\e[1A"; echo -ne "\033[0K\r"
  echostyle "## Geekbench v6 CPU Benchmark:"
  echo "" | tee -a $log
  echo -e "  Single Core : $GEEKBENCH_SCORES_SINGLE  $grank" | tee -a $log
  echo -e "  Multi Core : $GEEKBENCH_SCORES_MULTI" | tee -a $log
  [ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" >> geekbench_claim.url 2> /dev/null
  echo "" | tee -a $log
  echo -e " Cooling down..."
  sleep 10
  echo -ne "\e[1A"; echo -ne "\033[0K\r"
  fi
}

calc_size() {
    local raw=$1
    local total_size=0
    local num=1
    local unit="KB"
    if ! [[ ${raw} =~ ^[0-9]+$ ]]; then
        echo ""
        return
    fi
    if [ "${raw}" -ge 1073741824 ]; then
        num=1073741824
        unit="TB"
    elif [ "${raw}" -ge 1048576 ]; then
        num=1048576
        unit="GB"
    elif [ "${raw}" -ge 1024 ]; then
        num=1024
        unit="MB"
    elif [ "${raw}" -eq 0 ]; then
        echo "${total_size}"
        return
    fi
    total_size=$(awk 'BEGIN{printf "%.1f", '"$raw"' / '$num'}')
    echo "${total_size} ${unit}"
}

# since calc_size converts kilobyte to MB, GB and TB
# to_kibyte converts zfs size from bytes to kilobyte
to_kibyte() {
    local raw=$1
    awk 'BEGIN{printf "%.0f", '"$raw"' / 1024}'
}

calc_sum() {
    local arr=("$@")
    local s
    s=0
    for i in "${arr[@]}"; do
        s=$((s + i))
    done
    echo ${s}
}

check_virt() {
    _exists "dmesg" && virtualx="$(dmesg 2>/dev/null)"
    if _exists "dmidecode"; then
        sys_manu="$(dmidecode -s system-manufacturer 2>/dev/null)"
        sys_product="$(dmidecode -s system-product-name 2>/dev/null)"
        sys_ver="$(dmidecode -s system-version 2>/dev/null)"
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    if grep -qa docker /proc/1/cgroup; then
        virt="Docker"
    elif grep -qa lxc /proc/1/cgroup; then
        virt="LXC"
    elif grep -qa container=lxc /proc/1/environ; then
        virt="LXC"
    elif [[ -f /proc/user_beancounters ]]; then
        virt="OpenVZ"
    elif [[ "${virtualx}" == *kvm-clock* ]]; then
        virt="KVM"
    elif [[ "${sys_product}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${sys_manu}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${virtualx}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${sys_product}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${virtualx}" == *"Parallels Software International"* ]]; then
        virt="Parallels"
    elif [[ "${virtualx}" == *VirtualBox* ]]; then
        virt="VirtualBox"
    elif [[ -e /proc/xen ]]; then
        if grep -q "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            virt="Xen-Dom0"
        else
            virt="Xen-DomU"
        fi
    elif [ -f "/sys/hypervisor/type" ] && grep -q "xen" "/sys/hypervisor/type"; then
        virt="Xen"
    elif [[ "${sys_manu}" == *"Microsoft Corporation"* ]]; then
        if [[ "${sys_product}" == *"Virtual Machine"* ]]; then
            if [[ "${sys_ver}" == *"7.0"* || "${sys_ver}" == *"Hyper-V" ]]; then
                virt="Hyper-V"
            else
                virt="Microsoft Virtual Machine"
            fi
        fi
    else
        virt="Dedicated"
    fi
}

ipv4_info() {
    local org city country region
    org="$(wget -q -T10 -O- ipinfo.io/org)"
    city="$(wget -q -T10 -O- ipinfo.io/city)"
    country="$(wget -q -T10 -O- ipinfo.io/country)"
    region="$(wget -q -T10 -O- ipinfo.io/region)"
    if [[ -n "${org}" ]]; then
        echo " Organization       : $(_blue "${org}")"
    fi
    if [[ -n "${city}" && -n "${country}" ]]; then
        echo " Location           : $(_blue "${city} / ${country}")"
    fi
    if [[ -n "${region}" ]]; then
        echo " Region             : $(_yellow "${region}")"
    fi
    if [[ -z "${org}" ]]; then
        echo " Region             : $(_red "No ISP detected")"
    fi
}

install_speedtest() {
    if [ ! -e "./speedtest-cli/speedtest" ]; then
        sys_bit=""
        local sysarch
        sysarch="$(uname -m)"
        if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
            sysarch="$(arch)"
        fi
        if [ "${sysarch}" = "x86_64" ]; then
            sys_bit="x86_64"
        fi
        if [ "${sysarch}" = "i386" ] || [ "${sysarch}" = "i686" ]; then
            sys_bit="i386"
        fi
        if [ "${sysarch}" = "armv8" ] || [ "${sysarch}" = "armv8l" ] || [ "${sysarch}" = "aarch64" ] || [ "${sysarch}" = "arm64" ]; then
            sys_bit="aarch64"
        fi
        if [ "${sysarch}" = "armv7" ] || [ "${sysarch}" = "armv7l" ]; then
            sys_bit="armhf"
        fi
        if [ "${sysarch}" = "armv6" ]; then
            sys_bit="armel"
        fi
        [ -z "${sys_bit}" ] && _red "Error: Unsupported system architecture (${sysarch}).\n" && exit 1
        url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        if ! wget --no-check-certificate -q -T10 -O speedtest.tgz ${url1}; then
            if ! wget --no-check-certificate -q -T10 -O speedtest.tgz ${url2}; then
                _red "Error: Failed to download speedtest-cli.\n" && exit 1
            fi
        fi
        mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
        rm -f speedtest.tgz
    fi
    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
}

print_intro() {
    echo "-------------------- A Bench.sh Script By Teddysun -------------------"
    echo " Version            : $(_green v2024-11-11)"
    echo " Usage              : $(_red "wget -qO- bench.sh | bash")"
}

# Get System information
get_system_info() {
    cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cores=$(awk -F: '/^processor/ {core++} END {print core}' /proc/cpuinfo)
    freq=$(awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo)
    ccache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cpu_aes=$(grep -i 'aes' /proc/cpuinfo)
    cpu_virt=$(grep -Ei 'vmx|svm' /proc/cpuinfo)
    tram=$(
        LANG=C
        free | awk '/Mem/ {print $2}'
    )
    tram=$(calc_size "$tram")
    uram=$(
        LANG=C
        free | awk '/Mem/ {print $3}'
    )
    uram=$(calc_size "$uram")
    swap=$(
        LANG=C
        free | awk '/Swap/ {print $2}'
    )
    swap=$(calc_size "$swap")
    uswap=$(
        LANG=C
        free | awk '/Swap/ {print $3}'
    )
    uswap=$(calc_size "$uswap")
    up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)
    if _exists "w"; then
        load=$(
            LANG=C
            w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
        )
    elif _exists "uptime"; then
        load=$(
            LANG=C
            uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
        )
    fi
    opsy=$(get_opsy)
    arch=$(uname -m)
    if _exists "getconf"; then
        lbit=$(getconf LONG_BIT)
    else
        echo "${arch}" | grep -q "64" && lbit="64" || lbit="32"
    fi
    kern=$(uname -r)
    in_kernel_no_swap_total_size=$(
        LANG=C
        df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | grep total | awk '{ print $2 }'
    )
    swap_total_size=$(free -k | grep Swap | awk '{print $2}')
    zfs_total_size=$(to_kibyte "$(calc_sum "$(zpool list -o size -Hp 2> /dev/null)")")
    disk_total_size=$(calc_size $((swap_total_size + in_kernel_no_swap_total_size + zfs_total_size)))
    in_kernel_no_swap_used_size=$(
        LANG=C
        df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | grep total | awk '{ print $3 }'
    )
    swap_used_size=$(free -k | grep Swap | awk '{print $3}')
    zfs_used_size=$(to_kibyte "$(calc_sum "$(zpool list -o allocated -Hp 2> /dev/null)")")
    disk_used_size=$(calc_size $((swap_used_size + in_kernel_no_swap_used_size + zfs_used_size)))
    tcpctrl=$(sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}')
}
# Print System information
print_system_info() {
    if [ -n "$cname" ]; then
        echo " CPU Model          : $(_blue "$cname")"
    else
        echo " CPU Model          : $(_blue "CPU model not detected")"
    fi
    if [ -n "$freq" ]; then
        echo " CPU Cores          : $(_blue "$cores @ $freq MHz")"
    else
        echo " CPU Cores          : $(_blue "$cores")"
    fi
    if [ -n "$ccache" ]; then
        echo " CPU Cache          : $(_blue "$ccache")"
    fi
    if [ -n "$cpu_aes" ]; then
        echo " AES-NI             : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " AES-NI             : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    if [ -n "$cpu_virt" ]; then
        echo " VM-x/AMD-V         : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " VM-x/AMD-V         : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    echo " Total Disk         : $(_yellow "$disk_total_size") $(_blue "($disk_used_size Used)")"
    echo " Total Mem          : $(_yellow "$tram") $(_blue "($uram Used)")"
    if [ "$swap" != "0" ]; then
        echo " Total Swap         : $(_blue "$swap ($uswap Used)")"
    fi
    echo " System uptime      : $(_blue "$up")"
    echo " Load average       : $(_blue "$load")"
    echo " OS                 : $(_blue "$opsy")"
    echo " Arch               : $(_blue "$arch ($lbit Bit)")"
    echo " Kernel             : $(_blue "$kern")"
    echo " TCP CC             : $(_yellow "$tcpctrl")"
    echo " Virtualization     : $(_blue "$virt")"
    echo " IPv4/IPv6          : $online"
}

print_io_test() {
    iotest
    write_io

}

print_end_time() {
    end_time=$(date +%s)
    time=$((end_time - start_time))
    if [ ${time} -gt 60 ]; then
        min=$((time / 60))
        sec=$((time % 60))
        echo " Finished in        : ${min} min ${sec} sec"
    else
        echo " Finished in        : ${time} sec"
    fi
    date_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    echo " Timestamp          : $date_time"
}

! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
# check for curl/wget
_exists "curl" && local_curl=true
# test if the host has IPv4/IPv6 connectivity
[[ -n ${local_curl} ]] && ip_check_cmd="curl -s -m 4" || ip_check_cmd="wget -qO- -T 4"
ipv4_check=$( (ping -4 -c 1 -W 4 ipv4.google.com >/dev/null 2>&1 && echo true) || ${ip_check_cmd} -4 icanhazip.com 2> /dev/null)
ipv6_check=$( (ping -6 -c 1 -W 4 ipv6.google.com >/dev/null 2>&1 && echo true) || ${ip_check_cmd} -6 icanhazip.com 2> /dev/null)
if [[ -z "$ipv4_check" && -z "$ipv6_check" ]]; then
    _yellow "Warning: Both IPv4 and IPv6 connectivity were not detected.\n"
fi
[[ -z "$ipv4_check" ]] && online="$(_red "\xe2\x9c\x97 Offline")" || online="$(_green "\xe2\x9c\x93 Online")"
[[ -z "$ipv6_check" ]] && online+=" / $(_red "\xe2\x9c\x97 Offline")" || online+=" / $(_green "\xe2\x9c\x93 Online")"
start_time=$(date +%s)
get_system_info
check_virt
clear
print_intro
next
print_system_info
ipv4_info
next
print_io_test
next
install_speedtest && speed && rm -fr speedtest-cli
next
geekbench6
next
print_end_time
next