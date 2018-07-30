#!/bin/sh

# 等待依赖容器
function nc_test()
{
_hostname=$1
_port=$2
nc -z -w 3 $_hostname $_port

if [ $? != 0 ];then
  echo $1:$2 not ready !
  return 1
fi

return 0
}


for i in {1..1200}
do
  sleep 1
  nc_test nginx 80 || continue
  nc_test qpid-broker 5670 || continue
  nc_test redis 6379 || continue
  nc_test mysql 3306 || continue
  nc_test mongodb 27017 || continue              

  nc_test uom-sys-license 6221 || continue

  nc_test levam-auth 6211 || continue
  
  nc_test uom-device-manager 6222 || continue
  nc_test kernel.ser-biz-ondemand 6009 || continue
  
  nc_test uom-storage-manager 6223 || continue
  nc_test uom-update-manager 6224 || continue
  nc_test kernel.ser-biz-audio 6003 || nc_test kernel.ser-biz-audio-jj 6003 || nc_test kernel.ser-biz-audio-all 6003 || continue
  nc_test kernel.ser-biz-record-manager 20896 || continue              

  break
done
  
sleep 2

myself=$(cd `dirname $0`; pwd)
cd $myself

# JVM_PAR_MEM为jvm内存参数,JVM_PAR_Other为jvm其他参数,通过环境变量传入容器的启动脚本
if [ x"" = x"$JVM_PAR_MEM" ];then
  JVM_PAR_MEM="-Xmx512m -Xmn192m -XX:MaxPermSize=256m -XX:MaxDirectMemorySize=128m"
fi
if [ x"" = x"$JVM_PAR_Other" ];then
  JVM_PAR_Other="-Xloggc:logs/gc.log -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:-TraceClassUnloading -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/levam/heapdump.hprof"
fi

java -Dfile.encoding=UTF-8 \
$JVM_PAR_MEM \
$JVM_PAR_Other \
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -cp .:./*:./lib/* com.goldmsg.GoldmsgApplication file:./config/application.properties &