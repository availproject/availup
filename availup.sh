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
# generate folders if missing
if [ ! -d "$HOME/.avail" ]; then
    mkdir $HOME/.avail
fi
if [ ! -d "$HOME/.avail/bin" ]; then
    mkdir $HOME/.avail/bin
fi
if [ ! -d "$HOME/.avail/identity" ]; then
    mkdir $HOME/.avail/identity
fi
if [ ! -d "$HOME/.avail/data" ]; then
    mkdir $HOME/.avail/data
fi
if [ ! -d "$HOME/.avail/config" ]; then
    mkdir $HOME/.avail/config
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
    echo "🛜  No network selected. Defaulting to goldberg testnet."
    NETWORK="goldberg"
else
    NETWORK="$network"
fi
CONFIG_PARAMS="bootstraps=['/dns/bootnode.1.lightclient.goldberg.avail.tools/tcp/37000/p2p/12D3KooWBkLsNGaD3SpMaRWtAmWVuiZg1afdNSPbtJ8M8r9ArGRT','/dns/bootnode.2.lightclient.goldberg.avail.tools/tcp/37000/p2p/12D3KooWRCgfvaLSnQfkwGehrhSNpY7i5RenWKL2ARst6ZqgdZZd']\nfull_node_ws=['wss://rpc-goldberg.sandbox.avail.tools:443','wss://goldberg-rpc.fra.avail.tools:443']\nconfidence=99.0\navail_path='$HOME/.avail/data'\nrecord_ttl=43200\n"
AVAIL_BIN=$HOME/.avail/bin/avail-light
if [ "$NETWORK" = "goldberg" ]; then
    echo "📌 Goldberg testnet selected."
    VERSION="v1.7.9"
    if [ -z "$config" ]; then
        CONFIG="$HOME/.avail/config/config.yml"
        if [ -f "$CONFIG" ]; then
            echo "📄 Configuration file found at $CONFIG."
        else
            echo "🤷 No configuration file set. This will be automatically generated at startup."
        fi
        touch $CONFIG
        echo -e $CONFIG_PARAMS >> $CONFIG
    else
        CONFIG="$config"
    fi
elif [ "$NETWORK" = "local" ]; then
    echo "📌 Local testnet selected."
    VERSION="v1.7.9"
    if [ -z "$config" ]; then
        echo "🚫 No configuration file was provided for local testnet, exiting."
        exit 1
    fi
else
    echo "🚫 Invalid network selected. Select one of the following: goldberg, local."
    exit 1
fi
if [ -z "$app_id" ]; then
    echo "📲 No app ID specified. Defaulting to light client mode."
    APPID="0"
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
# check if avail-light version matches!
UPGRADE=0
if [ ! -z "$upgrade" ]; then
    echo "🔄 Checking for updates..."
    if [ -f $AVAIL_BIN ]; then
        CURRENT_VERSION="v$($HOME/.avail/bin/avail-light --version | cut -d " " -f 2)"
        if [ "$CURRENT_VERSION" = "v1.7.8" ] && [ "$VERSION" = "v1.7.9" ]; then
            UPGRADE=0
            echo "✨ Avail binary is up to date. Skipping upgrade."
        elif [ "$CURRENT_VERSION" != "$VERSION" ]; then
            UPGRADE=1
            echo "✨ Avail binary is up to date. Skipping upgrade."
        else
            if [ "$upgrade" = "y" -o "$upgrade" = "yes" ]; then
                UPGRADE=1
            fi
        fi
    fi
fi

onexit() {
    chmod 600 $IDENTITY
    echo "🔄 Avail stopped. Future instances of the light client can be started by invoking the avail-light binary or rerunning this script$EXTRAPROMPT"
    if [[ ":$PATH:" != *":$HOME/.avail/bin:"* ]]; then
        if ! grep -q "export PATH=\"\$PATH:$HOME/.avail/bin\"" "$PROFILE"; then
            echo -e "export PATH=\"\$PATH:$HOME/.avail/bin\"\n" >>$PROFILE
        fi
        echo -e "📌 Avail has been added to your profile. Run the following command to load it in the current session:\n. $PROFILE\n"
    fi
    exit 0
}
# check if avail-light binary is available and check if upgrade variable is set to 0
if [ -f $AVAIL_BIN -a "$UPGRADE" = 0 ]; then
    echo "✅ Avail is already installed. Starting Avail..."
    trap onexit EXIT
    $HOME/.avail/bin/avail-light --config $CONFIG --app-id $APPID --identity $IDENTITY
    exit 0
fi
if [ "$UPGRADE" = 1 ]; then
    echo "🔄 Upgrading Avail..."
    if [ -f $AVAIL_BIN ]; then
        rm $AVAIL_BIN
        if [ -f $CONFIG ]; then
            rm $CONFIG
            touch $CONFIG
            echo $CONFIG_PARAMS >>$CONFIG
        fi
        if [ -d "$HOME/.avail/data" ]; then
            rm -rf $HOME/.avail/data
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
    ARCH_STRING="linux-aarch64"
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
    echo "📂 Cloning avail-light repository and building..."
    git clone -q -c advice.detachedHead=false --depth=1 --single-branch --branch $VERSION https://github.com/availproject/avail-light.git $HOME/avail-light
    cd $HOME/avail-light
    cargo install --locked --path . --bin avail-light
    rm -rf $HOME/avail-light
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
trap onexit EXIT
$AVAIL_BIN --config $CONFIG --app-id $APPID --identity $IDENTITY
