#!/bin/bash

## CONFIGURATION ##

realm=null
principal=$user@$realm
keytab=./$user.keytab
domain=null
ns=null

export KRB5CCNAME="/tmp/dhcp-dyndns.cc"

# keytab can be generated using
# $ ktutil
# ktutil: addent -password -p dhcpduser@EXAMPLE.COM -k 1 -e aes256-cts-hmac-sha1-96
# Password for dhcpduser@EXAMPLE.COM:
# ktutil: wkt dhcpduser.keytab
# ktutil: quit

## VARIABLES ##

action=$1
ip=$2
name=$(echo $3 | awk -F '.' '{print $1}')
mac=$4

usage()
{
echo "USAGE:"
echo $0 add 192.0.2.123 testhost 00:11:22:33:44:55
echo $0 add 192.168.0.127 "" 00:11:22:44:33:55
echo $0 delete 192.0.2.123 testhost 00:11:22:33:44:55
echo $0 delete 192.0.2.127 "" 00:11:22:44:33:55
}

if [ "$ip" = "" ]; then
echo "IP missing"
usage
exit 101
fi
if [ "$name" = "" ]; then
#echo "name missing"
#usage
#exit 102
name=$(echo $ip | awk -F '.' '{print "dhcp-"$1"-"$2"-"$3"-"$4}')

if [ "$action" = "delete" ]; then
name=$(host $ip | awk '{print $5}' | awk -F '.' '{print $1}')

echo $name | grep NXDOMAIN 2>$1 >/dev/null
if [ "$?" = "0" ]; then
exit 0;
fi
fi
fi

ptr=$(echo $ip | awk -F '.' '{print $4"."$3"."$2"."$1".in-addr.arpa"}')

## KERBEROS ##

#export LD_LIBRARY_PATH=/usr/local/krb5-1.7/lib
#export PATH=/usr/local/krb5-1.7/bin:$PATH

klist 2>&1 | grep $realm | grep '/' > /dev/null
if [ "$?" = 1 ]; then
expiration=0
else
expiration=$(klist | grep $realm | grep '/' | awk -F ' ' '{system ("date -d \""$2"\" +%s")}' | sort | head -n 1)
fi

now=$(date +%s)
if [ "$now" -ge "$expiration" ]; then
echo "Getting new ticket, old one expired $expiration, now is $now"
kinit -F -k -t $keytab $principal
fi

## NSUPDATE ##

case "$action" in
add)
echo "Setting $name.$domain to $ip on $ns"

oldname=$(host $ip $ns | grep "domain name pointer" | awk '{print $5}' | awk -F '.' '{print $1}')
if [ "$oldname" = "" ]; then
oldname=$name
elif [ "$oldname" = "$name" ]; then
oldname=$name
else
echo "Also deleting $oldname A record"
fi

nsupdate -g <
server $ns
realm $realm
update delete $oldname.$domain 3600 A
update delete $name.$domain 3600 A
update add $name.$domain 3600 A $ip
send
UPDATE
result1=$?
nsupdate -g <
server $ns
realm $realm
update delete $ptr 3600 PTR
update add $ptr 3600 PTR $name.$domain
send
UPDATE
result2=$?
;;

delete)
echo "Deleting $name.$domain to $ip on $ns"
nsupdate -g <
server $ns
realm $realm
update delete $name.$domain 3600 A
send
UPDATE
result1=$?
nsupdate -g <
server $ns
realm $realm
update delete $ptr 3600 PTR
send
UPDATE
result2=$?
;;
*)
echo "Invalid action specified"
exit 103
;;
esac

result=$result1$result2
if [ "$result" != "00" ]; then
echo "DHCP-DNS Update failed: $result"
logger "DHCP-DNS Update failed: $result"
fi


exit $result

and here is the relevant part of my dhcpd.conf:

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientMac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
set ClientName = pick-first-value(option host-name, host-decl-name, config-option host-name, noname);
log(concat("Commit: IP: ", ClientIP, " Mac: ", ClientMac, " Name: ", ClientName));

execute("/root/dhcp-dyndns.sh", "add", ClientIP, ClientName, ClientMac);
}
on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientMac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
log(concat("Release: IP: ", ClientIP, " Mac: ", ClientMac));
# cannot get a ClientName here, for some reason that always fails

execute("/root/dhcp-dyndns.sh", "delete", ClientIP, "", ClientMac);
}
on expiry {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
# cannot get a ClientMac here, apparently this only works when actually receiving a packet
log(concat("Expired: IP: ", ClientIP));
# cannot get a ClientName here, for some reason that always fails


execute("/root/dhcp-dyndns.sh", "delete", ClientIP, "", "0");
}
