#!/bin/sh

print_help() {
  printf 'USAGE: %s DIF [FLOW_ID]\n' "$0"
}

rlite_ctl() {
   if [ "$1" = "flows-show" ]; then
   cat <<EOF
Flows table:
  ipcp 2, addr:port 1:2<-->3:2, rx(pkt:1, 32B, drop:0), tx(pkt:1, 48B, drop:0), rtx(pkt:0, 0B)
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
  fi
}

gather() {


if [ -z "$FLOW_ID" ]; then
  FLOW_ID="$(rlite-ctl flows-show | sed -n -e '$ s/.*addr:port [[:digit:]]\+:\([[:digit:]]\+\).*/\1/p')"
fi

if [ -z "$FLOW_ID" ]; then
   echo "Failed to get a flow id" >&2
   exit 1
fi

TIME=0
OUTFILE="$DIF-$FLOW_ID.cvs"
while true; do
   printf "%s," "$TIME" >> "$OUTFILE"
   rlite-ctl flow-dump "$FLOW_ID" | sed -e 's/.*= \([[:digit:]]\+\).*/\1/' | awk -F'\n' '{if(NR == 1) {printf $0} else {printf ","$0}}' >> "$OUTFILE"
   printf '\n' >> "$OUTFILE"
   sleep 1
   TIME=$((TIME + 1))
done

}


DIF="$1"

if [ -n "$2" ]; then
  FLOW_ID="$2"
fi

if [ -z "$DIF" ]; then
   print_help
   return 1
fi

gather
