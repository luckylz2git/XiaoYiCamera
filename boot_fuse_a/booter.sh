#!/bin/sh
timeout=10
SCRIPTS=/tmp/fuse_a/custom/
DEFAULT=0_default.ash
AUTOEXEC=/tmp/fuse_a/autoexec.ash
GPIO=/proc/ambarella/gpio
ashmax=0

proc_gpio_write()
{
  gpiohex=`printf %02x ${1}`
  echo -en 'c\x'"${gpiohex}"'\x01' > $GPIO
  if [ "${2}" == "0" ]; then
    echo -en 'w\x'"${gpiohex}"'\x00' > $GPIO
  fi

  if [ "${2}" == "1" ]; then
    echo -en 'w\x'"${gpiohex}"'\x01' > $GPIO
  fi
}

proc_gpio_read()
{
  cut -c $(($1 + 1)) $GPIO
}

beacon_blink()
{
  # $1 - beacon $2 - times $3 - duration
  for i in $( seq 1 ${2} );
  do
    proc_gpio_write ${1} 0
    sleep ${3}
    proc_gpio_write ${1} 1
    sleep ${3}
  done
}

if [ $( proc_gpio_read 13 ) -eq 0 ];
then

  while read num name
  do
    if [ $num -gt $ashmax ]; then ashmax=$num; fi
    echo $num"-"$name
    eval ash$num="$name"
  done << FFF
  $(ls $SCRIPTS | grep -E '[1-9]_.*\.ash' | sed 's=_= =')
FFF

  beacon_blink 12 $timeout 0.5 &

  cnt=0
  tstart=$( date +%s )
  tinit=$( proc_gpio_read 95 )
  while true;
  do
    tlast=$( proc_gpio_read 95 )
    if [ $tinit -ne $tlast ] && [ $tlast -eq 0 ]; then
      cnt=$(( $cnt + 1))
      echo $cnt
      if [ $cnt -gt $ashmax ]; then
        beacon_blink 54 20 0.1
        exit
      fi
      beacon_blink 114 1 0 &
    fi
    tinit=$tlast
    if [ $(($( date +%s ) - $tstart)) -ge $timeout  ]; then
      break
    fi
  done
  sleep 2

  if [ $cnt -eq 0 ];then cat $SCRIPTS$DEFAULT > $AUTOEXEC; sleep 1; reboot; fi

  beacon_blink 54 $cnt 0.2

  if [ ! -z "$(eval echo \$ash$cnt)" ]; then
    cat $SCRIPTS$DEFAULT > $AUTOEXEC
    eval cat "\$SCRIPTS\$cnt\_\$ash$cnt" >> $AUTOEXEC
  else
    beacon_blink 54 20 0.1
    exit
  fi
  sleep 1
  reboot
fi
