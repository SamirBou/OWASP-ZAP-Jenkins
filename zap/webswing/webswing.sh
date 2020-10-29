#!/bin/sh
#
# Startup script for the Webswing 
#
# Use following variables to override default settings:
# WEBSWING_HOME
# WEBSWING_OPTS
# WEBSWING_JAVA_HOME
# WEBSWING_JAVA_OPTS
# WEBSWING_LOG_FILE
# WEBSWING_PID_FILE
# 
# for example: 
# WEBSWING_HOME=/home/webswing WEBSWING_JAVA_HOME=/var/share/jdk8 ./webswing.sh start

export HOME=`dirname $0`
export OPTS="-h 0.0.0.0 -j $HOME/jetty.properties -c $HOME/webswing.config"
export JAVA_HOME=$JAVA_HOME
export JAVA_OPTS=-Xmx128M
export LOG=$HOME/webswing.out
export PID_PATH_NAME=$HOME/webswing.pid

if [ -n "$WEBSWING_HOME" ]; then
    HOME="$WEBSWING_HOME"
fi  
if [ -n "$WEBSWING_OPTS" ]; then
    OPTS=$WEBSWING_OPTS
fi  
if [ -n "$WEBSWING_JAVA_HOME" ]; then
    JAVA_HOME=$WEBSWING_JAVA_HOME
fi  
if [ -n "$WEBSWING_JAVA_OPTS" ]; then
    JAVA_OPTS=$WEBSWING_JAVA_OPTS
fi 
if [ -n "$WEBSWING_LOG_FILE" ]; then
    LOG=$WEBSWING_LOG_FILE
fi 
if [ -n "$WEBSWING_PID_FILE" ]; then
    PID_PATH_NAME=$WEBSWING_PID_FILE
fi 


if [ -z `command -v $0` ]; then 
    CURRENTDIR=`pwd`
    cd `dirname $0` > /dev/null
    SCRIPTPATH=`pwd`/
    cd $CURRENTDIR
else
    SCRIPTPATH="" 
fi

if [ ! -f $HOME/webswing-server.war ]; then
    echo "Webswing executable not found in $HOME folder" 
    exit 1
fi

if [ ! -f $JAVA_HOME/bin/java ]; then
    echo "Java installation not found in $JAVA_HOME folder" 
    exit 1
fi
if [ -z `command -v xvfb-run` ]; then
    echo "Unable to locate xvfb-run command. Please install Xvfb before starting Webswing." 
    exit 1
fi
if [ ! -z `command -v ldconfig` ]; then
    if [ `ldconfig -p | grep -i libxext.so | wc -l` -eq 0 ]; then 
        echo "Missing dependent library libXext."
        exit 1
    fi
    if [ `ldconfig -p | grep -i libxi.so | wc -l` -eq 0 ]; then
        echo "Missing dependent library libXi."
        exit 1
    fi
    if [ `ldconfig -p | grep -i libxtst.so | wc -l` -eq 0 ]; then
        echo "Missing dependent library libXtst"
        exit 1
    fi
    if [ `ldconfig -p | grep -i libxrender.so | wc -l` -eq 0 ]; then
        echo "Missing dependent library libXrender."
        exit 1
    fi
fi

# See how we were called.
case "$1" in
    run)
        # Run Webswing server- expects X Server to be running
        if [ ! -f $PID_PATH_NAME ] || [ `ps -axo pid | grep "$(cat $PID_PATH_NAME)" | wc -l` -eq 0 ]; then
            $JAVA_HOME/bin/java $JAVA_OPTS -jar $HOME/webswing-server.war $OPTS 2>> $LOG >> $LOG &
            echo $! > $PID_PATH_NAME
            wait $(cat $PID_PATH_NAME)
        else
            echo "Webswing is already running with pid $(cat $PID_PATH_NAME)"
        fi
        ;;
    start)
        # Start daemon.
        if [ ! -f $PID_PATH_NAME ] || [ `ps -axo pid | grep "$(cat $PID_PATH_NAME)" | wc -l` -eq 0 ]; then
            echo "Starting Webswing... "
            echo "HOME:$HOME"
            echo "OPTS:$OPTS"
            echo "JAVA_HOME:$JAVA_HOME"
            echo "JAVA_OPTS:$JAVA_OPTS"
            echo "LOG:$LOG"
            echo "PID:$PID_PATH_NAME"
            xvfb-run $SCRIPTPATH$0 run  &
            echo "Webswing STARTED"
        else
            echo "Webswing is already running with pid $(cat $PID_PATH_NAME)"
        fi
        ;;
    stop)
        if [ -f $PID_PATH_NAME ]; then
            echo "Webswing stoping ..."
            kill -9 $(cat $PID_PATH_NAME);
            if [ `ps -axo pid | grep "$(cat $PID_PATH_NAME)" | wc -l` -eq 0 ]; then
                echo "Webswing stopped ..."
                rm $PID_PATH_NAME
            else
                echo "Stopping Webswing failed."
                exit 1
            fi
        else
            echo "Webswing is not running ..."
        fi
    ;;
    status)
        if [ -f $PID_PATH_NAME ]; then
            if [ `ps axo pid | grep "^ *$(cat $PID_PATH_NAME)$" | wc -l` -eq 0 ]; then
                rm $PID_PATH_NAME
            else
                echo "Webswing is running with pid $(cat $PID_PATH_NAME)."
            fi
        else
            echo "Webswing is not running ..."
        fi
    ;;
    restart)
        $SCRIPTPATH$0 stop
        $SCRIPTPATH$0 start
    ;;
    *)
        echo "Usage: $0 {run|start|stop|restart|status}"
        exit 1
esac

exit 0
