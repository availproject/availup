echo "🆙 Starting Availup..."
if [ ! -d "${HOME}/.avail" ]; then
    mkdir $HOME/.avail
fi
if [ ! -d "${HOME}/.avail-light" ]; then
    mkdir $HOME/.avail-light
fi
if [ ! -f "${HOME}/.avail/config.yml" ]; then
    touch $HOME/.avail/config.yml
    echo "log_level = \"info\"\nhttp_server_host = \"0.0.0.0\"\nhttp_server_port = 7001\n\nsecret_key = { seed = \"${RANDOM}avail${RANDOM}\" }\nlibp2p_port = \"37000\"\nfull_node_ws = [\"wss://kate.avail.tools:443/ws\"]\napp_id = 0\nconfidence = 99.0\navail_path = \"${HOME}/.avail-light\"\nbootstraps = [\"/ip4/127.0.0.1/tcp/39000/quic-v1/12D3KooWMm1c4pzeLPGkkCJMAgFbsfQ8xmVDusg272icWsaNHWzN\"]" >~/.avail/config.yml
fi
onexit() {
    echo "🔄 Avail stopped. Future instances of the light client can be started by invoking avail-light -c \$HOME/.avail/config.yml$EXTRAPROMPT"
    exit 0
}
# check if avail-light binary is installed, if yes, just run it
if command -v avail-light >/dev/null 2>&1; then
    echo "✅ Avail is already installed. Starting Avail with default config..."
    trap onexit EXIT
    avail-light -c $HOME/.avail/config.yml
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
    if [ -d "${HOME}/avail-light" ]; then
        echo "📂 Avail-light is already cloned. Pulling latest changes..."
        cd $HOME/avail-light
        git pull
    else
        echo "📂 Avail-light is not cloned. Cloning..."
        git clone -q --depth=1 --single-branch --branch=main https://github.com/availproject/avail-light.git $HOME/avail-light
        cd $HOME/avail-light
    fi
    cargo install --locked --path . --bin avail-light
else
    VERSION="v1.7.3-rc1"
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
    sudo mv avail-light-$ARCH_STRING /usr/local/bin/avail-light
    rm avail-light-$ARCH_STRING.tar.gz
fi
echo "✅ Availup exited successfully."
echo "🧱 Starting Avail."
trap onexit EXIT
avail-light -c $HOME/.avail/config.yml
