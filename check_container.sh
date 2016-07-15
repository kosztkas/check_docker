#!/bin/bash

# Author: Sandor Kosztka
# Email: sandor.kosztka@gmail.com
# License: MIT
# Nagios Usage: nrpe usage TODO
# Usage: ./check__container.sh _container_id_ <options>
#---
# The running() function checks if a container is running and grabs some base information
#   OK - running
#   WARNING - container is dead
#   CRITICAL - container is stopped
#   UNKNOWN - does not exist
#---
# The cpu() function checks the cpu% used by the container
#   OK - within limits
#   WARNING - CPU% is more than specified with -W flag
#   CRITICAL - CPU% is more than specified with the -C flag
#   UNKNOWN - not used yet
#---
# The memused() function checks the memory% used by the container
#   OK - running
#   WARNING -  MEM% is more than specified with -W flag
#   CRITICAL -  MEM% is more than specified with -C flag
#   UNKNOWN - not used yet

ALLOWED_TESTS=" running cpu memused "
MESSAGE="UNKNOWN"
RETVAL=3

usage()
{
    cat << EOF
    usage: $0 _container_id_ options
    This script helps monitoring docker containers with nagios.

    OPTIONS:
    -h      Print Help (this message) and exit
    -w      Warning "less then" value
    -W      Warning "more then" value
    -c      Critical "less then" value
    -C      Critical "more then" value
    -T      Set check test type
EOF
}

finish()
{
    echo -e "$MESSAGE"
    exit $RETVAL
}

wrong_command()
{
    MESSAGE="Wrong command"
    RETVAL=$UNKNOWN
    finish
}
# check container running
#./check__container.sh _container_id_ -T running
running()
{
    RUN=$(docker inspect --format="{{ .State.Running }}" $CONTAINER 2> /dev/null)

    if [ $? -eq 1 ]; then
        MESSAGE="UNKNOWN - $CONTAINER does not exist."
        RETVAL=3
    fi

    if [ "$RUN" == "false" ]; then
        MESSAGE="CRITICAL - $CONTAINER is not running."
        RETVAL=2
    fi

    DEAD=$(docker inspect --format="{{ .State.Dead }}" $CONTAINER)

    if [ "$DEAD" == "true" ]; then
        MESSAGE="WARNING - $CONTAINER is dead."
        RETVAL=1
    fi

    STARTED=$(docker inspect --format="{{ .State.StartedAt }}" $CONTAINER)
    NETWORK=$(docker inspect --format="{{ .NetworkSettings.IPAddress }}" $CONTAINER)

    MESSAGE="OK - $CONTAINER is running. IP: $NETWORK, StartedAt: $STARTED"

    #echo "OK - $CONTAINER is running. IP: $NETWORK, StartedAt: $STARTED | cpu=$CPU mem=$MEMUSAGE memused=$MEMUSED netIn=$NETIN netOut=$NETOUT"
    finish
}

# check container cpu%
# ./check__container.sh _container_id_ -W 70 -C 90 -T cpu
cpu()
{
    STATS=$(docker stats --no-stream $CONTAINER | tail -1)
    CPU=$(echo $STATS | awk '{print $2}' | head -c -2)

    if [[ `echo "$CPU > $HIGHWARNING" | bc` == 1 ]] ; then
        MESSAGE="WARNING - $CPU% cpu used!"
        RETVAL=1
    fi
    if [[ `echo "$CPU > $HIGHCRITICAL" | bc` == 1 ]] ; then
        MESSAGE="CRITICAL - $CPU% cpu used!"
        RETVAL=2
    else
        MESSAGE="OK"
        RETVAL="0"
    fi
    return $RETVAL
}

# check container mem%
# ./check__container.sh _container_id_ -W 70 -C 90 -T memused
memused()
{
    STATS=$(docker stats --no-stream $CONTAINER | tail -1)
    MEMUSED=$(echo $STATS | awk '{print $8}' | head -c -2)


    if [[ `echo "$MEMUSED > $HIGHWARNING" | bc` == 1 ]] ; then
        MESSAGE="WARNING - $MEMUSED% memory used!"
        RETVAL=1
    fi
    if [[ `echo "$MEMUSED > $HIGHCRITICAL" | bc` == 1 ]] ; then
        MESSAGE="CRITICAL - $MEMUSED% memory used!"
        RETVAL=2
    else
        MESSAGE="OK"
        RETVAL="0"
    fi
    return $RETVAL
}

#Argument processing
#Take the mandatory container name from the first param then shift it to make getopts work
#unless using the helper, in that case leave it
if [[ "$1" != "-h" ]]; then
    CONTAINER=$1
    shift
fi

#Process the optargs
while getopts "hw:W:c:C:T:" OPTION
    do
        case $OPTION in
            h)
            usage
            exit 1
            ;;
            w)
            LOWWARNING=$OPTARG
            ;;
            W)
            HIGHWARNING=$OPTARG
            ;;
            c)
            LOWCRITICAL=$OPTARG
            ;;
            C)
            HIGHCRITICAL=$OPTARG
            ;;
            T)
            if [[ "$ALLOWED_TESTS" =~ " $OPTARG " ]];
                then
                    $OPTARG
                    RETVAL=$?
                else wrong_command
            fi
            finish
            ;;
            *)
            usage
            exit
            ;;
        esac
    done
