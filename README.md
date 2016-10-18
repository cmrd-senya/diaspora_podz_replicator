# Diaspora* Podz Replicator

This gem contains tools to make [diaspora*](https://github.com/diaspora/diaspora) deployment easy. By including this gem you'll make it available to deploy diaspora pods by issuing rake tasks within your project directory and thus make diaspora installation (or a few) available to test your software against it. Also can be used to test diaspora itself. Deployment process is backed by [diaspora-replica](https://github.com/joebew42/diaspora-replica).

The gem provides a CLI tool called `preplica`.

## Requirements

- LXC
- Vagrant -- this one isn't provided as a rubygem anymore, so one must install it explicitly
- About 5 Gb free space

On Ubuntu 16.04 LXC can be installed by
```
sudo apt-get install lxc cgroup-lite
```

Vagrant must be installed from the upstream package ([download page](https://www.vagrantup.com/downloads.html)), the version from repositories is buggy.

## Prepare environment

#### 1. Create a config file in `config/replica.yml`

[Here](https://raw.githubusercontent.com/cmrd-senya/diaspora/fb4d972c49d33e4f9e8ec114557006b76e707fb8/config/replica.yml.example) is an example of the file.

And adjust `config/replica.yml` with the settings you need (pod count, software revisions, etc). If you work outside the diaspora* source directory, you must add the `diaspora_root` configuration parameter in your configuration file pointing to diaspora source folder.

Configuration address may be tuned with the `--config` command line switch.

#### 2. Add pods hostnames to `/etc/hosts`
```
...
192.168.11.6    pod1.diaspora.local
192.168.11.8    pod2.diaspora.local
192.168.11.10    pod3.diaspora.local
192.168.11.12    pod4.diaspora.local
...
```

By default pods are addressed using domain names which should be accessible from your host. IP addresses are hardcoded in Vagrant file of my customized replica version. Domain binding is probably not a necessary step, but I never tested it without, so that may require some more work.

#### 3. Vagrant must be allowed to execute containers without asking password (must be run without `sudo`)

```
vagrant lxc sudoers
```

#### 4. I also had to issue this command on Ubuntu 16.04. Not sure if it's really mandatory or just a requirement due to some my local misconfiguration. Ubuntu 14.04 never required this.

```
sudo mount cgroup /sys/fs/cgroup//devices -t cgroup -o rw,relatime,devices,release_agent=/run/cgmanager/agents/cgm-release-agent.devices
```

## How to use it

#### Deploy pods software
Use
```
bundle exec preplica deploy
```

It'll create a proper number of LXC containers and populate them with diaspora software. Might take a while, especially for the very first time.

#### Launch pods software
 If the deployment has been finished successfully, you may launch the pods' software by
```
bundle exec preplica launch
```

Now you may access the pods by their domains `podN.diaspora.local`.

#### Stop pods software

```
bundle exec preplica stop
```

#### Halt the VMs

```
bundle exec preplica halt
```

#### Destroy the VMs

If you want to clean up and remove these virtual machines, run
```
bundle exec preplica clean
```

## Logs

Log files are written to `<diaspora root>/log` directory with `replica.<timestamp>.log` name. Might be changed with `--logdir` command line option.
