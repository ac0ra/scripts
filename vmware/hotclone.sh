#!/bin/bash

# ESXi hosts
HOSTS=(10.150.100.16)

# For each host, indicate vm datastore name in order
DS=(datastore1)

# Backup datastore
BDSTORE="x.x.x.x::vmbak-casc-dc"

for (( i = 0 ; i < ${#HOSTS[@]} ; i++ )) do
 host=${HOSTS[$i]}
 dstore=${DS[$i]}

 # Get vms list
 ssh root@$host 'vim-cmd vmsvc/getallvms' > /tmp/vmlist-temp
 sed 1d /tmp/vmlist-temp > /tmp/vmlist

 # Iterate backup sequence
 exec 3</tmp/vmlist
 while read <&3; do
  line=$REPLY
  #echo "VM: $line"

  # Get VM id
  id=`echo "$line" | awk '{print $1}'`
  vmname=`echo "$line" | awk '{print $2}'`
  echo $id
  ts=`date +%y%m%d-%H%M`
  echo $ts
  # Create snapshot
  echo "ssh root@$host 'vim-cmd vmsvc/snapshot.create $id $vmname-$ts $vmname-$ts'"
  ssh root@$host "vim-cmd vmsvc/snapshot.create $id $vmname-$ts $vmname-$ts"

  # Copy snapshot to remote datastore
  #echo "ssh root@$host 'scp -i /.ssh/id_dsa -r /vmfs/volumes/${dstore}/$vmname $BDSTORE'"
  #ssh root@$host 'scp -i /.ssh/id_dsa -r /vmfs/volumes/${dstore}/$vmname $BDSTORE'

  # This is the rsync option
  echo "time ssh root@$host 'rsync -av /vmfs/volumes/${dstore}/$vmname $BDSTORE'"
  time ssh root@$host "rsync -av /vmfs/volumes/${dstore}/$vmname $BDSTORE"

  # Remove snapshot to merge back delta file
  echo "ssh root@$host 'vim-cmd vmsvc/snapshot.removeall $id'"
  ssh root@$host "vim-cmd vmsvc/snapshot.removeall $id"
 done
 exec 3>&-
done
