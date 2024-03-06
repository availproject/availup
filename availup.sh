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
if [ -f "$HOME/.bashrc" ]; then
    PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.kshrc" ]; then
    PROFILE="$HOME/.kshrc"
else
    echo "🫣 Unable to locate a profile, availup might not work as intended!"
    PROFILE="/etc/profile"
fi
if [ -z "$network" ]; then
    echo "ℹ️ No network selected. Defaulting to goldberg."
    NETWORK="goldberg"
else 
    NETWORK="$network"
fi
if [ "$NETWORK" = "goldberg" ]; then
    echo "📌 Goldberg network selected."
    VERSION="v1.7.9"
elif [ "$NETWORK" = "kate" ]; then
    echo "📌 Kate network selected."
    VERSION="v1.7.9"
elif [ "$NETWORK" = "local" ]; then
    echo "📌 Local network selected."
    VERSION="v1.7.9"
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
if [ ! -d "$HOME/.avail-light" ]; then
    mkdir $HOME/.avail-light
fi
if [ ! -d "$HOME/.avail-light/$NETWORK" ]; then
    mkdir $HOME/.avail-light/$NETWORK
fi
if [ -z "$config" ]; then
    echo "ℹ️ No config file selected. Defaulting to $NETWORK config..."
else 
    CONFIG=$config
fi
onexit() {
    echo "🔄 Avail stopped. Future instances of the light client can be started by invoking the avail-light binary directly$EXTRAPROMPT"
    if [[ ":$PATH:" != *":$HOME/.availup:"* ]]; then
        echo "📌 Adding Avail to your path. Please run the following command to load it in the current terminal session:\nsource $PROFILE"
        echo "export PATH=\$PATH:$HOME/.availup" >> $PROFILE
    fi
    exit 0
}
if command -v avail-light >/dev/null 2>&1; then
    echo "✅ Avail is already installed. Starting Avail..."
    trap onexit EXIT
    if [ -z "$config" ]; then
        $HOME/.availup/avail-light --network $NETWORK --app-id $APPID
    else
        $HOME/.availup/avail-light --config $CONFIG --app-id $APPID
    fi
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
    if [ ! -d "$HOME/.availup" ]; then
        sudo mkdir $HOME/.availup
    fi
    sudo mv avail-light-$ARCH_STRING $HOME/.availup/avail-light
    rm avail-light-$ARCH_STRING.tar.gz
fi
echo "✅ Availup exited successfully."
echo "🧱 Starting Avail."
trap onexit EXIT
if [ -z "$config" ]; then
    $HOME/.availup/avail-light --network $NETWORK --app-id $APPID
else
    $HOME/.availup/avail-light --config $CONFIG --app-id $APPID
fi
