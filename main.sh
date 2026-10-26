#!/bin/bash
# main.sh — exitool 一体化脚本
#   Windows/Git Bash:  bash main.sh push     -> 自部署到 WSL BUILD:/root/sh/main.sh
#   Linux/容器内:      bash main.sh          -> TUI 系统面板 + 软件源切换(多国)
#                      bash main.sh mirror [tuna|aliyun|ustc|jaist|yandex|kaist|us|uk|de|fr|nl|sg|au|in|official|N|custom:URL]
#   支持 Alpine / Debian / Ubuntu / Arch,纯 bash + coreutils
#   切换软件源后自动执行 apt-get/apk/pacman 索引更新

set -u
LC_ALL=C.UTF-8 2>/dev/null || true

# ---------- 部署模式 ----------
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_FILE=$(basename "$0")

do_push() {
  cd "$SCRIPT_DIR" || exit 1
  wsl.exe -d BUILD bash "$SCRIPT_FILE" deploy
}

do_deploy() {
  local src tmp
  src="$SCRIPT_DIR/$SCRIPT_FILE"
  tmp=$(mktemp)
  tr -d '\r' < "$src" > "$tmp"
  bash -n "$tmp" || { echo "SYNTAX FAIL: $src" >&2; rm -f "$tmp"; exit 1; }
  mkdir -p /root/sh
  cp "$tmp" /root/sh/main.sh
  chmod 755 /root/sh/main.sh
  rm -f /root/sh/sysinfo-tui.sh "$tmp"
  echo "DEPLOYED: /root/sh/main.sh"
  ls -l /root/sh/main.sh
}

# ---------- 软件源管理 ----------
detect_family() {
  if [ -e /etc/alpine-release ]; then echo alpine
  elif [ -e /etc/arch-release ]; then echo arch
  elif [ -e /etc/os-release ]; then
    local id
    id=$(. /etc/os-release && echo "${ID:-}")
    case "$id" in
      ubuntu) echo ubuntu ;;
      debian) echo debian ;;
      *) case "$(. /etc/os-release && echo "${ID_LIKE:-}")" in
           *debian*) echo debian ;;
           *) echo unknown ;;
         esac ;;
    esac
  else echo unknown; fi
}

FAMILY=$(detect_family)
MIRROR_NAMES=( "中国·清华TUNA" "中国·阿里云" "中国·科大USTC" "日本·JAIST" "俄罗斯·Yandex" "韩国·KAIST" "美国" "英国" "德国" "法国" "荷兰" "新加坡" "澳大利亚" "印度" "全球·官方" "自定义 URL" )
# 索引: 0..15(idx15=自定义, 由 $CUSTOM_BASE 拼路径)

SEC_DEB=http://security.debian.org/debian-security

# 输出 "主源URL|安全源URL"(SEC 为 - 表示由 switch_* 决定);空串=该站无此家族
m_urls() { # $1=family $2=idx
  local s=$SEC_DEB
  case "$1" in
  alpine) case "$2" in
      0) echo "https://mirrors.tuna.tsinghua.edu.cn/alpine|-" ;;
      1) echo "https://mirrors.aliyun.com/alpine|-" ;;
      2) echo "https://mirrors.ustc.edu.cn/alpine|-" ;;
      4) echo "https://mirror.yandex.ru/mirrors/alpine|-" ;;
      8) echo "https://ftp.fau.de/alpine|-" ;;
      14) echo "http://dl-cdn.alpinelinux.org/alpine|-" ;;
      *) echo "" ;; esac ;;
  debian) case "$2" in
      0) echo "https://mirrors.tuna.tsinghua.edu.cn/debian|https://mirrors.tuna.tsinghua.edu.cn/debian-security" ;;
      1) echo "https://mirrors.aliyun.com/debian|https://mirrors.aliyun.com/debian-security" ;;
      2) echo "https://mirrors.ustc.edu.cn/debian|https://mirrors.ustc.edu.cn/debian-security" ;;
      3) echo "http://ftp.jaist.ac.jp/pub/Linux/debian|$s" ;;
      4) echo "http://mirror.yandex.ru/debian|$s" ;;
      5) echo "http://ftp.kaist.ac.kr/debian|$s" ;;
      6) echo "http://ftp.us.debian.org/debian|$s" ;;
      7) echo "http://ftp.uk.debian.org/debian|$s" ;;
      8) echo "http://ftp.de.debian.org/debian|$s" ;;
      9) echo "http://ftp.fr.debian.org/debian|$s" ;;
      10) echo "http://ftp.nl.debian.org/debian|$s" ;;
      11) echo "http://mirror.djvg.sg/debian|$s" ;;
      12) echo "http://ftp.au.debian.org/debian|$s" ;;
      13) echo "http://debian.mirror.net.in/debian|$s" ;;
      14) echo "http://deb.debian.org/debian|$s" ;;
      *) echo "" ;; esac ;;
  ubuntu) case "$2" in
      0) echo "https://mirrors.tuna.tsinghua.edu.cn/ubuntu|-" ;;
      1) echo "https://mirrors.aliyun.com/ubuntu|-" ;;
      2) echo "https://mirrors.ustc.edu.cn/ubuntu|-" ;;
      3) echo "https://mirror.lc/ubuntu|-" ;;
      4) echo "https://mirror.truenetwork.ru/ubuntu|-" ;;
      5) echo "https://ftp.kaist.ac.kr/ubuntu|-" ;;
      6) echo "http://us.archive.ubuntu.com/ubuntu|-" ;;
      7) echo "http://gb.archive.ubuntu.com/ubuntu|-" ;;
      8) echo "https://ftp.uni-stuttgart.de/ubuntu|-" ;;
      9) echo "https://ubuntu.mirrors.ovh.net/ubuntu|-" ;;
      10) echo "http://nl.archive.ubuntu.com/ubuntu|-" ;;
      11) echo "https://mirror.freedif.org/ubuntu|-" ;;
      12) echo "https://mirror.aarnet.edu.au/pub/ubuntu/archive|-" ;;
      13) echo "http://mirrors.piconets.webwerks.in/ubuntu-mirror/ubuntu|-" ;;
      14) if [ "$(uname -m)" = x86_64 ]; then echo "http://archive.ubuntu.com/ubuntu|-"
          else echo "http://ports.ubuntu.com/ubuntu-ports|-"; fi ;;
      *) echo "" ;; esac ;;
  arch) case "$2" in
      0) echo "https://mirrors.tuna.tsinghua.edu.cn/archlinux|-" ;;
      1) echo "https://mirrors.aliyun.com/archlinux|-" ;;
      2) echo "https://mirrors.ustc.edu.cn/archlinux|-" ;;
      3) echo "https://ftp.jaist.ac.jp/pub/Linux/ArchLinux|-" ;;
      4) echo "https://mirror.yandex.ru/archlinux|-" ;;
      5) echo "https://ftp.kaist.ac.kr/archlinux|-" ;;
      6) echo "https://mirrors.kernel.org/archlinux|-" ;;
      7) echo "https://www.mirrorservice.org/sites/ftp.archlinux.org|-" ;;
      8) echo "https://ftp.fau.de/archlinux|-" ;;
      9) echo "https://fr.mirrors.cicku.me/archlinux|-" ;;
      10) echo "https://nl.mirrors.cicku.me/archlinux|-" ;;
      11) echo "https://mirror.freedif.org/archlinux|-" ;;
      12) echo "https://mirror.aarnet.edu.au/pub/archlinux|-" ;;
      13) echo "https://in.mirrors.cicku.me/archlinux|-" ;;
      14) echo "-|-" ;;
      *) echo "" ;; esac ;;
  esac
  return 1
}

bak() { [ -f "$1" ] && cp -n "$1" "$1.bak"; }

os_codename() { . /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}"; }

switch_alpine() { # $1=main
  local main=$1 suffix repo=/etc/apk/repositories
  [ -w /etc ] || { echo "需要 root" >&2; return 1; }
  if grep -q '/edge' "$repo" 2>/dev/null; then suffix=edge
  else suffix=v$(cut -d. -f1,2 /etc/alpine-release); fi
  bak "$repo"
  printf '%s/%s/main\n%s/%s/community\n' "$main" "$suffix" "$main" "$suffix" > "$repo"
}

switch_debian() { # $1=main $2=sec
  local main=$1 sec=$2 codename f822=/etc/apt/sources.list.d/debian.sources
  codename=$(os_codename); codename=${codename:-stable}
  if [ -f "$f822" ]; then
    bak "$f822"
    cat > "$f822" <<EOF
Types: deb
URIs: $main
Suites: $codename ${codename}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: $sec
Suites: ${codename}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  else
    bak /etc/apt/sources.list
    cat > /etc/apt/sources.list <<EOF
deb $main $codename main contrib non-free non-free-firmware
deb $main $codename-updates main contrib non-free non-free-firmware
deb $sec $codename-security main contrib non-free non-free-firmware
EOF
  fi
}

switch_ubuntu() { # $1=main
  local main=$1 sec codename f822=/etc/apt/sources.list.d/ubuntu.sources
  codename=$(os_codename)
  [ -n "$codename" ] || { echo "无法识别 Ubuntu 代号" >&2; return 1; }
  if [ "$(uname -m)" = x86_64 ]; then sec=http://security.ubuntu.com/ubuntu
  else sec=$main; fi
  if [ -f "$f822" ]; then
    bak "$f822"
    cat > "$f822" <<EOF
Types: deb
URIs: $main
Suites: $codename ${codename}-updates ${codename}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: $sec
Suites: ${codename}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
  else
    bak /etc/apt/sources.list
    cat > /etc/apt/sources.list <<EOF
deb $main $codename main restricted universe multiverse
deb $main $codename-updates main restricted universe multiverse
deb $main $codename-backports main restricted universe multiverse
deb $sec $codename-security main restricted universe multiverse
EOF
  fi
}

switch_arch() { # $1=main("-"表示仅官方)
  local f=/etc/pacman.d/mirrorlist main=$1
  [ -w /etc/pacman.d ] || { echo "需要 root" >&2; return 1; }
  bak "$f"
  {
    [ "$main" != "-" ] && echo "Server = $main/\$repo/os/\$arch"
    echo "Server = https://geo.mirrorlist.cc/\$repo/os/\$arch"
  } > "$f"
}

# 组合: idx=15 用 $CUSTOM_BASE 按 tuna 惯例拼路径
apply_mirror() { # $1=idx 0..15
  local idx=$1 t main sec
  local fn
  case "$FAMILY" in
    alpine) fn=switch_alpine ;; debian) fn=switch_debian ;;
    ubuntu) fn=switch_ubuntu ;; arch) fn=switch_arch ;;
    *) echo "不支持的发行版: $FAMILY" >&2; return 1 ;;
  esac
  if [ "$idx" = 15 ]; then
    [ -n "${CUSTOM_BASE:-}" ] || { echo "未提供自定义 URL" >&2; return 1; }
    case "$FAMILY" in
      alpine) t="$CUSTOM_BASE/alpine|-" ;;
      debian) t="$CUSTOM_BASE/debian|$CUSTOM_BASE/debian-security" ;;
      ubuntu) t="$CUSTOM_BASE/ubuntu|-" ;;
      arch) t="$CUSTOM_BASE/archlinux|-" ;;
    esac
  else
    t=$(m_urls "$FAMILY" "$idx")
  fi
  [ -n "$t" ] || { echo "该站点未收录 $FAMILY 源,请换站点/官方/自定义" >&2; return 1; }
  IFS='|' read -r main sec <<< "$t"
  case "$FAMILY" in
    debian) "$fn" "$main" "$sec" ;;
    *) "$fn" "$main" ;;
  esac
}

current_source() {
  local h=""
  case "$FAMILY" in
    alpine) h=$(grep -m1 -oE 'https?://[^/]+' /etc/apk/repositories 2>/dev/null) ;;
    debian|ubuntu) h=$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list 2>/dev/null | grep -m1 -oE 'https?://[^/ ]+') ;;
    arch) h=$(grep -m1 -oE 'https?://[^/$]+' /etc/pacman.d/mirrorlist 2>/dev/null) ;;
  esac
  case "$h" in
    *tuna*) echo "中国·清华TUNA" ;;
    *aliyun*) echo "中国·阿里云" ;;
    *ustc*) echo "中国·科大USTC" ;;
    "") echo "未知" ;;
    *) echo "其他 ($h)" ;;
  esac
}

update_cmd() {
  case "$FAMILY" in
    alpine) echo apk update ;;
    debian|ubuntu) echo apt-get update ;;
    arch) echo pacman -Sy ;;
    *) echo "" ;;
  esac
}

# 执行家族更新命令,输出尾部存入 $UOUT,退出码存入 $URC
do_update_capture() {
  local cmd out rc
  cmd=$(update_cmd)
  if [ -z "$cmd" ]; then UOUT="未知家族,无更新命令"; URC=1; return 1; fi
  out=$(bash -c "$cmd" 2>&1); rc=$?
  UOUT=$(printf '%s\n' "$out" | tail -n 8)
  URC=$rc
  return $rc
}

# CLI 名称 -> idx
mirror_idx_by_name() {
  case "$1" in
    tuna) echo 0 ;; aliyun) echo 1 ;; ustc) echo 2 ;; jaist) echo 3 ;;
    yandex) echo 4 ;; kaist) echo 5 ;; us) echo 6 ;; uk) echo 7 ;;
    de) echo 8 ;; fr) echo 9 ;; nl) echo 10 ;; sg) echo 11 ;;
    au) echo 12 ;; in) echo 13 ;; official) echo 14 ;;
    *) return 1 ;;
  esac
}

case "${1:-}" in
  push)   do_push;   exit 0 ;;
  deploy) do_deploy; exit 0 ;;
  mirror)
    target=${2:-}
    if [ -z "$target" ]; then
      echo "family=$FAMILY current=$(current_source)"
      exit 0
    fi
    idx=""
    case "$target" in
      custom:*) CUSTOM_BASE=${target#custom:}; CUSTOM_BASE=${CUSTOM_BASE%/}; idx=15 ;;
      [1-9]|1[0-6]) idx=$((target - 1)) ;;
      *) idx=$(mirror_idx_by_name "$target") || { echo "无效站点名" >&2; exit 2; } ;;
    esac
    if apply_mirror "$idx"; then
      echo "OK: $FAMILY -> ${MIRROR_NAMES[idx]}${CUSTOM_BASE:+ ($CUSTOM_BASE)}"
      if do_update_capture; then
        echo "索引已自动更新"
      else
        echo "自动更新失败 rc=$URC:"
        printf '%s\n' "$UOUT" | tail -n 3
        exit 1
      fi
    else
      exit 1
    fi
    exit 0 ;;
esac

# ---------- TUI ----------
ROWS=( "系统信息" "磁盘使用" "软件源切换" "图形化安装" "用户管理" "刷新界面" "退出" )
SEL=1
MSG=""

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }
on_exit() { show_cursor; printf '\e[0m\n'; }
trap on_exit EXIT
trap 'exit 130' INT TERM

# 丢弃转义序列残余字节。必须带 -t: bash 的 read -n 会覆盖自设 termios,
# 且无超时的 read -n 256 会阻塞到凑满 256 字符或换行,吞掉后续按键导致界面冻结
flush_keys() { IFS= read -r -n 256 -s -t 0.05 || true; }

read_key() {
  local k rest=""
  IFS= read -rn1 k || { MSG="输入结束"; return 1; }
  if [ "$k" = $'\003' ]; then KEY=ctrlc; return 0; fi
  if [ "$k" = $'\e' ]; then
    IFS= read -rn2 -t 0.2 rest || true
    case "$rest" in
      '[A') KEY=up;    flush_keys; return 0 ;;
      '[B') KEY=down;  flush_keys; return 0 ;;
      '[C') KEY=right; flush_keys; return 0 ;;
      '[D') KEY=left;  flush_keys; return 0 ;;
      *) KEY=esc; [ -n "$rest" ] && { flush_keys; MSG="收到转义序列"; }; return 0 ;;
    esac
  fi
  KEY="$k"
}

move_sel() {
  local d=$1 n=$2 cur=$3
  echo $(( (cur - 1 + d + n) % n + 1 ))
}

kv() { printf '  %-14s %s\n' "$1" "$2"; }

view_os() {
  local pretty
  pretty=$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-unknown}")
  kv "发行版" "$pretty"
  kv "内核" "$(uname -r)"
  kv "主机名" "$(uname -n)"
  kv "架构" "$(uname -m)"
}

view_uptime() {
  local up
  up=$(cut -d. -f1 /proc/uptime)
  kv "运行时长" "$(( up/3600 ))h$(( up%3600/60 ))m"
  kv "负载" "$(cut -d' ' -f1-3 /proc/loadavg)"
}

view_mem() {
  local total avail
  total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
  avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
  kv "内存总量" "$(( total/1024 )) MB"
  kv "可用内存" "$(( avail/1024 )) MB"
  kv "已用" "$(( (total-avail)/1024 )) MB ($(( (total-avail)*100/total ))%)"
}

view_cpu() {
  local model cores
  model=$(awk -F': *' '/^model name/{print $2; exit}' /proc/cpuinfo)
  cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
  kv "CPU" "${model:-unknown}"
  kv "核心数" "$cores"
}

view_gpu() {
  local d cls ven dev brand label seen="" hit=0 key
  for d in /sys/bus/pci/devices/*; do
    cls=$(cat "$d/class" 2>/dev/null) || continue
    case "$cls" in 0x0300*|0x0301*|0x0302*) ;; *) continue ;; esac
    ven=$(cat "$d/vendor" 2>/dev/null)
    dev=$(cat "$d/device" 2>/dev/null)
    key="$ven:$dev:$cls"
    case " $seen " in *" $key "*) continue ;; esac
    seen="$seen $key"
    case "$ven" in
      0x1414) brand="Microsoft" ;; 0x8086) brand="Intel" ;; 0x10de) brand="NVIDIA" ;;
      0x1002) brand="AMD" ;; 0x15ad) brand="VMware" ;; 0x80ee) brand="VirtualBox" ;;
      0x1af4|0x1ab8) brand="virtio" ;; *) brand="GPU $ven" ;;
    esac
    label=$(cat "$d/label" 2>/dev/null)
    case "$cls" in 0x0300*) cls="VGA" ;; 0x0301*) cls="XGA" ;; *) cls="3D" ;; esac
    kv "GPU" "$brand ${dev#0x} [$cls]${label:+ $label}"
    hit=1
  done
  if [ -e /dev/dxg ]; then
    kv "GPU 加速" "/dev/dxg (WSL DXCore,经 Windows 显卡)"
  elif [ -d /dev/dri ]; then
    kv "DRM 节点" "$(ls /dev/dri 2>/dev/null | tr '\n' ' ')"
  fi
  [ -f /proc/driver/nvidia/version ] && kv "NVIDIA 驱动" "$(head -1 /proc/driver/nvidia/version)"
  [ "$hit" = 0 ] && [ ! -e /dev/dxg ] && kv "GPU" "未检测到 PCI 显示设备"
}

view_disk() {
  echo "  文件系统        容量  已用  可用 使用率"
  df -h / /root 2>/dev/null | awk 'NR>1 && !seen[$1]++ {printf "  %-16s %5s %5s %5s %6s\n", $1, $2, $3, $4, $5}'
  echo
  echo "  /root 占用: $(du -sh /root 2>/dev/null | cut -f1)"
}

pause_msg() {
  MSG="按任意键返回菜单"
  render
  read_key || true
  MSG=""
}

render() {
  printf '\e[H\e[2J'
  printf '\e[1;36m── Linux 系统信息面板 (TUI) ──\e[0m\n\n'
  local i=1
  for row in "${ROWS[@]}"; do
    if [ $i -eq $SEL ]; then
      printf '  \e[7m▶ %s\e[0m\n' "$row"
    else
      printf '    %s\n' "$row"
    fi
    i=$(( i + 1 ))
  done
  echo
  case $SEL in
    1) view_os; view_uptime; view_mem; echo; view_cpu; view_gpu ;;
    2) view_disk ;;
    3) kv "发行版家族" "$FAMILY"; kv "当前源" "$(current_source)" ;;
    4) kv "发行版家族" "$FAMILY"; kv "主线" "$(gfx_count 0) 项"; kv "派系" "$(gfx_count 1) 项"; kv "登录管理器" "$(gfx_count 2) 项" ;;
    5) kv "普通用户" "$(user_count) 个"; kv "提权组" "$(sudo_group_name)" ;;
    6) view_os ;;
  esac
  [ -n "$MSG" ] && printf '\n\e[33m%s\e[0m\n' "$MSG"
  printf '\n\e[2m↑/↓ 选择 · Enter 查看 · q 退出\e[0m\n'
}

MIR_SEL=1
SW_MSG=""
UOUT=""
URC=0

dispw() { # 显示宽度: 码位>127 按 2 列计
  local s=$1
  local n=${#s} w=0 i code
  for ((i = 0; i < n; i++)); do
    printf -v code '%d' "'${s:i:1}"
    if (( code > 127 )); then w=$(( w + 2 )); else w=$(( w + 1 )); fi
  done
  echo "$w"
}

fmt_item() { # $1=idx -> 固定 20 显示列宽单元(ANSI 色不计入宽度)
  local name=${MIRROR_NAMES[$1]} body
  body=$(pad_to 21 " $name ")
  if [ $(( $1 + 1 )) -eq $MIR_SEL ]; then
    printf '\e[7m▶%s\e[0m' "${body:1}"
  else
    printf '%s' "$body"
  fi
}

pad_to() { # $1=宽度 $2=字符串
  local p=$(( $1 - $(dispw "$2") ))
  [ "$p" -gt 0 ] || p=0
  printf '%s%*s' "$2" "$p" ''
}

render_mirror() {
  printf '\e[H\e[2J'
  printf '\e[1;35m── 软件源切换(多国) ───────────────\e[0m\n\n'
  kv "发行版家族" "$FAMILY"
  kv "当前源" "$(current_source)"
  echo
  local n=${#MIRROR_NAMES[@]}
  local rows=$(( (n + 1) / 2 ))
  local r c1 c2 s1 s2 COL=20
  for ((r = 0; r < rows; r++)); do
    c1=$(( 2 * r )); c2=$(( 2 * r + 1 ))
    s1=$(fmt_item "$c1"); s2=""; [ "$c2" -lt "$n" ] && s2=$(fmt_item "$c2")
    printf '%s%s\n' "$s1" "$s2"
  done
  [ -n "$UOUT" ] && { echo; printf '%s\n' "$UOUT"; }
  [ -n "$SW_MSG" ] && printf '\n\e[33m%s\e[0m\n' "$SW_MSG"
  printf '\n\e[2m↑/↓ 同列移动 · ←/→ 换列 · Enter 应用并自动更新 · u 手动更新 · q 返回\e[0m\n'
}

mirror_screen() {
  local mi out
  MIR_SEL=1; SW_MSG=""
  while :; do
    render_mirror
    read_key || break
    case "$KEY" in
      ctrlc) exit 130 ;;
      up)    MIR_SEL=$(move_sel -2 ${#MIRROR_NAMES[@]} "$MIR_SEL") ;;
      down)  MIR_SEL=$(move_sel  2 ${#MIRROR_NAMES[@]} "$MIR_SEL") ;;
      k)     MIR_SEL=$(move_sel -2 ${#MIRROR_NAMES[@]} "$MIR_SEL") ;;
      j)     MIR_SEL=$(move_sel  2 ${#MIRROR_NAMES[@]} "$MIR_SEL") ;;
      left|'h')  MIR_SEL=$(move_sel -1 ${#MIRROR_NAMES[@]} "$MIR_SEL") ;;
      right|'l') MIR_SEL=$(move_sel  1 ${#MIRROR_NAMES[@]} "$MIR_SEL") ;;
      esc|q|Q) break ;;
      '')
        mi=$((MIR_SEL - 1))
        if [ "$mi" = 15 ]; then
          CUSTOM_BASE=""
          printf '\n\e[0m输入镜像站基础 URL (如 https://mirror.example.com,回车确认): '
          IFS= read -r CUSTOM_BASE || { SW_MSG="已取消"; continue; }
          CUSTOM_BASE=${CUSTOM_BASE%/}
          [ -n "$CUSTOM_BASE" ] || { SW_MSG="URL 为空"; continue; }
        fi
        if out=$(apply_mirror "$mi" 2>&1); then
          SW_MSG="已切换: ${MIRROR_NAMES[mi]}${CUSTOM_BASE:+ ($CUSTOM_BASE)},正在自动更新索引..."
          render_mirror
          if do_update_capture; then
            SW_MSG="已切换: ${MIRROR_NAMES[mi]},索引已自动更新"
          else
            SW_MSG="已切换: ${MIRROR_NAMES[mi]},但索引更新失败(退出码 $URC)"
          fi
        else
          SW_MSG="$out"
        fi
        CUSTOM_BASE="" ;;
      u|U)
        SW_MSG="执行中: $(update_cmd)"
        render_mirror
        do_update_capture || true
        SW_MSG="$(update_cmd) 完成,退出码 $URC" ;;
      *) SW_MSG="未知按键,方向键或 hjkl" ;;
    esac
  done
  UOUT=""
}

# ---------- 图形化安装 ----------
GFX_TABS=( "图形化·主线" "图形化·派系" "登录管理器" )
GFX_TAB=1
GFX_SEL=1
G_MSG=""
G_OUT=""
G_RC=0

# 分类0=主线DE 1=派系flavor 2=登录管理器;输出 "标签|包名列表",无条目输出空
gfx_pkgs() {
  local t=$1 i=$2
  case "$FAMILY" in
  ubuntu)
    case "$t/$i" in
      0/0) echo "GNOME 核心|gnome-core" ;;
      0/1) echo "KDE Plasma|plasma-desktop" ;;
      0/2) echo "XFCE|xfce4" ;;
      0/3) echo "LXQt|lxqt" ;;
      0/4) echo "MATE|mate-desktop-environment" ;;
      0/5) echo "Cinnamon|cinnamon" ;;
      1/0) echo "Ubuntu 官方|ubuntu-desktop" ;;
      1/1) echo "Kubuntu|kubuntu-desktop" ;;
      1/2) echo "Xubuntu|xubuntu-desktop" ;;
      1/3) echo "Lubuntu|lubuntu-desktop" ;;
      2/0) echo "GDM3|gdm3" ;;
      2/1) echo "SDDM|sddm" ;;
      2/2) echo "LightDM|lightdm" ;;
    esac ;;
  debian)
    case "$t/$i" in
      0/0) echo "GNOME 核心|gnome-core" ;;
      0/1) echo "KDE Plasma|kde-plasma-desktop" ;;
      0/2) echo "XFCE|xfce4" ;;
      0/3) echo "LXQt|lxqt" ;;
      0/4) echo "MATE|mate-desktop-environment" ;;
      0/5) echo "Cinnamon|cinnamon" ;;
      1/0) echo "GNOME 任务包|task-gnome-desktop" ;;
      1/1) echo "KDE 任务包|task-kde-desktop" ;;
      1/2) echo "XFCE 任务包|task-xfce-desktop" ;;
      1/3) echo "LXQt 任务包|task-lxqt-desktop" ;;
      2/0) echo "GDM3|gdm3" ;;
      2/1) echo "SDDM|sddm" ;;
      2/2) echo "LightDM|lightdm" ;;
    esac ;;
  alpine)
    case "$t/$i" in
      0/0) echo "GNOME|gnome" ;;
      0/1) echo "KDE Plasma|plasma" ;;
      0/2) echo "XFCE|xfce" ;;
      0/3) echo "LXQt|lxqt" ;;
      2/0) echo "SDDM|sddm" ;;
      2/1) echo "SLiM|slim" ;;
      2/2) echo "greetd|greetd" ;;
    esac ;;
  arch)
    case "$t/$i" in
      0/0) echo "GNOME|gnome" ;;
      0/1) echo "KDE Plasma|plasma" ;;
      0/2) echo "XFCE|xfce4" ;;
      0/3) echo "LXQt|lxqt" ;;
      2/0) echo "GDM|gdm" ;;
      2/1) echo "SDDM|sddm" ;;
      2/2) echo "LightDM|lightdm lightdm-gtk-greeter" ;;
    esac ;;
  esac
}

gfx_count() { # $1=tab(0/1)
  local i=0
  while [ -n "$(gfx_pkgs "$1" "$i")" ]; do i=$(( i + 1 )); done
  echo "$i"
}

gfx_install_cmd() { # $1=包名列表
  case "$FAMILY" in
    ubuntu|debian) echo "DEBIAN_FRONTEND=noninteractive apt-get install -y $1" ;;
    alpine) echo "apk add $1" ;;
    arch) echo "pacman -S --noconfirm --needed $1" ;;
    *) echo "" ;;
  esac
}

gfx_boot_unit() { # $1=主包名 -> systemd/OpenRC 单元名
  case "$1" in
    gdm3|gdm) echo gdm ;;
    sddm) echo sddm ;;
    lightdm) echo lightdm ;;
    slim) echo slim ;;
    greetd) echo greetd ;;
    *) echo "$1" ;;
  esac
}

gfx_boot_cmd() { # $1=单元名 -> 配置开机自启命令
  case "$FAMILY" in
    alpine) echo "rc-update add $1 default" ;;
    ubuntu|debian|arch) echo "systemctl enable $1 && systemctl set-default graphical.target" ;;
    *) echo "" ;;
  esac
}

render_gfx() {
  printf '\e[H\e[2J'
  printf '\e[1;32m── 图形化安装 ──────────────────────\e[0m\n\n'
  kv "发行版家族" "$FAMILY"
  echo
  local i=1 label
  printf '  分类: '
  for label in "${GFX_TABS[@]}"; do
    if [ "$i" -eq "$GFX_TAB" ]; then printf '\e[7m %s \e[0m ' "$label"
    else printf '  %s    ' "$label"; fi
    i=$(( i + 1 ))
  done
  echo
  echo
  local n j t p
  n=$(gfx_count $(( GFX_TAB - 1 )))
  for ((j = 0; j < n; j++)); do
    t=$(gfx_pkgs $(( GFX_TAB - 1 )) "$j"); p=${t#*|}
    if [ $(( j + 1 )) -eq "$GFX_SEL" ]; then
      printf '  \e[7m▶ %-12s %s\e[0m\n' "${t%%|*}" "$p"
    else
      printf '    %-12s %s\n' "${t%%|*}" "$p"
    fi
  done
  [ -n "$G_OUT" ] && { echo; printf '%s\n' "$G_OUT"; }
  [ -n "$G_MSG" ] && printf '\n\e[33m%s\e[0m\n' "$G_MSG"
  printf '\n\e[2m←/→ 切换分类 · ↑/↓ 选择 · Enter 安装 · q 返回\e[0m\n'
}

gfx_screen() {
  local n t label pkgs k out cmd unit bout brc
  GFX_SEL=1; G_MSG=""; G_OUT=""
  while :; do
    n=$(gfx_count $(( GFX_TAB - 1 )))
    [ "$GFX_SEL" -le "$n" ] || GFX_SEL=1
    render_gfx
    read_key || break
    case "$KEY" in
      ctrlc) exit 130 ;;
      left|'h')  GFX_TAB=$(( GFX_TAB == 1 ? 3 : GFX_TAB - 1 )); GFX_SEL=1; G_OUT="" ;;
      right|'l') GFX_TAB=$(( GFX_TAB == 3 ? 1 : GFX_TAB + 1 )); GFX_SEL=1; G_OUT="" ;;
      up|'k')    [ "$n" -gt 0 ] && GFX_SEL=$(move_sel -1 "$n" "$GFX_SEL") ;;
      down|'j')  [ "$n" -gt 0 ] && GFX_SEL=$(move_sel 1 "$n" "$GFX_SEL") ;;
      esc|q|Q) break ;;
      '')
        if [ "$n" -eq 0 ]; then G_MSG="家族 $FAMILY 无可用条目"; continue; fi
        t=$(gfx_pkgs $(( GFX_TAB - 1 )) $(( GFX_SEL - 1 )))
        label=${t%%|*}; pkgs=${t#*|}
        G_MSG="安装 $label ($pkgs)? [y/N]"; G_OUT=""
        render_gfx
        show_cursor
        k=""
        IFS= read -rn1 k || k=""
        hide_cursor
        case "$k" in
          y|Y)
            cmd=$(gfx_install_cmd "$pkgs")
            [ -n "$cmd" ] || { G_MSG="家族 $FAMILY 不支持安装"; continue; }
            G_MSG="正在安装 $label ..."
            render_gfx
            out=$(bash -c "$cmd" 2>&1); G_RC=$?
            if [ "$G_RC" -eq 0 ]; then
              G_MSG="安装 $label 完成"
              if [ "$GFX_TAB" = 3 ]; then
                unit=$(gfx_boot_unit "${pkgs%% *}")
                cmd=$(gfx_boot_cmd "$unit")
                if [ -n "$cmd" ]; then
                  G_OUT=$(printf '%s\n' "$out" | tail -n 4)
                  G_MSG="安装完成,正在配置开机自启: $cmd"
                  render_gfx
                  bout=$(bash -c "$cmd" 2>&1); brc=$?
                  G_OUT=$(printf '%s\n' "$bout" | tail -n 6)
                  if [ "$brc" -eq 0 ]; then
                    G_MSG="安装 $label 完成,已设置 $unit 开机自启(graphical.target)"
                  else
                    G_MSG="安装成功,但开机项配置失败 rc=$brc"
                  fi
                fi
              else
                G_OUT=$(printf '%s\n' "$out" | tail -n 8)
              fi
            else
              G_OUT=$(printf '%s\n' "$out" | tail -n 8)
              G_MSG="安装失败 rc=$G_RC"
            fi ;;
          *) G_MSG="已取消" ;;
        esac ;;
      *) G_MSG="未知按键" ;;
    esac
  done
}

# ---------- 用户管理 ----------
U_SEL=1
U_MSG=""

sudo_group_name() {
  case "$FAMILY" in
    ubuntu|debian) echo sudo ;;
    *) echo wheel ;;
  esac
}

user_names() { awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd; }

user_count() { user_names | grep -c .; }

user_in_group() { # $1=组 $2=用户
  getent group "$1" 2>/dev/null | cut -d: -f4 | tr ',' '\n' | grep -qx "$2"
}

render_users() {
  local users u sg i hst sst
  printf '\e[H\e[2J'
  printf '\e[1;34m── 用户管理 ──────────────────────\e[0m\n\n'
  kv "发行版家族" "$FAMILY"
  sg=$(sudo_group_name)
  i=1
  users=$(user_names)
  printf '  %-20s %s\n' "用户" "sudo / 家目录"
  if [ -z "$users" ]; then echo "  (无普通用户)"; fi
  for u in $users; do
    if user_in_group "$sg" "$u"; then sst="sudo"; else sst="----"; fi
    if [ -d "$(getent passwd "$u" | cut -d: -f6)" ]; then hst="家目录✓"; else hst="家目录✗"; fi
    if [ "$i" -eq "$U_SEL" ]; then
      printf '  \e[7m▶ %-16s %s / %s\e[0m\n' "$u" "$sst" "$hst"
    else
      printf '    %-16s %s / %s\n' "$u" "$sst" "$hst"
    fi
    i=$(( i + 1 ))
  done
  [ -n "$U_MSG" ] && printf '\n\e[33m%s\e[0m\n' "$U_MSG"
  printf '\n\e[2m↑/↓ 选择 · n 添加 · x 删除 · s 切换sudo · q 返回\e[0m\n'
}

user_screen() {
  local n u name ans pw shell sg out rc
  U_SEL=1; U_MSG=""
  while :; do
    n=$(user_count)
    [ "$U_SEL" -le "$n" ] || U_SEL=1
    render_users
    read_key || break
    case "$KEY" in
      ctrlc) exit 130 ;;
      up)    [ "$n" -gt 0 ] && U_SEL=$(( U_SEL - 1 )); [ "$U_SEL" -ge 1 ] || U_SEL=1 ;;
      down)  [ "$n" -gt 0 ] && U_SEL=$(( U_SEL + 1 )); [ "$U_SEL" -le "$n" ] || U_SEL=$n ;;
      esc|q|Q) break ;;
      n|N)
        show_cursor
        printf '\n\e[0m新用户名: '; IFS= read -r name || { hide_cursor; continue; }
        if ! printf '%s' "$name" | grep -Eq '^[a-z_][a-z0-9_-]{0,30}$'; then
          hide_cursor; U_MSG="非法用户名(小写字母/数字/_-)"; continue
        fi
        if getent passwd "$name" >/dev/null 2>&1; then
          hide_cursor; U_MSG="用户 $name 已存在"; continue
        fi
        printf '\n加入 %s 组获得 sudo? [y/N]: ' "$(sudo_group_name)"; IFS= read -r ans || ans=""
        printf '\n设置密码(留空跳过): '; IFS= read -rs pw || pw=""
        hide_cursor
        shell=/bin/bash; [ -x "$shell" ] || shell=/bin/sh
        out=$(useradd -m -s "$shell" "$name" 2>&1); rc=$?
        if [ "$rc" -ne 0 ]; then U_MSG="useradd 失败: $out"; continue; fi
        sg=$(sudo_group_name)
        case "$ans" in [yY]*) gpasswd -a "$name" "$sg" >/dev/null 2>&1 ;; esac
        if [ -n "$pw" ]; then
          printf '%s:%s\n' "$name" "$pw" | chpasswd 2>/dev/null
          U_MSG="已创建 $name(自动建家目录,已设密码)"
        else
          U_MSG="已创建 $name(自动建家目录,未设密码)"
        fi
        case "$ans" in [yY]*) U_MSG="$U_MSG,已加入 $sg" ;; esac ;;
      x|X)
        u=$(user_names | sed -n "${U_SEL}p")
        [ -n "$u" ] || { U_MSG="没有选中的用户"; continue; }
        U_MSG="删除用户 $u 及其家目录? [y/N]"
        render_users
        show_cursor; ans=""; IFS= read -rn1 ans || ans=""; hide_cursor
        case "$ans" in
          [yY])
            out=$(userdel -r "$u" 2>&1); rc=$?
            if [ "$rc" -eq 0 ]; then U_MSG="已删除 $u(含家目录)"; else U_MSG="删除失败: $out"; fi
            U_SEL=1 ;;
          *) U_MSG="已取消" ;;
        esac ;;
      s|S)
        u=$(user_names | sed -n "${U_SEL}p")
        [ -n "$u" ] || { U_MSG="没有选中的用户"; continue; }
        sg=$(sudo_group_name)
        if user_in_group "$sg" "$u"; then
          out=$(gpasswd -d "$u" "$sg" 2>&1); U_MSG="${out:-已移除 $u 的 $sg}"
        else
          out=$(gpasswd -a "$u" "$sg" 2>&1); U_MSG="${out:-已为 $u 启用 sudo}"
        fi ;;
      *) U_MSG="未知按键: n 添加 · x 删除 · s 切换sudo" ;;
    esac
  done
}

main() {
  hide_cursor
  while :; do
    render
    if ! read_key; then break; fi
    case "$KEY" in
      ctrlc) exit 130 ;;
      up) SEL=$(move_sel -1 ${#ROWS[@]} "$SEL") ;;
      down) SEL=$(move_sel 1 ${#ROWS[@]} "$SEL") ;;
      j) SEL=$(move_sel 1 ${#ROWS[@]} "$SEL") ;;
      k) SEL=$(move_sel -1 ${#ROWS[@]} "$SEL") ;;
      left|right) : ;;
      r|R) MSG="已刷新" ;;
      esc) MSG="" ;;
      '')
        case $SEL in
          7) exit 0 ;;
          6) MSG="已刷新" ;;
          5) MSG=""; user_screen ;;
          4) MSG=""; gfx_screen ;;
          3) MSG=""; mirror_screen ;;
          *) pause_msg ;;
        esac ;;
      q|Q) exit 0 ;;
      *) MSG="未知按键，用 ↑/↓ 或 j/k" ;;
    esac
  done
}

main
