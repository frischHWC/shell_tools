mkdir -p /home/myuser/
cat /etc/hosts | grep -v "localhost" > /home/myuser/hosts
chmod 755 /home/myuser/hosts