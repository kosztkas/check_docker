check_docker
=========
Docker checking script for nagios.
Check if the container with the given id (or name) is running or the memory and CPU usage is between the given limits.

#### Samples

- Helper
```sh
sudo ./check_container.sh -h 
```
- Check if container is running
```sh
sudo ./check_container.sh _container_id_ -T running 
```
- Check container memory usage
```sh
sudo ./check_container.sh _container_id_ -W 70 -C 90 -T memused
```


TODO:
-----
- [ ] add disk I/O checking
- [ ] add net I/O checking
- [ ] define nrpe usage
