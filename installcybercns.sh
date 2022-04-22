#!/bin/bash

verifySaltconf(){
    FILE=/etc/salt/minion.d/minion.conf
    if [ -f "$FILE" ]; then
        echo "Salt already configured in this system. If any issues please contact support@cybercns.com"
        exit 0
    fi
}

verifyPortConnStatus() {
    echo "Verifying Port Connectivity To CyberCNS Central Server"
    SERVER="cybercnscentral.mycybercns.com"
    MSG="Please open port birectionaly with $SERVER and initiate installation process"
    tmp=$(nc -w 2 -v $SERVER 443 >/dev/null)
    if [ "$?" -ne 0 ]; then
      echo "Connection to $SERVER on port 443 failed, $MSG"
      exit 1
    fi
    tmp=$(nc -w 2 -v $SERVER 4505 >/dev/null)
    if [ "$?" -ne 0 ]; then
      echo "Connection to $SERVER on port 4505 failed, $MSG"
      exit 1
    fi
    tmp=$(nc -w 2 -v $SERVER 4506 >/dev/null)
    if [ "$?" -ne 0 ]; then
      echo ""
      echo "Connection to $SERVER on port 4506 failed, $MSG"
      echo ""
      exit 1
    fi
}

verifySystemRequirements() {
    ram=`free -g | awk '/Mem:/ { print $2 }' `
    diskSize=`df -m / | egrep -v 'Filesystem' | awk '{print $2}'`
    . /etc/lsb-release
    if [[ "$DISTRIB_RELEASE" != "20.04" && "$DISTRIB_RELEASE" != "18.04" ]] || [[ "$DISTRIB_ID" != "Ubuntu" ]];
    then
        echo "CyberCNS Installation Will Support Only On Ubuntu 20.04 Systems"
        exit 0
    fi
    if [ $ram -lt 15 ];
     then
      echo "Minimum 16GB Of RAM Required For CyberCNS To Configure But Provided is "$ram"GB, Quiting Installation Process"
      exit 0
    fi
    if [ $diskSize -lt 97000 ];
    then
    echo "Minimum 100GB Of Root Partition Required For CyberCNS To Configure But Provided is "`df -h / | egrep -v 'Filesystem' | awk '{print $2}'`", Quiting Installation Process"
    exit 0
    fi
}

readUserInputs() {
  variable=""
  eval input="$1"
  eval length="$2"
  while true
  do
    read -p "$input"  variable
    if [ ${#variable} -lt $length ]
    then
        echo "Input is not valid minimun $2 characters required"
    else
        break
    fi
  done
  eval "$3=$variable"
}

# Verifying Salt Config Status
verifySaltconf

# Verifying Port Connectivity Status
verifyPortConnStatus

# Verifying CyberCNS Dependencies
verifySystemRequirements

email="nic@ewtpro.com"
#confirmemail=""
#readUserInputs "Please\ enter\ your\ Email:-\ " 6 email
#readUserInputs "Please\ confirm\ your\ Email:-\ " 6 confirmemail

#if [ "$email" != "$confirmemail" ]; then
#    echo "Email is not matching with confirm Email"
#    exit
#fi

wget https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh
chmod +x bootstrap-salt.sh
bash bootstrap-salt.sh -x python3

cat <<EOF >/etc/salt/minion.d/minion.conf
id: $email
master: cybercnscentral.mycybercns.com
acceptance_wait_time: 60
EOF

systemctl restart salt-minion

echo "All Done!! Please wait for some more time for the installation to finish."
