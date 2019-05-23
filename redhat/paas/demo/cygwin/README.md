# cygwin


```
cygrunsrv --install supervisord --user 'wzh' --passwd '' --path /home/wzh/virtualenv/supervisor/bin/python  --args "/home/wzh/virtualenv/supervisor/bin/supervisord -n -c /home/wzh/virtualenv/supervisor/etc/supervisor/supervisord.ini"

supervisorctl -c ~/virtualenv/supervisor/etc/supervisor/supervisord.ini status

mkdir /home/SYSTEM
cp -r /home/wzh/.ssh /home/SYSTEM
chown -R SYSTEM: /home/SYSTEM

```