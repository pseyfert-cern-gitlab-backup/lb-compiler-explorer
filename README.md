# use case

as a prerequisit, the host machine should have cvmfs installed (including the sft.cern.ch, lhcb.cern.ch, lhcbdev.cern.ch repositories). A possible lauch pattern would be

```sh
echo "ensure the cvmfs repositories are populated before they are mounted to the container"
ls /cvmfs/lhcb.cern.ch/lib > /dev/null
ls /cvmfs/lhcbdev.cern.ch/nightlies > /dev/null
ls /cvmfs/sft.cern.ch > /dev/null

docker pull gitlab-registry.cern.ch/pseyfert/lb-compiler-explorer:latest
docker run -it --rm  -v/tmp:/localstore -v/cvmfs/lhcb.cern.ch:/cvmfs/lhcb.cern.ch -v/cvmfs/lhcbdev.cern.ch:/cvmfs/lhcbdev.cern.ch -v/cvmfs/sft.cern.ch:/cvmfs/sft.cern.ch -p 80:10240 gitlab-registry.cern.ch/pseyfert/lb-compiler-explorer:latest
```

This exposes the compiler explorer instance on port 80 of the host.

As exchange folder for short links, in the container `/localstore` is used.
This might be configured through your docker launch-thing (openstack) or (as
above) be a mounted volume from the host.
