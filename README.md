# [netdata](https://github.com/netdata/netdata) LSI MegaRAID `chart.d` plugin

This plugin lets you monitor LSI MegaRAID temperatures from other hosts. You need to install `storcli` on the
monitored host.

## Install

```sh
git clone https://github.com/agross/netdata-lsimr.git
ln -s "$PWD/netdata-lsimr/lsimr.chart.sh" /usr/libexec/netdata/charts.d/lsimr.chart.sh
```

## Configure

1. Create `/etc/netdata/charts.d/lsimr.conf`
1. Edit:

   ```conf
   # the data collection frequency
   # if unset, will inherit the netdata update frequency
   lsimr_update_every=60

   # the charts priority on the dashboard
   lsimi_priority=150000

   lsimr_ssh_identity_file=/path/to/private/key/for/somebody
   lsimr_ssh_host=somebody@host

   ```

1. Restart netdata
