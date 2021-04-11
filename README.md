# Fundaria
Live examples:

https://fundaria.com/test/sc/deploy-bsc.html

https://fundaria.com/test/sc/complex-testing-bsc.html

https://fundaria.com/test/sc/complex-testing-bsc.html?pool=1



Instalation:

apt install apache2

apt install php

apt install docker.io

docker pull ethereum/solc:0.8.3

groupadd docker

chmod 666 /var/run/docker.sock

service apache2 start


Using:

Deploy contracts:

deploy-bsc.html

Testing:

complex-testing-bsc.html (Fundaria pool)

complex-testing-bsc.html?pool=1 (a startup pool)


/logs:

Every log is the sequence of actions, described on the top of log file.
