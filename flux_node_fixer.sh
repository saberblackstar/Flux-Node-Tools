#!/bin/bash

if ! jq --version >/dev/null 2>&1; then
  echo -e "${RED}jq not found ... installing jq${NC}"
  sudo apt install jq -y

  if ! jq --version >/dev/null 2>&1; then
    echo "jq install was not successful - exiting"
    exit
  fi
fi

#colors
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
NC='\033[0m'

_HLINE="\xE2\x94\x80"
_VLINE="\xE2\x94\x82"

DASH_BENCH_TITLE='FLUX BENCHMARK INFO'
DASH_BENCH_DETAILS_TITLE='FLUX BENCHMARK DETAILS'
DASH_BENCH_ERROR_TITLE='FLUX BENCH ERROR LOG'

DASH_NODE_TITLE='FLUX NODE INFO'
DASH_DAEMON_TITLE='FLUX DAEMON INFO'
DASH_DAEMON_ERROR_TITLE='FLUX DAEMON ERROR LOG'

WINDOW_WIDTH=$(tput cols)
WINDOW_HALF_WIDTH=$(bc <<<"$WINDOW_WIDTH / 2")

WRENCH='\xF0\x9F\x94\xA7'
#BLUE_CIRCLE='\xF0\x9F\x94\xB5'
BLUE_CIRCLE="${SEA}\xE2\x96\xB6${NC}"

COIN_CLI='flux-cli'
BENCH_CLI='fluxbench-cli'
CONFIG_FILE='flux.conf'
BENCH_DIR_LOG='.fluxbenchmark'

BENCH_LOG_DIR='benchmark_debug_error.log'
DAEMON_LOG_DIR='flux_daemon_debug_error.log'
WATCHDOG_LOG_DIR='~/watchdog/watchdog_error.log'

#variables to draw windows
show_bench='1'
show_daemon='0'
show_node='0'

# variable to see if the terminal size has changed
redraw_term='1'

#gets fluxbench version info
flux_bench_version=$(($BENCH_CLI getinfo) | jq -r '.version')

flux_bench_details=$($BENCH_CLI getstatus)
flux_bench_back=$(jq -r '.flux' <<<"$flux_bench_details")
flux_bench_flux_status=$(jq -r '.status' <<<"$flux_bench_details")
flux_bench_benchmark=$(jq -r '.benchmarking' <<<"$flux_bench_details")

#gets blockchain info
flux_daemon_details=$($COIN_CLI getinfo)
flux_daemon_version=$(jq -r '.version' <<<"$flux_daemon_details")
flux_daemon_protocol_version=$(jq -r '.protocolversion' <<<"$flux_daemon_details")
flux_daemon_block_height=$(jq -r '.blocks' <<<"$flux_daemon_details")
flux_daemon_connections=$(jq -r '.connections' <<<"$flux_daemon_details")
flux_daemon_difficulty=$(jq -r '.difficulty' <<<"$flux_daemon_details")
flux_daemon_error=$(jq -r '.error' <<<"$flux_daemon_details")

#gets flux node status
flux_node_details=$($COIN_CLI getzelnodestatus)
flux_node_status=$(jq -r '.status' <<<"$flux_node_details")
flux_node_collateral=$(jq -r '.collateral' <<<"$flux_node_details")
flux_node_added_height=$(jq -r '.added_height' <<<"$flux_node_details")
flux_node_confirmed_height=$(jq -r '.confirmed_height' <<<"$flux_node_details")
flux_node_last_confirmed_height=$(jq -r '.last_confirmed_height' <<<"$flux_node_details")
flux_node_last_paid_height=$(jq -r '.last_paid_height' <<<"$flux_node_details")

flux_bench_stats=$($BENCH_CLI getbenchmarks)
flux_bench_stats_real_cores=$(jq -r '.real_cores' <<<"$flux_bench_stats")
flux_bench_stats_cores=$(jq -r '.cores' <<<"$flux_bench_stats")
flux_bench_stats_ram=$(jq -r '.ram' <<<"$flux_bench_stats")
flux_bench_stats_ssd=$(jq -r '.ssd' <<<"$flux_bench_stats")
flux_bench_stats_hhd=$(jq -r '.hdd' <<<"$flux_bench_stats")
flux_bench_stats_ddwrite=$(jq -r '.ddwrite' <<<"$flux_bench_stats")
flux_bench_stats_storage=$(jq -r '.totalstorage' <<<"$flux_bench_stats")
flux_bench_stats_eps=$(jq -r '.eps' <<<"$flux_bench_stats")
flux_bench_stats_ping=$(jq -r '.ping' <<<"$flux_bench_stats")
flux_bench_stats_download=$(jq -r '.download_speed' <<<"$flux_bench_stats")
flux_bench_stats_upload=$(jq -r '.upload_speed' <<<"$flux_bench_stats")
flux_bench_stats_speed_test_version=$(jq -r '.speed_version' <<<"$flux_bench_stats")
flux_bench_stats_error=$(jq -r '.error' <<<"$flux_bench_stats")

daemon_log=""
bench_log=""

#calculated block height since last confirmed
blockDiff=$((flux_daemon_block_height-flux_node_last_confirmed_height))
#blockDiff='25'


function update (){
  local userInput

  read -s -n 1 -t 1 userInput
  #'b' shows the last 5 lines of bench mark error log
  #'d' shows the last 5 lines of daemon error log
  #'q' will quit
  if [[ $userInput == 'b' ]]; then
    bench_log=$(tail -5 $BENCH_LOG_DIR)
    show_node='0'
    show_daemon='0'
    show_bench='1'
    redraw_term='1'
    sleep 0.1
  elif [[ $userInput == 'n' ]]; then
    show_node='1'
    show_daemon='0'
    show_bench='0'
    redraw_term='1'
    sleep 0.1
  elif [[ $userInput == 'd' ]]; then
    daemon_log=$(tail -5 $DAEMON_LOG_DIR)
    show_node='0'
    show_daemon='1'
    show_bench='0'
    redraw_term='1'
    sleep 0.1
  elif [[ $userInput == 'q' ]]; then
    clear
    exit
  else
    redraw_term='0'
  fi
}

# function check_status() {
#   if [[ $flux_bench_flux_status == "online" ]];
#   then
#     echo -e "Flux node status           -    ${GREEN}ONLINE${NC}"
#   else
#     echo -e "Flux node status           -    ${RED}OFFLINE${NC}"
#   fi
# }

# function check_bench() {
#   if [[ ($flux_bench_benchmark == "failed") || ($flux_bench_benchmark == "toaster") ]]; then
#     echo -e "Flux node benchmark        -    ${RED}$flux_bench_status${NC}"
#     read -p 'would you like to check for updates and restart benchmarks? (y/n) ' userInput
#     if [ $userInput == 'n' ]; then
#       echo 'user does not want to restart benchmarks'
#     else
#       echo 'user would like to restart benchmarks'
#       flux_update_benchmarks
#     fi
#   elif [[ $flux_bench_benchmark == "running" ]]; then
#     echo -e "${BLUE}node benchmarks running ... ${NC}"
#   elif [[ $flux_bench_benchmark == "dos" ]]; then
#     echo -e "${RED}node in denial of service state${NC}"
#   else
#     echo -e "Flux node benchmark        -    ${GREEN}$flux_bench_benchmark${NC}"
#   fi
# }

# function check_back(){
#   if [[ $flux_bench_back != *"connected"* ]];
#   then
#     echo -e "Flux back status           -    ${RED}DISCONNECTED${NC}"
#     read -p 'would you like to check for updates and restart flux-back? (y/n) ' userInput
#     if [ $userInput == 'n' ]; then
#       echo -e "${RED}user does not want to restart flux back${NC}"
#     else
#       echo -e "${BLUE}user would like to update and restart flux-back${NC}"
#       echo 'updating ... '
#       flux_update_restart
#     fi
#   else
#     echo -e "Flux back status           -    ${GREEN}CONNECTED${NC}"
#   fi
# }

# function node_os_update(){
#   sudo apt-get --with-new-pkgs upgrade -y && sudo apt autoremove -y
# }

# function flux_update_service(){
#   node_os_update
#   #sudo systemctl stop flux
#   #sleep 2
#   #sudo systemctl start flux
#   #sleep 5
# }

# function flux_update_benchmarks(){
#   node_os_update
#   #$BENCH_CLI restartnodebenchmarks
# }

function flux_daemon_info(){
  clear
  sleep 0.25
  make_header "$DASH_DAEMON_TITLE" "$BLUE"
  echo -e "$BLUE_CIRCLE   Flux daemon version          -    $flux_daemon_version"
  echo -e "$BLUE_CIRCLE   Flux protocol version        -    $flux_daemon_protocol_version"
  echo -e "$BLUE_CIRCLE   Flux daemon block height     -    $flux_daemon_block_height"
  echo -e "$BLUE_CIRCLE   Flux daemon connections      -    $flux_daemon_connections"
  echo -e "$BLUE_CIRCLE   Flux deamon difficulty       -    $flux_daemon_difficulty"
  make_header

  if [[ $daemon_log != "" ]]; then
    make_header "$DASH_DAEMON_ERROR_TITLE" "$RED"
    echo "$daemon_log"
    make_header
  fi
  navigation
}

function flux_node_info(){\
  clear
  sleep 0.25
  make_header "$DASH_NODE_TITLE" "$BLUE"
  echo -e "$BLUE_CIRCLE   Flux node status             -    $flux_node_status"
  echo -e "$BLUE_CIRCLE   Flux node added height       -    $flux_node_added_height"
  echo -e "$BLUE_CIRCLE   Flux node confirmed height   -    $flux_node_confirmed_height"
  echo -e "$BLUE_CIRCLE   Flux node last confirmed     -    $flux_node_last_confirmed_height"
  echo -e "$BLUE_CIRCLE   Flux node last paid height   -    $flux_node_last_paid_height"
  echo -e "$BLUE_CIRCLE   Blocks since last confirmed  -    $blockDiff"
  make_header
  navigation
}

function flux_benchmark_info(){\
  clear
  sleep 0.25
  make_header "$DASH_BENCH_TITLE" "$BLUE"
  echo -e "$BLUE_CIRCLE   Flux bench version           -    $flux_bench_version"
  echo -e "$BLUE_CIRCLE   Flux back status             -    $flux_bench_back"
  echo -e "$BLUE_CIRCLE   Flux bench status            -    $flux_bench_flux_status"
  echo -e "$BLUE_CIRCLE   Flux benchmarks              -    $flux_bench_benchmark"
  make_header "$DASH_BENCH_DETAILS_TITLE" "$BLUE"
  echo -e "$BLUE_CIRCLE   Bench Real Cores             -    $flux_bench_stats_real_cores"
  echo -e "$BLUE_CIRCLE   Bench Cores                  -    $flux_bench_stats_cores"
  echo -e "$BLUE_CIRCLE   Bench Ram                    -    $flux_bench_stats_ram"
  echo -e "$BLUE_CIRCLE   Bench SSD                    -    $flux_bench_stats_ssd"
  echo -e "$BLUE_CIRCLE   Bench HHD                    -    $flux_bench_stats_hhd"
  echo -e "$BLUE_CIRCLE   Bench ddWrite                -    $flux_bench_stats_ddwrite"
  echo -e "$BLUE_CIRCLE   Bench Total Storage          -    $flux_bench_stats_storage"
  echo -e "$BLUE_CIRCLE   Bench EPS                    -    $flux_bench_stats_eps"
  echo -e "$BLUE_CIRCLE   Bench Ping                   -    $flux_bench_stats_ping"
  echo -e "$BLUE_CIRCLE   Bench Download Speed         -    $flux_bench_stats_download"
  echo -e "$BLUE_CIRCLE   Bench Upload Speed           -    $flux_bench_stats_upload"
  echo -e "$BLUE_CIRCLE   Bench Speed Test Version     -    $flux_bench_stats_speed_test_version"
  echo -e "$BLUE_CIRCLE   Bench Errors                 -    $flux_bench_stats_error"
  make_header

   if [[ $bench_log != "" ]]; then
    make_header "$DASH_BENCH_ERROR_TITLE" "$RED"
    echo "$bench_log"
    make_header
  fi
  navigation
}

function make_header(){
  local output
  local inputLength
  local halfInputLength
  local HEADER_TEXT_START
  local HEADER_TEXT_STOP
  output=""
  if [[ -z $1 ]]; then
    for (( c=1; c<=$WINDOW_WIDTH; c++ ))
    do 
      output="${output}${_HLINE}"
    done
  else
    inputLength=${#1}
    halfInputLength=$(bc <<<"$inputLength / 2")
    HEADER_TEXT_START=$((WINDOW_HALF_WIDTH-halfInputLength))
    HEADER_TEXT_STOP=$((HEADER_TEXT_START+inputLength))
    for (( c=1; c<=$WINDOW_WIDTH; c++ ))
    do 
      if [[ $c -lt $HEADER_TEXT_START || $c -gt $HEADER_TEXT_STOP ]]; then
        output="${output}${NC}${_HLINE}"
      else
        offset=$((c-HEADER_TEXT_START))
        output="${output}${2}${1:offset:1}"
      fi
    done
  fi

  echo -e ${output}
}

function navigation(){
  echo -e "         d for daemon info | b for benchmarks | n for node | q to quit         " 
}

#checks the current window size and compares it to the last windows size to see if we need to redraw the term
function check_term_resize(){
  local currentWidth
  currentWidth=$(tput cols)
  if [[ $WINDOW_WIDTH -ne $currentWidth  ]]; then
    redraw_term='1'
  fi
}


function main_terminal(){
 
  while true; do
    check_term_resize

    WINDOW_WIDTH=$(tput cols)
    WINDOW_HALF_WIDTH=$(bc <<<"$WINDOW_WIDTH / 2")

    if [[ $redraw_term == '1' ]]; then
      if [[ $show_daemon == '1' ]]; then
        flux_daemon_info
      elif [[ $show_node == '1' ]]; then
        flux_node_info
      elif [[ $show_bench == '1' ]]; then
        flux_benchmark_info
      fi
    fi
    update
  done
}

main_terminal

