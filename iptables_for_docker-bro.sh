#!/bin/bash
IFOUT="enp9s0"

IPDESTINATION_SIP="192.168.88.41"
ALLOW_APP_PORT="80,443,3307,3308,7379,3000,8291,3040,3030,7100,6379"
ALLOW_LIST_IP_FILE="./iplist.txt"
ALLOW_LIST_IP_FILE_CLOUDFIRE="./iplist_cloudfire.txt"
ALLOW_ADMIN_PORT="22,10050,10051,31194"


echo "==============  OUR NET ==========="
ALLOW_LIST_IP_FILE_LIST=$(cat $ALLOW_LIST_IP_FILE | paste -d "," -s)
echo $ALLOW_LIST_IP_FILE_LIST
echo "==============CLOUD FIRE==========="
ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE=$(cat $ALLOW_LIST_IP_FILE_CLOUDFIRE | paste -d "," -s)
echo $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE

#iptables -S | grep "A " |  perl -ne 'print "iptables $_"' > defaultiptablerules.sh

#chmod +x defaultiptablerules.sh

#sed -i '1s@^@#!/bin/bash\n@'  defaultiptablerules.sh


iptables -F

iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -N DOCKER
iptables -N DOCKER-ISOLATION-STAGE-1
iptables -N DOCKER-ISOLATION-STAGE-2
iptables -N DOCKER-USER



echo "ALLOW_ADMIN_PORT $ALLOW_ADMIN_PORT"
echo "ALLOW_ADMIN_IP   $ALLOW_ADMIN_IP"
echo "ALLOW_APP_PORT   $ALLOW_APP_PORT"

iptables -A INPUT -s $ALLOW_LIST_IP_FILE_LIST -i $IFOUT -p tcp -m multiport --dports $ALLOW_ADMIN_PORT  -j ACCEPT
iptables -A INPUT -s $ALLOW_LIST_IP_FILE_LIST -i $IFOUT -p icmp  -j ACCEPT


iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 80 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 80 -j ACCEPT

iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 443 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 443 -j ACCEPT

iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 6379 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 6379 -j ACCEPT

iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 8080 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 8080 -j ACCEPT


iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 8090 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 8090 -j ACCEPT

iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 5432 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 5432 -j ACCEPT


iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST_CLOUDFIRE -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 5433 -j ACCEPT
iptables -I DOCKER-USER -i $IFOUT -s $ALLOW_LIST_IP_FILE_LIST -m conntrack --ctdir ORIGINAL -p tcp --ctorigdstport 5433 -j ACCEPT


iptables -A DOCKER-USER -i $IFOUT -m conntrack --ctdir ORIGINAL -j DROP






iptables -A INPUT -i $IFOUT -p tcp -m multiport --dports $ALLOW_APP_PORT,$ALLOW_ADMIN_PORT -j DROP


#iptables -A INPUT -i $IFOUT -j DROP

#source ./defaultiptablerules.sh



#####Default rules Docker 
iptables -A FORWARD -j DOCKER-USER
iptables -A FORWARD -j DOCKER-ISOLATION-STAGE-1
iptables -A FORWARD -o br-c9ce238a8765 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o br-c9ce238a8765 -j DOCKER
iptables -A FORWARD -i br-c9ce238a8765 ! -o br-c9ce238a8765 -j ACCEPT
iptables -A FORWARD -i br-c9ce238a8765 -o br-c9ce238a8765 -j ACCEPT
iptables -A FORWARD -o br-811aa2f698e3 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o br-811aa2f698e3 -j DOCKER
iptables -A FORWARD -i br-811aa2f698e3 ! -o br-811aa2f698e3 -j ACCEPT
iptables -A FORWARD -i br-811aa2f698e3 -o br-811aa2f698e3 -j ACCEPT
iptables -A FORWARD -o br-a0dfeecce081 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o br-a0dfeecce081 -j DOCKER
iptables -A FORWARD -i br-a0dfeecce081 ! -o br-a0dfeecce081 -j ACCEPT
iptables -A FORWARD -i br-a0dfeecce081 -o br-a0dfeecce081 -j ACCEPT
iptables -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o docker0 -j DOCKER
iptables -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
iptables -A FORWARD -i docker0 -o docker0 -j ACCEPT
iptables -A DOCKER -d 172.18.0.2/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 8000 -j ACCEPT
iptables -A DOCKER -d 172.18.0.8/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A DOCKER -d 172.18.0.8/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A DOCKER -d 172.18.0.5/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 5432 -j ACCEPT
iptables -A DOCKER -d 172.18.0.6/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 8080 -j ACCEPT
iptables -A DOCKER -d 172.18.0.6/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 8000 -j ACCEPT
iptables -A DOCKER -d 172.18.0.6/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 4200 -j ACCEPT
iptables -A DOCKER -d 172.18.0.6/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 3001 -j ACCEPT
iptables -A DOCKER -d 172.18.0.6/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 3000 -j ACCEPT
iptables -A DOCKER -d 172.18.0.6/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A DOCKER -d 172.20.0.2/32 ! -i br-c9ce238a8765 -o br-c9ce238a8765 -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A DOCKER -d 172.18.0.3/32 ! -i br-a0dfeecce081 -o br-a0dfeecce081 -p tcp -m tcp --dport 6379 -j ACCEPT
iptables -A DOCKER-ISOLATION-STAGE-1 -i br-c9ce238a8765 ! -o br-c9ce238a8765 -j DOCKER-ISOLATION-STAGE-2
iptables -A DOCKER-ISOLATION-STAGE-1 -i br-811aa2f698e3 ! -o br-811aa2f698e3 -j DOCKER-ISOLATION-STAGE-2
iptables -A DOCKER-ISOLATION-STAGE-1 -i br-a0dfeecce081 ! -o br-a0dfeecce081 -j DOCKER-ISOLATION-STAGE-2
iptables -A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
iptables -A DOCKER-ISOLATION-STAGE-1 -j RETURN
iptables -A DOCKER-ISOLATION-STAGE-2 -o br-c9ce238a8765 -j DROP
iptables -A DOCKER-ISOLATION-STAGE-2 -o br-811aa2f698e3 -j DROP
iptables -A DOCKER-ISOLATION-STAGE-2 -o br-a0dfeecce081 -j DROP
iptables -A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
iptables -A DOCKER-ISOLATION-STAGE-2 -j RETURN
iptables -A DOCKER-USER -j RETURN



###OPENVPN


iptables -A INPUT -i $IFOUT -m state --state NEW -p udp --dport 31134 -j ACCEPT
iptables -A INPUT -i $IFOUT -m state --state NEW -p tcp --dport 31134 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 31194 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --dport 31194 -j ACCEPT

iptables -A INPUT -p tcp -m udp --dport 31194 -j ACCEPT
iptables -A OUTPUT -p tcp -m udp --dport 31194 -j ACCEPT


#iptables -A DOCKER-INGRESS -i $IFOUT -j DROP
#iptables -A DOCKER-INGRESS -i $IFOUT -j DROP


iptables -n -L -v --line-numbers
echo "============================================================================"
iptables -S


ip a | grep tun
ps -ef | grep openvpn
ping -c 5 $IPDESTINATION_SIP
