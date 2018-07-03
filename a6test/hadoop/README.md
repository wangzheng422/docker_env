![Hadoop](Hadoop_logo.svg)
## How to use this image

This Hadoop is supposed to be used as a cluster.  
It was tested using host network mode and directly using the nodes IPs.

### Environment variables
There are a series of environment variables that simplify the container behaviour and configuration

#### Common
Bellow are the shared environment variables that should be set using the same value in all nodes:

*customizable* `SSH_PORT=2222` Set the port in which the container will be accessible via ssh  
*customizable* `START_YARN=true` If not set the cluster will only be set as a HDFS cluster  
`NODE_IPS=10.0.0.1,10.0.0.2` set the IPs of all the datanodes  
*customizable* `NAME_NODE_ADDR=10.0.0.3` set the IP of the namenode server. Currently also used as the resource manager IP  
*customizable* `NAME_NODE_PORT=9000` sets the port used by the nodes to communicate with the name node  

#### Namenode
*customizable* `FORMAT_NAMENODE=true` will format the namenode everytime the node is run  
*customizable* `DATA_DIR=/data/hdfs` the directory format as HDFS
`SERVER_ROLE=nn` Set the node as the namenode and the resource manager  
*customizable* `TEST=true` will run a run-wordcount.sh task after the namenode is setup  

#### Datanodes
`SERVER_ROLE=dn` Set the node as the datanode  


#### YARN configuration env
This are also set as common. The numbers below are the default values used if those are not set.

*customizable* `YARN_MIN_ALLOC=128` Sets the minimum memory allocation for each task in MB  
*customizable* `YARN_MAX_ALLOC=2048` Sets the maximum memory allocation for each task in MB
*customizable* `YARN_MIN_VCORES_NUM=1`  Sets the minumum number of virtual cores used by each task  
*customizable* `YARN_MAX_VCORES_NUM=2`  Sets the maximmum number of virtual cores used by each task  
*customizable* `YARN_RESOURCE_MEM=4096`  Sets the total amount of memory used by the resource node  
*customizable* `YARN_CORES=4`  Sets the total number of cores used by the resource node  


### Application template
Here is an example of an App deployed to a three node cluster. The usage scenario is described below:  

Namenode/Resource manager - `10.171.129.10`  
Datanode one - `10.171.128.37`  
Datanode two - `10.172.230.213`

Build this image and replace on every `image` section

```
version: "2"

services:
  namenode:
    image: hadoop
    network_mode: HOST
    size: S
    environment:
      SSH_PORT: 2222
      NODE_IPS: "10.171.128.37,10.172.230.213"
      NAME_NODE_ADDR: 10.171.129.10
      NAME_NODE_PORT: 9000
      SERVER_ROLE: "nn"
      FORMAT_NAMENODE: "true"
      TEST: "true"
      START_YARN: "true"
    ports:
      - "8088/http"
      - "50070"
      - "9000"
    labels:
      - "constraint:node==ip:10.171.129.10"
  hadoop-node1:
    image: hadoop
    network_mode: HOST
    size: XS
    environment:
      SSH_PORT: 2222
      NODE_IPS: "10.171.128.37,10.172.230.213"
      NAME_NODE_ADDR: 10.171.129.10
      NAME_NODE_PORT: 9000
      SERVER_ROLE: "dn"
      START_YARN: "true"
    labels:
      - "constraint:node==ip:10.171.128.37"
  hadoop-node2:
    image: hadoop
    network_mode: HOST
    size: XS
    environment:
      SSH_PORT: 2222
      NODE_IPS: "10.171.128.37,10.172.230.213"
      NAME_NODE_ADDR: 10.171.129.10
      NAME_NODE_PORT: 9000
      SERVER_ROLE: "dn"
      START_YARN: "true"
    labels:
      - "constraint:node==ip:10.172.230.213"
```


### Ports
These are the default ports used by the namenode/resource manager node. Currently are not customizable but should be very easy to add support.

*Resource manager WebUI* - **8088**  
*Namenode WebUI* - **50070**
*Resource manager port* - **8032**  
*Resource manager admin interface* - **8033**

Please consult hadoops documentation for more information.
