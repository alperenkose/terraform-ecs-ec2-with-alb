#!/bin/bash

/bin/echo '#!/bin/bash
if [[ $(sudo /usr/sbin/iptables -t nat -L) != *"MASQUERADE"* ]]; then
  /bin/echo 1 > /proc/sys/net/ipv4/ip_forward

  for s in ${join(" ", private_subnets_cidr_blocks)};
  do
    /usr/bin/logger -i -t "user_data" "Setting NAT for $s subnet"
    /usr/sbin/iptables -t nat -A POSTROUTING -s $s -j MASQUERADE
  done

fi
' | sudo /usr/bin/tee /sbin/ifup-local

sudo chmod +x /sbin/ifup-local
sudo /sbin/ifup-local
