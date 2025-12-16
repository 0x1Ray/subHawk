#!/bin/bash

# subHawk Installation Script
# Installs all required and optional dependencies for subHawk

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_banner() {
    echo -e "${PURPLE}
  ██████  █    ██  ▄▄▄▄   ▄▄▄██▀▀▀▄▄▄      █     █░▄▄▄█████▓
▒██    ▒  ██  ▓██▒▓█████▄   ▒██   ▓██▒   ▒███   ▓██░▓  ██▒ ▓▒
░ ▓██▄   ▓██  ▒██░▒██▒ ▄██  ░██   ▒██░   ▒██░   ▒██░▒ ▓██░ ▒░
  ▒   ██▒▓▓█  ░██░▒██░█▀    ▓██▄██▓ ▒██░   ▒██░   ░██░░ ▓██▓ ░ 
▒██████▒▒▒▒█████▓ ░▓█  ▀█▓   ▓███▒  ░██████▒░██████▒░██░  ▒██▒ ░ 
▒ ▒▓▒ ▒ ░░▒▓▒ ▒ ▒ ░▒▓███▀▒   ▒▓▒▒░  ░ ▒░▓  ░░ ▒░▓  ░░▓    ▒ ░░   
░ ░▒  ░ ░░░▒░ ░ ░ ▒░▒   ░    ▒ ░▒░  ░ ░ ▒  ░░ ░ ▒  ░ ▒ ░    ░    
░  ░  ░   ░░░ ░ ░  ░    ░    ░        ░ ░     ░ ░    ▒ ░  ░      
      ░     ░      ░         ░ ░        ░  ░    ░  ░ ░           
                              ░                                  
${NC}"
    echo -e "${CYAN}              subHawk Installation Script${NC}"
    echo -e "${GREEN}              Installing Ultimate Enumeration Tools${NC}"
    echo -e "${YELLOW}==============================================================${NC}"
    echo
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        if command -v sudo &> /dev/null; then
            SUDO="sudo"
        else
            echo -e "${RED}[!] This script requires root privileges. Please run with sudo.${NC}"
            exit 1
        fi
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            PKG_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
        else
            echo -e "${RED}[!] Unsupported package manager. Please install dependencies manually.${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            PKG_MANAGER="brew"
        else
            echo -e "${RED}[!] Homebrew is required on macOS. Please install it first.${NC}"
            echo "Visit: https://brew.sh/"
            exit 1
        fi
    else
        echo -e "${RED}[!] Unsupported operating system.${NC}"
        exit 1
    fi
}

install_prerequisites() {
    echo -e "${BLUE}[*] Installing system prerequisites...${NC}"
    
    case $PKG_MANAGER in
        "apt")
            $SUDO apt-get update
            $SUDO apt-get install -y curl wget git jq dnsutils build-essential
            ;;
        "yum")
            $SUDO yum install -y curl wget git jq bind-utils gcc
            ;;
        "dnf")
            $SUDO dnf install -y curl wget git jq bind-utils gcc
            ;;
        "pacman")
            $SUDO pacman -Syu --noconfirm curl wget git jq bind gcc
            ;;
        "brew")
            brew install curl wget git jq bind
            ;;
    esac
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}[!] Go is not installed. Installing...${NC}"
        install_go
    else
        echo -e "${GREEN}[+] Go is already installed${NC}"
    fi
}

install_go() {
    echo -e "${BLUE}[*] Installing Go...${NC}"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            GO_ARCH="amd64"
            ;;
        aarch64|arm64)
            GO_ARCH="arm64"
            ;;
        armv6l)
            GO_ARCH="armv6l"
            ;;
        *)
            echo -e "${RED}[!] Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
    else
        echo -e "${RED}[!] Unsupported OS for automatic Go installation${NC}"
        exit 1
    fi
    
    # Download and install Go
    GO_VERSION="1.21.0"
    GO_FILE="go${GO_VERSION}.${OS}-${GO_ARCH}.tar.gz"
    wget "https://go.dev/dl/${GO_FILE}" -O /tmp/${GO_FILE}
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        $SUDO rm -rf /usr/local/go
        $SUDO tar -C /usr/local -xzf /tmp/${GO_FILE}
        echo 'export PATH=$PATH:/usr/local/go/bin' | $SUDO tee -a /etc/profile > /dev/null
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
        source /etc/profile
        source ~/.bashrc
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        $SUDO rm -rf /usr/local/go
        $SUDO tar -C /usr/local -xzf /tmp/${GO_FILE}
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
        source ~/.zshrc
    fi
    
    rm /tmp/${GO_FILE}
    echo -e "${GREEN}[+] Go installed successfully${NC}"
}

install_required_tools() {
    echo -e "${BLUE}[*] Installing required tools...${NC}"
    
    # Install subfinder
    echo -e "${BLUE}[*] Installing subfinder...${NC}"
    if ! command -v subfinder &> /dev/null; then
        go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        echo -e "${GREEN}[+] subfinder installed${NC}"
    else
        echo -e "${GREEN}[+] subfinder already installed${NC}"
    fi
    
    # Install dnsx
    echo -e "${BLUE}[*] Installing dnsx...${NC}"
    if ! command -v dnsx &> /dev/null; then
        go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
        echo -e "${GREEN}[+] dnsx installed${NC}"
    else
        echo -e "${GREEN}[+] dnsx already installed${NC}"
    fi
}

install_optional_tools() {
    echo -e "${BLUE}[*] Installing optional tools...${NC}"
    
    # Install httpx
    echo -e "${BLUE}[*] Installing httpx...${NC}"
    if ! command -v httpx &> /dev/null; then
        go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
        echo -e "${GREEN}[+] httpx installed${NC}"
    else
        echo -e "${GREEN}[+] httpx already installed${NC}"
    fi
    
    # Install amass
    echo -e "${BLUE}[*] Installing amass...${NC}"
    if ! command -v amass &> /dev/null; then
        go install -v github.com/owasp/amass/v3/...@master
        echo -e "${GREEN}[+] amass installed${NC}"
    else
        echo -e "${GREEN}[+] amass already installed${NC}"
    fi
    
    # Install assetfinder
    echo -e "${BLUE}[*] Installing assetfinder...${NC}"
    if ! command -v assetfinder &> /dev/null; then
        go install -v github.com/tomnomnom/assetfinder@latest
        echo -e "${GREEN}[+] assetfinder installed${NC}"
    else
        echo -e "${GREEN}[+] assetfinder already installed${NC}"
    fi
    
    # Install findomain
    echo -e "${BLUE}[*] Installing findomain...${NC}"
    if ! command -v findomain &> /dev/null; then
        # Try to download pre-compiled binary
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [[ $(uname -m) == "x86_64" ]]; then
                wget https://github.com/findomain/findomain/releases/latest/download/findomain-linux -O findomain
                chmod +x findomain
                $SUDO mv findomain /usr/local/bin/
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install findomain
        fi
        
        if command -v findomain &> /dev/null; then
            echo -e "${GREEN}[+] findomain installed${NC}"
        else
            echo -e "${YELLOW}[!] Could not install findomain${NC}"
        fi
    else
        echo -e "${GREEN}[+] findomain already installed${NC}"
    fi
}

install_wordlists() {
    echo -e "${BLUE}[*] Installing wordlists...${NC}"
    
    # Install SecLists
    if [ ! -d "/usr/share/seclists" ]; then
        echo -e "${BLUE}[*] Cloning SecLists...${NC}"
        $SUDO git clone https://github.com/danielmiessler/SecLists.git /usr/share/seclists
        echo -e "${GREEN}[+] SecLists installed${NC}"
    else
        echo -e "${GREEN}[+] SecLists already installed${NC}"
    fi
    
    # Install subHawk specific wordlists if needed
    mkdir -p ~/.subhawk/wordlists
    
    # Create common subdomain wordlist
    cat > ~/.subhawk/wordlists/common.txt << 'EOF'
www
mail
ftp
admin
test
dev
api
blog
shop
forum
portal
login
auth
vpn
secure
dashboard
console
stage
staging
prod
production
internal
intranet
cpanel
webmail
old
new
beta
alpha
demo
uat
qa
support
help
docs
status
cdn
assets
img
image
css
js
files
download
downloads
media
video
audio
app
mobile
m
static
stats
analytics
search
wiki
git
svn
jenkins
nagios
cacti
zabbix
splunk
kibana
elasticsearch
prometheus
grafana
ansible
chef
puppet
docker
kubernetes
openshift
aws
azure
gcp
consul
vault
nomad
terraform
redis
mongodb
mysql
postgresql
oracle
sqlserver
elb
alb
nlb
cloudfront
s3
ec2
lambda
rds
dynamodb
iam
vpc
route53
cloudflare
akamai
fastly
imperva
EOF
    
    echo -e "${GREEN}[+] subHawk wordlists installed${NC}"
}

setup_subhawk() {
    echo -e "${BLUE}[*] Setting up subHawk...${NC}"
    
    # Make sure subHawk script is executable
    if [ -f "./subHawk.sh" ]; then
        chmod +x ./subHawk.sh
        echo -e "${GREEN}[+] subHawk script made executable${NC}"
    else
        echo -e "${YELLOW}[!] subHawk.sh not found in current directory${NC}"
    fi
    
    # Create config directory
    mkdir -p ~/.subhawk
    
    # Create default config
    cat > ~/.subhawk/config.yaml << 'EOF'
# subHawk Configuration File
sources:
  - "alienvault"
  - "anubis"
  - "bufferover"
  - "c99"
  - "censys"
  - "certspotter"
  - "chaos"
  - "commoncrawl"
  - "crtsh"
  - "digicert"
  - "dnsdumpster"
  - "dnsrepo"
  - "hackertarget"
  - "intelx"
  - "passivetotal"
  - "securitytrails"
  - "shodan"
  - "subdomainfinderc99"
  - "threatcrowd"
  - "urlscan"
  - "virustotal"
  - "waybackarchive"
  - "whoisxmlapi"
  - "zoomeye"

# Default threads count
threads: 100

# Risk scoring thresholds
risk_thresholds:
  high: 50
  medium: 25
  low: 0

# Output formats
output_formats:
  - "txt"
  - "json"
  - "csv"
EOF
    
    echo -e "${GREEN}[+] subHawk configuration created${NC}"
}

show_completion() {
    echo -e "${GREEN}"
    echo "========================================"
    echo "  subHawk Installation Complete!"
    echo "========================================"
    echo -e "${NC}"
    
    echo -e "${BLUE}Installed Tools:${NC}"
    echo "  - subfinder (required)"
    echo "  - dnsx (required)"
    echo "  - httpx (optional)"
    echo "  - amass (optional)"
    echo "  - assetfinder (optional)"
    echo "  - findomain (optional)"
    
    echo -e "${BLUE}Installed Resources:${NC}"
    echo "  - SecLists (/usr/share/seclists)"
    echo "  - subHawk wordlists (~/.subhawk/wordlists/)"
    echo "  - subHawk configuration (~/.subhawk/config.yaml)"
    
    echo -e "${BLUE}Usage:${NC}"
    echo "  chmod +x subHawk.sh"
    echo "  ./subHawk.sh -d example.com"
    
    echo -e "${YELLOW}Note: You may need to reload your shell or run 'source ~/.bashrc'${NC}"
    echo -e "${YELLOW}      (or the appropriate config file for your shell)${NC}"
    
    echo -e "${GREEN}"
    echo "========================================"
    echo "  Happy Hunting!"
    echo "========================================"
    echo -e "${NC}"
}

# Main installation function
main() {
    show_banner
    check_sudo
    detect_os
    
    echo -e "${BLUE}[*] Starting subHawk installation...${NC}"
    
    install_prerequisites
    install_required_tools
    install_optional_tools
    install_wordlists
    setup_subhawk
    
    show_completion
}

# Run installation
main "$@"
