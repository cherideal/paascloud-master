#!/bin/bash
servicePort=8020
serviceName=$(basename `pwd`)
if [ ! -d "/data/logs/paascloud/$serviceName" ]; then
  mkdir -p /data/logs/paascloud/$serviceName
  touch /data/logs/paascloud/$serviceName/$serviceName
fi
cp -f target/$serviceName.jar ./
if [ -n "$1" ]; then
    case $1 in
        "start")
            echo "*** Starting $serviceName ***"
            nohup java -server -Xmx512m -jar $serviceName.jar >/dev/null 2>&1 &
            tailf /data/logs/paascloud/$serviceName/$serviceName|sed '/Started PaasCloudZipkinApplication in/Q'
            echo "tailf /data/logs/paascloud/$serviceName/$serviceName"
            echo "*** Started $serviceName ***"
            exit 0
        ;;
        "stop")
            curl -X POST http://admin:admin@localhost:$servicePort/actuator/shutdown
			echo
			for i in `seq 1 10`
            do
                PID=`ps -ef|grep ${serviceName}|grep -v grep|awk '{print $2}'`
                if [ -z "${PID}" ]; then
                    echo "${serviceName} shutdown gracefully."
                    SHUTDOWN=1
                    break
                else
                    echo "waiting ${serviceName} shutdown ${i}"
                    sleep 1
                fi
            done

            if [ -z "${SHUTDOWN}" ]; then
                echo "app may not shutdown gracefully, kill immediately."
                for i in `seq 11 30`
                do
                    PID=`ps -ef|grep ${serviceName}|grep -v grep|awk '{print $2}'`
                    if [ -z "${PID}" ]; then
                        break;
                    else
                        kill -9 ${PID}
                        echo "waiting ${serviceName} shutdown: ${i}"
                        sleep 1
                    fi
                done
                echo "${serviceName} shutdown succefully."
            fi

            exit 0
        ;;
        *) echo "start|stop action is required."
    esac
else
    echo "action is required."
fi