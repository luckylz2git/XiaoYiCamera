#!/bin/sh

echo 'BTServer >> Start...'
if [ -f /usr/local/share/script/setup_bluetooth.sh ]; then

	if [ -f /usr/bin/i_example_util ]; then
	
		if [ -f /usr/bin/lu_example_util ]; then
	
			if [ -f /usr/local/share/script/BTServer ]; then
	
				/usr/local/share/script/setup_bluetooth.sh
				/usr/bin/i_example_util
				/usr/bin/lu_example_util
				/usr/local/share/script/BTServer
				#/tmp/fuse_d/BTServer
	
			else
				echo 'BTServer >> BTServer not exist!!!'
			fi
	
		else
			echo 'BTServer >> lu_example_util not exist!!!'
		fi
	
	else
		echo 'BTServer >> i_example_util not exist!!!'
	fi

else
	echo 'BTServer >> setup_bluetooth.sh not exist!!!'
fi
echo 'BTServer >> End...'
