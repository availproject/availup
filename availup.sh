#!/usr/bin/env sh
echo "🆙 Starting Availup..."
while [ $# -gt 0 ]; do
    if [[ $1 == "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done
if [ -z "$network" ]; then
    echo "ℹ️ No network selected. Defaulting to goldberg."
    NETWORK="goldberg"
else 
    NETWORK="$network"
fi
if [ "$NETWORK" = "goldberg" ]; then
    echo "📌 Goldberg network selected."
    VERSION="v1.7.4"
elif [ "$NETWORK" = "kate" ]; then
    echo "📌 Kate network selected."
    VERSION="v1.7.4"
elif [ "$NETWORK" = "local" ]; then
    echo "📌 Local network selected."
    VERSION="v1.7.4"
else
    echo "🚫 Invalid network selected. Please select one of the following: goldberg, kate, local."
    exit 1
fi
if [ -z "$app_id" ]; then
    echo "ℹ️ No app ID specified. Defaulting to 0."
    APPID="0"
else 
    APPID="$app_id"
fi
if [ ! -d "$HOME/.avail" ]; then
    mkdir $HOME/.avail
fi
if [ ! -d "$HOME/.avail/$NETWORK" ]; then
    mkdir $HOME/.avail/$NETWORK
fi
if [ ! -d "$HOME/.avail-light" ]; then
    mkdir $HOME/.avail-light
fi
if [ ! -d "$HOME/.avail-light/$NETWORK" ]; then
    mkdir $HOME/.avail-light/$NETWORK
fi
if [ -z "$config" ]; then
    echo "ℹ️ No config file selected. Defaulting to $HOME/.avail/$NETWORK/config.yml."
    CONFIG="$HOME/.avail/$NETWORK/config.yml"
    touch $CONFIG
    if command -v hexdump >/dev/null 2>&1; then
        echo "🔐 Generating random seed..."
        SEED=$(hexdump -vn32 -e'8/8 "%0X"' /dev/urandom)
    else
        SEED="$RANDOM$RANDOM-avail-$RANDOM$RANDOM"
    fi
    if [ "$NETWORK" = "goldberg" ]; then
        echo "log_level = \"info\"\nhttp_server_host = \"0.0.0.0\"\nhttp_server_port = 7001\n\nsecret_key = { seed = \"$SEED\" }\nlibp2p_port = \"37000\"\nfull_node_ws = [\"wss://goldberg.avail.tools:443/ws\"]\napp_id = $APPID\nconfidence = 99.0\navail_path = \"$HOME/.avail-light/$NETWORK\"\nbootstraps = [[\"12D3KooWBkLsNGaD3SpMaRWtAmWVuiZg1afdNSPbtJ8M8r9ArGRT\",\"/dns/bootnode.1.lightclient.goldberg.avail.tools/udp/37000/quic-v1\"]]" >~/.avail/$NETWORK/config.yml
    elif [ "$NETWORK" = "kate" ]; then
        echo "log_level = \"info\"\nhttp_server_host = \"0.0.0.0\"\nhttp_server_port = 7001\n\nsecret_key = { seed = \"$SEED\" }\nlibp2p_port = \"37000\"\nfull_node_ws = [\"wss://kate.avail.tools:443/ws\"]\napp_id = $APPID\nconfidence = 99.0\navail_path = \"$HOME/.avail-light/$NETWORK\"\nbootstraps = [\"/ip4/127.0.0.1/tcp/39000/quic-v1/12D3KooWMm1c4pzeLPGkkCJMAgFbsfQ8xmVDusg272icWsaNHWzN\"]" >~/.avail/$NETWORK/config.yml
    fi
else 
    CONFIG=$config
fi
onexit() {
    echo "🔄 Avail stopped. Future instances of the light client can be started by invoking avail-light -c \$HOME/.avail/$NETWORK/config.yml$EXTRAPROMPT"
    exit 0
}
# check if avail-light binary is installed, if yes, just run it
if command -v avail-light >/dev/null 2>&1; then
    echo "✅ Avail is already installed. Starting Avail with default config..."
    trap onexit EXIT
    avail-light -c $CONFIG
    exit 0
fi
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-amd64"
elif [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="apple-arm64"
elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="apple-x86_64"
elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-aarch64"
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
    # use tar to extract the downloaded file and move it to /usr/local/bin
    tar -xzf avail-light-$ARCH_STRING.tar.gz
    chmod +x avail-light-$ARCH_STRING
    if [ ! -d "/usr/local" ]; then
        sudo mkdir /usr/local
    fi
    if [ ! -d "/usr/local/bin" ]; then
        sudo mkdir /usr/local/bin
    fi
    sudo mv avail-light-$ARCH_STRING /usr/local/bin/avail-light
    rm avail-light-$ARCH_STRING.tar.gz
fi
echo "✅ Availup exited successfully."
echo "🧱 Starting Avail."
trap onexit EXIT
avail-light -c $CONFIG
