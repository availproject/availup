#!/usr/bin/env bash
echo "🆙 Starting Availup..."
while [ $# -gt 0 ]; do
    if [[ $1 = "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

# enable default upgrades by default
upgrade="${upgrade:-y}"

# enable tracking service
tracking_service="${tracking_service:-n}"
tracking_service_address="${tracking_service_address:-}"

# generate folders if missing
if [ ! -d "$HOME/.avail" ]; then
    mkdir $HOME/.avail
fi
if [ ! -d "$HOME/.avail/identity" ]; then
    mkdir $HOME/.avail/identity
fi
# check if bash is current terminal shell, else check for zsh
if [ -z "$BASH_VERSION" ]; then
    if [ -z "$ZSH_VERSION" ]; then
        echo "🚫 Unable to locate a shell. Availup might not work as intended!"
    else
        CURRENT_TERM="zsh"
    fi
else
    CURRENT_TERM="bash"
fi
if [ "$CURRENT_TERM" = "bash" -a -f "$HOME/.bashrc" ]; then
    PROFILE="$HOME/.bashrc"
elif [ "$CURRENT_TERM" = "bash" -a -f "$HOME/.bash_profile" ]; then
    PROFILE="$HOME/.bash_profile"
elif [ "$CURRENT_TERM" = "bash" -a -f "$HOME/.zshrc" ]; then
    PROFILE="$HOME/.zshrc"
elif [ "$CURRENT_TERM" = "bash" -a -f "$HOME/.zsh_profile" ]; then
    PROFILE="$HOME/.zsh_profile"
elif [ "$CURRENT_TERM" = "zsh" -a -f "$HOME/.zshrc" ]; then
    PROFILE="$HOME/.zshrc"
elif [ "$CURRENT_TERM" = "zsh" -a -f "$HOME/.zsh_profile" ]; then
    PROFILE="$HOME/.zsh_profile"
elif [ "$CURRENT_TERM" = "bash" ]; then
    PROFILE="$HOME/.bashrc"
    touch $HOME/.bashrc
elif [ "$CURRENT_TERM" = "zsh" ]; then
    PROFILE="$HOME/.zshrc"
    touch $HOME/.zshrc
else
    echo "🫣 Unable to locate a compatible shell or rc file, using POSIX default, availup might not work as intended!"
    PROFILE="/etc/profile"
fi

if [ -z "$network" ]; then
    echo "🛜 No network selected. Defaulting to mainnet."
    NETWORK="mainnet"
else
    NETWORK="$network"
fi

UPGRADE=0
if [ "$NETWORK" = "mainnet" ]; then
    echo "📌 Mainnet selected."
elif [ "$NETWORK" = "turing" ]; then
    echo "📌 Turing testnet selected."
elif [ "$NETWORK" = "local" ]; then
    echo "📌 Local testnet selected."
fi

TURING_CONFIG_PARAMS="bootstraps=['/dns/bootnode.1.lightclient.turing.avail.so/tcp/37000/p2p/12D3KooWBkLsNGaD3SpMaRWtAmWVuiZg1afdNSPbtJ8M8r9ArGRT']\nfull_node_ws=['wss://turing-rpc.avail.so/ws','wss://avail-turing.public.blastapi.io','wss://turing-testnet.avail-rpc.com']\nconfidence=80.0\navail_path='$HOME/.avail/$NETWORK/data'\nkad_record_ttl=43200\not_collector_endpoint='http://otel.lightclient.turing.avail.so:4317'\ngenesis_hash='d3d2f3a3495dc597434a99d7d449ebad6616db45e4e4f178f31cc6fa14378b70'\n"
MAINNET_CONFIG_PARAMS="bootstraps=['/dns/bootnode.1.lightclient.mainnet.avail.so/tcp/37000/p2p/12D3KooW9x9qnoXhkHAjdNFu92kMvBRSiFBMAoC5NnifgzXjsuiM']\nfull_node_ws=['wss://mainnet-rpc.avail.so/ws','wss://mainnet.avail-rpc.com','wss://avail-mainnet.public.blastapi.io']\nconfidence=80.0\navail_path='$HOME/.avail/$NETWORK/data'\nkad_record_ttl=43200\ngenesis_hash='b91746b45e0346cc2f815a520b9c6cb4d5c0902af848db0a80f85932d2e8276a'\not_collector_endpoint='http://otel.lightclient.mainnet.avail.so:4317'\n"
AVAIL_BIN=$HOME/.avail/$NETWORK/bin/avail-light
if [ ! -d "$HOME/.avail/$NETWORK" ]; then
    mkdir $HOME/.avail/$NETWORK
fi
if [ ! -d "$HOME/.avail/$NETWORK/bin" ]; then
    mkdir $HOME/.avail/$NETWORK/bin
fi
if [ ! -d "$HOME/.avail/$NETWORK/data" ]; then
    mkdir $HOME/.avail/$NETWORK/data
fi
if [ ! -d "$HOME/.avail/$NETWORK/config" ]; then
    mkdir $HOME/.avail/$NETWORK/config
fi

readonly MAINNET_VERSION="avail-light-client-v1.12.10"
readonly TURING_VERSION="avail-light-client-v1.12.10"
readonly LOCAL_VERSION="avail-light-client-v1.12.10"

if [ "$NETWORK" = "mainnet" ]; then
    VERSION=$MAINNET_VERSION
    if [ -z "$config" ]; then
        CONFIG="$HOME/.avail/$NETWORK/config/config.yml"
        if [ -f "$CONFIG" ]; then
            echo "🗑️ Wiping old config file at $CONFIG."
            rm $CONFIG
        else
            echo "🤷 No configuration file set. This will be automatically generated at startup."
        fi
        touch $CONFIG
        if [ ! -z "$config_url" ]; then
            echo "📥 Downloading configuration file from $config_url..."
            if command -v curl >/dev/null 2>&1; then
                curl -sL $config_url >>$CONFIG
                echo -e "\navail_path='$HOME/.avail/$NETWORK/data'\n" >>$CONFIG
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- $config_url >>$CONFIG
                echo -e "\navail_path='$HOME/.avail/$NETWORK/data'\n" >>$CONFIG
            else
                echo "🚫 Neither curl nor wget are available. Please install one of these and try again."
                exit 1
            fi
        else
            echo -e $MAINNET_CONFIG_PARAMS >>$CONFIG
        fi
    else
        CONFIG="$config"
    fi
elif [ "$NETWORK" = "turing" ]; then
    VERSION=$TURING_VERSION
    if [ -z "$config" ]; then
        CONFIG="$HOME/.avail/$NETWORK/config/config.yml"
        if [ -f "$CONFIG" ]; then
            echo "🗑️  Wiping old config file at $CONFIG."
            rm $CONFIG
        else
            echo "🤷 No configuration file set. This will be automatically generated at startup."
        fi
        touch $CONFIG
        echo -e $TURING_CONFIG_PARAMS >>$CONFIG
    else
        CONFIG="$config"
    fi
elif [ "$NETWORK" = "local" ]; then
    echo "📌 Local testnet selected."
    VERSION=$LOCAL_VERSION
    if [ -z "$config" ]; then
        echo "🚫 No configuration file was provided for local testnet, exiting."
        exit 1
    fi
else
    echo "🚫 Invalid network selected. Select one of the following: mainnet, turing, local."
    exit 1
fi
if [ -z "$app_id" ]; then
    echo "📲 No app ID specified. Defaulting to light client mode."
else
    APPID="$app_id"
fi
if [ -z "$identity" ]; then
    IDENTITY=$HOME/.avail/identity/identity.toml
    if [ -f "$IDENTITY" ]; then
        echo "🔑 Identity found at $IDENTITY."
    else
        echo "🤷 No identity set. This will be automatically generated at startup."
    fi
else
    IDENTITY="$identity"
fi
# handle WSL systems
if uname -r | grep -qEi "(Microsoft|WSL)"; then
    # force remove IO lock
    if [ -d "$HOME/.avail/$NETWORK/data" ]; then
        rm -rf $HOME/.avail/$NETWORK/data
        mkdir $HOME/.avail/$NETWORK/data
    fi
    if [ "$force_wsl" != 'y' -a "$force_wsl" != 'yes' ]; then
        echo "👀 WSL detected. This script is not fully compatible with WSL. Please download the Windows runner instead by clicking this link: https://github.com/availproject/avail-light/releases/download/$VERSION/avail-light-windows-runner.zip Alternatively, rerun the command with --force_wsl y"
        exit 1
    else
        echo "👀 WSL detected. The binary is not fully compatible with WSL but forcing the run anyway."
    fi
fi

# check if the default upgrade option is enabled
# if enabled, proceed directly to upgrading the binary
# if it’s disabled, verify the current version, ask for permission and upgrade if it’s not the latest
if [ "$upgrade" = "n" ] || [ "$upgrade" = "N" ]; then
    echo "🔄 Checking for updates..."
    if [ -f $AVAIL_BIN ]; then
        CURRENT_VERSION="$($HOME/.avail/$NETWORK/bin/avail-light --version | awk '{print $1"-v"$2}')"
        if [ "$CURRENT_VERSION" != "$VERSION" ]; then
            echo "⬆️  Avail binary is out of date. Your current version is $CURRENT_VERSION, but the latest is $VERSION."
            read -p "Do you want to upgrade to the latest version? (y/n): " upgrade_response
            if [[ "$upgrade_response" = "y" || "$upgrade_response" = "Y" ]]; then
                UPGRADE=1
                echo "🔄 Upgrading to the latest version..."
            else
                echo "🚫 Upgrade skipped."
            fi
        fi
    fi
else
    if [ -f $AVAIL_BIN ]; then
        UPGRADE=1
        echo "⬆️ Triggering default upgrade of Avail binary..."
    fi
fi

onexit() {
    chmod 600 $IDENTITY
    echo "🔄 Avail stopped. Future instances of the light client can be started by invoking the avail-light binary or rerunning this script$EXTRAPROMPT"
    if [[ ":$PATH:" != *":$HOME/.avail/$NETWORK/bin:"* ]]; then
        if ! grep -q "export PATH=\"\$PATH:$HOME/.avail/$NETWORK/bin\"" "$PROFILE"; then
            echo -e "export PATH=\"\$PATH:$HOME/.avail/$NETWORK/bin\"\n" >>$PROFILE
        fi
        echo -e "📌 Avail has been added to your profile. Run the following command to load it in the current session:\n. $PROFILE\n"
    fi
    exit 0
}

run_binary() {
    trap onexit EXIT

    CMD="$AVAIL_BIN --config $CONFIG --identity $IDENTITY ${APPID:+--app-id $APPID}"
    
    if [ "$tracking_service" = "y" ] || [ "$tracking_service" = "yes" ]; then
        CMD="$CMD --tracking-service-enable"
    fi
    if [ ! -z "$tracking_service_address" ]; then
        CMD="$CMD --tracking-service-address $tracking_service_address"
    fi
    
    $CMD
    exit $?
}
# check if avail-light binary is available and check if upgrade variable is set to 0
if [ -f $AVAIL_BIN -a "$UPGRADE" = 0 ]; then
    echo "✅ Avail is already installed. Starting Avail..."
    trap onexit EXIT
    run_binary
fi
if [ "$UPGRADE" = 1 ]; then
    echo "🗑️ Wiping state data..."
    if [ -f $AVAIL_BIN ]; then
        rm $AVAIL_BIN
        if [ -d "$HOME/.avail/$NETWORK/data" ]; then
            rm -rf $HOME/.avail/$NETWORK/data
            mkdir $HOME/.avail/$NETWORK/data
        fi
    else
        echo "🤔 Avail was not installed with availup. Attemping to uninstall with cargo..."
        cargo uninstall avail-light || echo "👀 Avail was not installed with cargo, upgrade might not be required!"
        if command -v avail-light >/dev/null 2>&1; then
            echo "🚫 Avail was not uninstalled. Please uninstall manually and try again."
            exit 1
        fi
    fi
fi
if [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="apple-arm64"
elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="apple-x86_64"
elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-arm64"
elif [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-amd64"
fi
if [ -z "$ARCH_STRING" ]; then
    echo "📥 No binary available for this architecture, building from source instead. This can take a while..."
    # check if cargo is not available, else attempt to install through rustup
    if command -v cargo >/dev/null 2>&1; then
        echo "📦 Cargo is available. Building from source..."
    else
        echo "👀 Cargo is not available. Attempting to install with Rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        EXTRAPROMPT="\nℹ️ Cargo env needs to be loaded by running source \$HOME/.cargo/env"
        echo "📦 Cargo is now available. Reattempting to build from source..."
    fi
    # check if avail-light folder exists in home directory, if yes, pull latest changes, else clone the repo
    AVAIL_LIGHT_DIR=$HOME/avail-light
    if [ -d $AVAIL_LIGHT_DIR ]; then
        echo "🔄 Updating avail-light repository and building..."
        cd $AVAIL_LIGHT_DIR
        git pull -q origin $VERSION
        git checkout -q $VERSION
        cargo build --release
        cp $AVAIL_LIGHT_DIR/target/release/avail-light $AVAIL_BIN
    else
        echo "📂 Cloning avail-light repository and building..."
        git clone -q -c advice.detachedHead=false --depth=1 --single-branch --branch $VERSION https://github.com/availproject/avail-light.git $AVAIL_LIGHT_DIR
        cd $AVAIL_LIGHT_DIR
        cargo build --release
        mv $AVAIL_LIGHT_DIR/target/release/avail-light $AVAIL_BIN
        rm -rf $AVAIL_LIGHT_DIR
    fi
else
    if command -v curl >/dev/null 2>&1; then
        curl -sLO https://github.com/availproject/avail-light/releases/download/$VERSION/avail-light-$ARCH_STRING.tar.gz
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://github.com/availproject/avail-light/releases/download/$VERSION/avail-light-$ARCH_STRING.tar.gz
    else
        echo "🚫 Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi
    # use tar to extract the downloaded file and move it to .avail/bin/ directory
    tar -xzf avail-light-$ARCH_STRING.tar.gz
    chmod +x avail-light-$ARCH_STRING
    mv avail-light-$ARCH_STRING $AVAIL_BIN
    rm avail-light-$ARCH_STRING.tar.gz
fi
echo "✅ Availup exited successfully."
echo "🧱 Starting Avail."
run_binary
