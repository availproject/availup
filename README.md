## Availup
To run an Avail light client, simply run the following command:
```bash
curl -sL1 avail.sh | bash
```
or, with `wget`:
```bash
wget --https-only --secure-protocol=TLSv1_2 --quiet -O - avail.sh | bash
```
You can pass additional flags to the script like:
```bash
curl -sL1 avail.sh | bash -s -- --network goldberg
```

Currently available flags are:
* `network`: can be one of the following: [`goldberg`, `local`]
* `config`: path to the configuration file, availup will generate a config if this flag is not specified
  * This flag is always required when running a local testnet
* `identity`: path to the identity file, availup will generate a config if this flag is not specified
  * It is important to keep your identity file safe!
* `app_id`: application ID to run the light client (defaults to `0`)
  * It is recommended to not change this flag unless you require the app-specific mode.
* `upgrade`: takes `y` and `yes` as valid arguments, indicating that the `avail-light` binary should be upgraded
  * Using this flag wipes your existing data and config, use with caution!

You can use a custom config by passing it to `availup` as a flag:
```bash
# create the config:
touch ~/config.yml
# edit the config:
nano ~/config.yml
# and rerunning the script:
curl -sL1 avail.sh | bash -s -- --config ~/config.yml
```

> ⚠️ It is not recommended to modify the default config stored in `~/.avail/config/config.yml` as that gets wiped on
> each run.

Alternatively, you can pass a specific application ID with `availup`:
```bash
rm ~/.avail/goldberg/config.yml
# and rerunning the script with flags:
curl -sL1 avail.sh | bash -s -- --app_id 1
```

> ℹ️ Adding an app ID disables the LC mode and runs your client in an app-specific mode, this might not be your
> intention.

To upgrade the light client to the latest supported version, you can simply pass the `--upgrade` flag like:
```bash
curl -sL1 avail.sh | bash -s -- --upgrade y
```

> ℹ️ Upgrading the LC only works if the binary was installed with the latest `availup` script or cargo.
