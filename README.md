## Availup
To run an Avail light client, simply run the following command:
```bash
curl -sL1 avail.sh | sh
```
or, with `wget`:
```bash
wget --https-only --secure-protocol=TLSv1_2 --quiet -O - avail.sh | sh
```
You can pass additional flags to the script like:
```bash
curl -sL1 avail.sh | sh -s -- --network goldberg
```
Currently available flags are:
* `network`: can be one of the following: [`kate`, `goldberg`, `local`]
* `config`: path to the configuration file, availup will generate a config if this flag is not specified
* `app_id`: application ID to run the light client (defaults to `0`)

Flags are defined once for each network in the config file. If a default configuration already exists, the flags are
ignored unless the configuration for that network does not exist.

You can modify the existing default config by running and rerun `availup` to use the new config:
```bash
nano ~/.avail/goldberg/config.yml
# and rerunning the script:
curl -sL1 avail.sh | sh
```
Alternatively, you can delete the existing config and generate a new config with `availup`:
```bash
rm ~/.avail/goldberg/config.yml
# and rerunning the script with flags:
curl -sL1 avail.sh | sh -s -- --app_id 1
```

To upgrade the light client to a latest version, you need to delete the binary:
```bash
sudo rm /usr/local/bin/avail-light
# in some cases, the config can be persisted, if older config is incompatible, then delete it first:
rm ~/.avail/goldberg/config.yml
# then, rerun the script:
curl -sL1 avail.sh | sh
```
