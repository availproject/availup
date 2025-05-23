## Availup
To run an Avail light client, simply run the following command:
```bash
curl -sL1 avail.sh | bash
```
or, with `wget`:
```bash
wget --secure-protocol=TLSv1_2 -q -O - avail.sh | bash
```
You can pass additional flags to the script like:
```bash
curl -sL1 avail.sh | bash -s -- --network turing
```

Currently available flags are:
* `network`: can be one of the following: [`mainnet`, `turing`, `local`]
* `config`: path to the configuration file, availup will generate a config if this flag is not specified
  * This flag is always required when running a local testnet
* `config_url`: URL to a valid YAML configuration file, availup will download the config if this flag is specified
  * If the configuration is invalid, the script will exit
  * This flag will only work with mainnet configurations
* `identity`: path to the identity file, availup will generate a config if this flag is not specified
  * It is important to keep your identity file safe!
* `app_id`: application ID to run the light client (defaults to `0`)
  * It is recommended to not change this flag unless you require the app-specific mode.
* `upgrade`: takes `y` and `yes` as valid arguments, indicating that the `avail-light` binary should be upgraded
  * Using this flag wipes your existing data and config, use with caution! This flag does not guarantee that the
    binary will be upgraded.
* `force_wsl`: takes `y` and `yes` as valid arguments, the script exits on WSL systems by default. This flag can
  removed in the future.
* `tracking_service`: takes `y` and `yes` as valid arguments, enabling `avail-light` tracking on a provided server
* `tracking_service_address`: URL to the tracker server, i.e. `http://127.0.0.1:8989`
* `operator_address`: Address of the Light Client operator; this field is sent to the tracking service

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

If you have a seed phrase that you'd like to use instead of the generated one, you can modify
`~/.avail/identity/identity.toml`, alternatively, you can pass it as a flag:
```bash
# edit default identity
nano ~/.avail/identity/identity.toml
# the script picks up the new identity automatically:
curl -sL1 avail.sh | bash
# create a new identity
touch ~/identity.toml
nano ~/identity.toml
# the script uses the identity at the path
curl -sL1 avail.sh | bash -s -- --identity ~/identity.toml
```

> ℹ️ The script persists your identity file between runs. Deleting the file will cause a new one to be generated on
> the next run.

Alternatively, you can pass a specific application ID with `availup`:
```bash
rm ~/.avail/turing/config.yml
# and rerunning the script with flags:
curl -sL1 avail.sh | bash -s -- --app_id 1
```

> ℹ️ Adding an app ID disables the LC mode and runs your client in an app-specific mode, this might not be your
> intention.

In availup, binary upgrades are enabled by default to ensure you always have the latest supported version. In order to skip default 
upgrades you can simply pass the `--upgrade` flag like:
```bash
curl -sL1 avail.sh | bash -s -- --upgrade n
```

> ℹ️ Upgrading the LC only works if the binary was installed with the latest `availup` script or cargo. If default updates are skipped, everytime the user will be prompted for a permission to upgrade once a new release is made available.

To run the light client on WSL systems, use the `--force_wsl` flag like:
```bash
curl -sL1 avail.sh | bash -s -- --force_wsl y
```

> ℹ️ Running this flag on any other system does nothing.

To load a configuration from a URL, use the `--config_url` flag like:
```bash
curl -sL1 avail.sh | bash -s -- --config_url https://raw.githubusercontent.com/availproject/availup/main/configs/sophon.yml
```

> ℹ️ The configuration file must be a valid YAML file, otherwise the script will exit.
