#!/usr/bin/env bash


PREFIX="-------- "
echo $PREFIX"Bootstraping hadoop..."

SSH_NEW_PORT=12022

if [ "$SSH_PORT" !=  "" ]; then
  SSH_NEW_PORT=$SSH_PORT
fi

echo $PREFIX"Updating ssh port to "$SSH_NEW_PORT
sed -i "s|Port 22|Port $SSH_NEW_PORT|g" /etc/ssh/sshd_config

#cat /etc/ssh/sshd_config
CONFIG_DIR=/opt/hadoop/etc/hadoop
export HADOOP_SSH_OPTS="-p $SSH_NEW_PORT"

echo $PREFIX"Starting ssh..."
service ssh start;

# DEFAULTS
RESOURCEMANAGER_ADDRESS=0.0.0.0
RESOURCEMANAGER_WEBPORT=8088
RESOURCEMANAGER_SCHEDULERPORT=8030
RESOURCEMANAGER_TRACKERPORT=8031
RESOURCEMANAGER_PORT=8032
RESOURCEMANAGER_ADMINPORT=8033

NAMENODE_ADDRESS=0.0.0.0
NAMENODE_PORT=9000
NAMENODE_WEBPORT=50070

ALB_ADDR=0.0.0.0

YARN_MIN_MB=128
YARN_MAX_MB=2048
YARN_MIN_VCORE=1
YARN_MAX_VCORE=2
YARN_MEMORY=4096
YARN_VCORES=4

DEFAULT_DATA_DIR=/data/hdfs/

if [ "$YARN_MIN_ALLOC" != "" ]; then
  YARN_MIN_MB = $YARN_MIN_ALLOC
fi

if [ "$YARN_MAX_ALLOC" != "" ]; then
  YARN_MAX_MB = $YARN_MAX_ALLOC
fi

if [ "$YARN_MIN_VCORES_NUM" != "" ]; then
  YARN_MIN_VCORE = $YARN_MIN_VCORES_NUM
fi

if [ "$YARN_MAX_VCORES_NUM" != "" ]; then
  YARN_MAX_VCORE = $YARN_MAX_VCORES_NUM
fi

if [ "$YARN_RESOURCE_MEM" != "" ]; then
  YARN_MEMORY = $YARN_RESOURCE_MEM
fi

if [ "$YARN_CORES" != "" ]; then
  YARN_VCORES = $YARN_CORES
fi

if [ "$DATA_DIR" != "" ]; then
  DEFAULT_DATA_DIR=$DATA_DIR
fi

# replacing the ports
if [ "$SERVER_ROLE" = "dn" ]; then
  # DATA NODE
  echo $PREFIX"Datanode configuration"

  cp /opt/hadoop/etc/hadoop/data-node-core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
  cp /opt/hadoop/etc/hadoop/data-node-hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
  cp /opt/hadoop/etc/hadoop/data-node-yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml
  cp /opt/hadoop/etc/hadoop/data-node-mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml
else
  # NAME NODE
  echo $PREFIX"Namenode configuration"

  cp /opt/hadoop/etc/hadoop/name-node-core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
  cp /opt/hadoop/etc/hadoop/name-node-hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
  cp /opt/hadoop/etc/hadoop/name-node-yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml
  cp /opt/hadoop/etc/hadoop/name-node-mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml

  cp /opt/hive/conf/hive-node-hive-site.xml /opt/hive/conf/hive-site.xml
fi

if [ "$NAME_NODE_ADDR" != "" ]; then
  RESOURCEMANAGER_ADDRESS=$NAME_NODE_ADDR
  NAMENODE_ADDRESS=$NAME_NODE_ADDR
fi

if [ "$NAME_NODE_PORT" != "" ]; then
  NAMENODE_PORT=$NAME_NODE_PORT
fi

echo $PREFIX"Setting up hadoop configuration..."
sed -i "s|{{resourcemanager.address}}|$RESOURCEMANAGER_ADDRESS|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.webport}}|$RESOURCEMANAGER_WEBPORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.schedulerport}}|$RESOURCEMANAGER_SCHEDULERPORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.trackerport}}|$RESOURCEMANAGER_TRACKERPORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.port}}|$RESOURCEMANAGER_PORT|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{resourcemanager.adminport}}|$RESOURCEMANAGER_ADMINPORT|g" $CONFIG_DIR/yarn-site.xml

sed -i "s|{{yarn.min-mb}}|$YARN_MIN_MB|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.max-mb}}|$YARN_MAX_MB|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.min-vcore}}|$YARN_MIN_VCORE|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.max-vcore}}|$YARN_MAX_VCORE|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.memory}}|$YARN_MEMORY|g" $CONFIG_DIR/yarn-site.xml
sed -i "s|{{yarn.vcores}}|$YARN_VCORES|g" $CONFIG_DIR/yarn-site.xml

sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/core-site.xml
sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/mapred-site.xml
sed -i "s|{{node.name.ip}}|$NAMENODE_ADDRESS|g" $CONFIG_DIR/yarn-site.xml

sed -i "s|{{node.name.port}}|$NAMENODE_PORT|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{node.name.port}}|$NAMENODE_PORT|g" $CONFIG_DIR/core-site.xml

sed -i "s|{{node.name.webport}}|$NAMENODE_WEBPORT|g" $CONFIG_DIR/hdfs-site.xml
sed -i "s|{{hdfs.data}}|$DEFAULT_DATA_DIR|g" $CONFIG_DIR/hdfs-site.xml

sed -i "s|{{ALB_ADDR}}|$ALB_ADDR|g" /opt/hive/conf/hive-site.xml
sed -i "s|{{NAME_NODE_ADDR}}|$NAMENODE_ADDRESS|g" /opt/hive/conf/hive-site.xml

# debuging configuration
if [ "$DEBUG" != "" ]; then
  cat $CONFIG_DIR/yarn-site.xml
fi

# Setup ssh for slaves
if [ "$NODE_IPS" != "" ]; then
  echo $PREFIX"Got nodes address as "$NODE_IPS

  nodes=""
  if echo $NODE_IPS | grep -q ","
  then
    #Multiple nodes
    nodes=$(echo $NODE_IPS | tr "," "\n")
  else
    #Single node
    nodes=$NODE_IPS
  fi
  echo "" > $CONFIG_DIR/slaves
  for addr in $nodes
  do
    echo $PREFIX"Setup for node "$addr
    echo $addr >> $CONFIG_DIR/slaves
    echo "Host "$addr >> ~/.ssh/config
    echo "  StrictHostKeyChecking no" >> ~/.ssh/config
    echo "" >> ~/.ssh/config

    # echo $PREFIX"Will try to connect to node "$addr
    # ssh -v $addr $HADOOP_SSH_OPTS exit
  done
fi

if [ "$SERVER_ROLE" = "nn" ]; then
    echo $PREFIX"Will start as namenode"

    if [ "$FORMAT_NAMENODE" = "true" ]; then

        VERSION_LOCATION=$DEFAULT_DATA_DIR/current/VERSION
        echo $PREFIX" Data dir will be verified by "$VERSION_LOCATION
        if [ ! -f $VERSION_LOCATION ]; then
          echo $PREFIX"Will format namenode"
          /opt/hadoop/bin/hdfs namenode -format -nonInteractive
        else
          echo $PREFIX"Namenode is already formatted"
        fi
    fi

    echo $PREFIX"Will start namenode in the background"
    # /opt/hadoop/bin/hdfs namenode &

    sleep 5

    start-dfs.sh
    mr-jobhistory-daemon.sh start historyserver

    sleep 60

    hdfs dfs -mkdir -p /usr/hive/warehouse  
    hdfs dfs -mkdir -p /usr/hive/tmp  
    hdfs dfs -mkdir -p /usr/hive/log  
    hdfs dfs -chmod +w /usr/hive/warehouse  
    hdfs dfs -chmod +w /usr/hive/tmp  
    hdfs dfs -chmod +w /usr/hive/log  
    hdfs dfs -chmod g+w /usr/hive/warehouse  
    hdfs dfs -chmod g+w /usr/hive/tmp  
    hdfs dfs -chmod g+w /usr/hive/log  


    echo $PREFIX"Starting supervisor..."
    service supervisor start;

    # Needs additional configuration !!!!
    # echo $PREFIX"Will start quorum journal in the background"
    # /opt/hadoop/bin/hdfs start journalnode &
    #
    # sleep 5

    if [ "$START_YARN" != "" ]; then

      echo $PREFIX"Will start YARN services..."
      echo $PREFIX"Starting resource manager..."
      # /opt/hadoop/sbin/yarn-daemon.sh --config $CONFIG_DIR start resourcemanager

      start-yarn.sh
      yarn-daemon.sh start proxyserver

    fi

    if [ "$TEST" = "true" ]; then
      echo $PREFIX"Will run wordcount test..."
      /run-wordcount.sh
    fi
else
    echo $PREFIX"Will start as data node"
    # /opt/hadoop/bin/hdfs datanode &

    # sleep 5

    if [ "$START_YARN" != "" ]; then

      echo $PREFIX"Will start YARN services..."

      echo $PREFIX"Starting node manager..."
      # /opt/hadoop/sbin/yarn-daemons.sh --config $CONFIG_DIR start nodemanager
    fi
fi


echo $PREFIX"Tailing logs..."
mkdir -p /opt/hadoop/logs/
echo "first line" > /opt/hadoop/logs/first
tail -f /opt/hadoop/logs/* 
wait || :
