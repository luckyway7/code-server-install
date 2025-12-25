#!/bin/bash
set -e

sudo apt update
sudo apt install -y curl jq moreutils whiptail

CODE_SERVER_PORT=$(whiptail --inputbox "[code-server] порт" 8 50 3>&1 1>&2 2>&3) || exit 1
CODE_SERVER_PASSWORD=$(whiptail --passwordbox "[code-server] пароль" 8 50 3>&1 1>&2 2>&3) || exit 1

curl -fsSL https://code-server.dev/install.sh | bash

CODE_SERVER_BIN=/usr/bin/code-server

mkdir -p ~/.config/code-server

cat > ~/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:$CODE_SERVER_PORT
auth: password
password: $CODE_SERVER_PASSWORD
cert: false
EOF

SERVICE_USER=$(whoami)

sudo tee /etc/systemd/system/code-server.service > /dev/null <<EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$HOME
Environment="SHELL=/usr/bin/bash"
ExecStart=$CODE_SERVER_BIN
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable code-server
sudo systemctl start code-server

mkdir -p /root/.local/share/code-server/User
cat > /root/.local/share/code-server/User/settings.json <<'EOF'
{
    "window.menuBarVisibility": "classic",
    "workbench.editor.editorActionsLocation": "titleBar",
    "workbench.sideBar.location": "right",
    "editor.fontSize": 16,
    "workbench.colorTheme": "Default Dark+",
    "editor.formatOnSave": false,
    "editor.semanticHighlighting.enabled": true,
    "python.languageServer": "Jedi",
    "editor.wordWrap": "on",
    "editor.stickyScroll.enabled": false,
    "workbench.iconTheme": "file-icons",
    "explorer.confirmDragAndDrop": false,
    "editor.minimap.enabled": false,
    "terminal.integrated.stickyScroll.enabled": false,
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.profiles.linux": {
        "bash": {
            "path": "/usr/bin/bash"
        }
    }
}
EOF

sudo jq '. + {
  "extensionsGallery": {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
    "itemUrl": "https://marketplace.visualstudio.com/items"
  }
}' /usr/lib/code-server/lib/vscode/product.json | sudo sponge /usr/lib/code-server/lib/vscode/product.json

/usr/bin/code-server --install-extension nextbook.file-and-folder-icons

sudo systemctl restart code-server
