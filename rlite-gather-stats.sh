#!/bin/sh

print_help() {
  printf 'USAGE: %s\n' "$0"
}

rlite_ctl() {
   if [ "$1" = "flows-show" ]; then
   cat <<EOF
Flows table:
  ipcp 0, addr:port 1:2<-->3:2, rx(pkt:1, 32B, drop:0), tx(pkt:1, 48B, drop:0), rtx(pkt:0, 0B)
  ipcp 2, addr:port 1:3<-->3:3, rx(pkt:29, 870B, drop:0), tx(pkt:30, 918B, drop:0), rtx(pkt:0, 0B)
EOF
  elif [ "$1" = "flow-dump" ]; then
  cat <<EOF
snd_lwe                = 0
snd_rwe                = 0
next_seq_num_to_use    = 56
last_seq_num_sent      = 55
last_ctrl_seq_num_rcvd = 0
cwq_len                = 0 [max=0]
rtxq_len               = 0 [max=0]
rtt                    = 0ms [stddev=3ms]
cgwin                  = 0
rcv_lwe                = 1
rcv_next_seq_num       = 55
rcv_rwe                = 0
max_seq_num_rcvd       = 54
last_lwe_sent          = 1
last_seq_num_acked     = 1
next_snd_ctl_seq       = 0
seqq_len               = 0
EOF
  elif [ "$1" = "ipcps-show" ]; then
    cat <<EOF
IPC Processes table:
	id=0, name='300.1.IPCP', dif_type='shim-eth', dif_name='300.DIF', address=*, txhdroom=0, rxhdroom=0, troom=0, mss=1500
	id=1, name='n1.1.IPCP', dif_type='normal', dif_name='n1.DIF', address=3, txhdroom=28, rxhdroom=0, troom=0, mss=1472
	id=2, name='n3.1.IPCP', dif_type='normal', dif_name='n3.DIF', address=3, txhdroom=56, rxhdroom=0, troom=0, mss=1444
EOF
  fi
}

gather() {

DIFS="$(rlite-ctl ipcps-show | sed -n -e 's/.*dif_name='\''\([[:graph:]]\+\)'\''.*/\1/p')"
START_TIME=$(date +%s%N)

while true; do
  for DIF in $DIFS; do
    FLOW_IDS="$(rlite-ctl flows-show "$DIF" | sed -n -e 's/.*addr:port [[:digit:]]\+:\([[:digit:]]\+\).*/\1/p')"

    if [ -z "$FLOW_IDS" ]; then
      continue
    fi

    for FLOW_ID in $FLOW_IDS; do
      TIME="$(date +%s%N)"
      printf "%s,%s,%s," "$(echo $((TIME-START_TIME)) | sed 's/\([0-9]\+\)\([0-9]\{9\}\)/\1.\2/')" "$DIF" "$FLOW_ID"
      rlite-ctl flow-dump "$FLOW_ID" | sed -e 's/.*= \([[:digit:]]\+\).*/\1/' | awk -F'\n' '{if(NR == 1) {printf $0} else {printf ","$0}}'
      printf '\n'
    done
  done
  sleep 0.01
done

}

if [ "$1" = "-h" ]; then
   print_help
   return 1
fi

gather
