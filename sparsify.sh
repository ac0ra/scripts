#!/bin/bash


n=_$(md5sum 0004fb0000120000696a094c8cde710a.img| cut -d ' ' -f 1)
ns=_$(md5sum 0004fb0000120000696a094c8cde710a.img.sparse | cut-d ' ' -f 1)
if [$n != $ns]
then
	echo "files differ error abort! etc.."
	echo "file broke" 0004fb0000120000696a094c8cde710a.img and 0004fb0000120000696a094c8cde710a.img.sparse differ" >> sparsify.log
	exit
else
	rm 0004fb0000120000696a094c8cde710a.img
	mv 0004fb0000120000696a094c8cde710a.img.sparse 0004fb0000120000696a094c8cde710a.img
fi

cp --sparse=always 0004fb00001200009be631df9f9b05d1.img 0004fb00001200009be631df9f9b05d1.img.sparse
n=_$(md5sum 0004fb00001200009be631df9f9b05d1.img| cut -d ' ' -f 1)
ns=_$(md5sum 0004fb00001200009be631df9f9b05d1.img.sparse | cut-d ' ' -f 1)
if [$n != $ns]
then
	echo "files differ error abort! etc.."
	echo "file broke" 0004fb0000120000696a094c8cde710a.img and 0004fb0000120000696a094c8cde710a.img.sparse differ" >> sparsify.log
	exit
else
	rm 0004fb00001200009be631df9f9b05d1.img
	mv 0004fb00001200009be631df9f9b05d1.img.sparse 0004fb00001200009be631df9f9b05d1.img
fi






for f in *.img
	do
	fs=$f.sparse
	echo $f
	echo $fs
	if [ -a $fs ]
	then
		echo $fs "already exists"
	else
		cp --sparse=always $f $fs
		
		n=_$(md5sum $f | cut -d ' ' -f 1)
		ns=_$(md5sum $fs | cut -d ' ' -f 1)
		if [$n != $ns]
		then
		 	echo "files differ, error abort! etc.."
			echo "file broke" $f "and "fs" differ" >> sparsify.log
			break
		else
			echo "i would have deleted" $f
			#rm $f
		fi
	fi
done
		
		
		
	

