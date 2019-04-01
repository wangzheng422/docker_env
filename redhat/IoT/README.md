# IoT

 ```bash
 basename -a /sys/class/net/* | grep en | awk '{system("ethtool " $1)}'
```