#!/bin/bash

# subHawk Complete Installation Script
# Installs all required dependencies for subHawk with error handling

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
    echo -e "${CYAN}              subHawk Complete Installation${NC}"
    echo -e "${GREEN}              All Tools & Dependencies Setup${NC}"
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
        elif command -v apk &> /dev/null; then
            PKG_MANAGER="apk"
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
            $SUDO apt-get install -y curl wget git jq dnsutils build-essential unzip
            ;;
        "yum")
            $SUDO yum install -y curl wget git jq bind-utils gcc unzip
            ;;
        "dnf")
            $SUDO dnf install -y curl wget git jq bind-utils gcc-c++ unzip
            ;;
        "pacman")
            $SUDO pacman -Syu --noconfirm curl wget git jq bind gcc unzip
            ;;
        "apk")
            $SUDO apk add curl wget git jq bind-tools build-base unzip
            ;;
        "brew")
            brew install curl wget git jq bind gcc
            ;;
    esac
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}[!] Go is not installed. Installing...${NC}"
        install_go
    else
        GO_VERSION=$(go version | cut -d' ' -f3 | cut -c3-)
        echo -e "${GREEN}[+] Go ${GO_VERSION} already installed${NC}"
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
        i386|i686)
            GO_ARCH="386"
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
    GO_VERSION="1.21.5"
    GO_FILE="go${GO_VERSION}.${OS}-${GO_ARCH}.tar.gz"
    GO_URL="https://go.dev/dl/${GO_FILE}"
    
    echo -e "${BLUE}[*] Downloading Go ${GO_VERSION} for ${OS}/${GO_ARCH}...${NC}"
    if ! wget "${GO_URL}" -O "/tmp/${GO_FILE}" --quiet; then
        echo -e "${RED}[!] Failed to download Go. Trying with curl...${NC}"
        if ! curl -sSL "${GO_URL}" -o "/tmp/${GO_FILE}"; then
            echo -e "${RED}[!] Failed to download Go with both wget and curl${NC}"
            exit 1
        fi
    fi
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        $SUDO rm -rf /usr/local/go
        $SUDO tar -C /usr/local -xzf "/tmp/${GO_FILE}"
        echo 'export PATH=$PATH:/usr/local/go/bin' | $SUDO tee -a /etc/profile > /dev/null
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        source /etc/profile
        source ~/.bashrc
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        $SUDO rm -rf /usr/local/go
        $SUDO tar -C /usr/local -xzf "/tmp/${GO_FILE}"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        source ~/.zshrc
    fi
    
    rm "/tmp/${GO_FILE}"
    echo -e "${GREEN}[+] Go ${GO_VERSION} installed successfully${NC}"
}

install_required_tools() {
    echo -e "${BLUE}[*] Installing required tools...${NC}"
    
    # Ensure GOPATH and GOBIN are set
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin
    export PATH=$PATH:$GOBIN:/usr/local/go/bin
    
    # Create GOPATH if it doesn't exist
    mkdir -p $GOPATH
    
    # Install subfinder (required)
    echo -e "${BLUE}[*] Installing subfinder...${NC}"
    if ! command -v subfinder &> /dev/null; then
        if go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest; then
            echo -e "${GREEN}[+] subfinder installed successfully${NC}"
        else
            echo -e "${RED}[!] Failed to install subfinder${NC}"
            return 1
        fi
    else
        VERSION=$(subfinder --version 2>/dev/null || echo "version unknown")
        echo -e "${GREEN}[+] subfinder already installed (${VERSION})${NC}"
    fi
    
    # Install dnsx (required)
    echo -e "${BLUE}[*] Installing dnsx...${NC}"
    if ! command -v dnsx &> /dev/null; then
        if go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest; then
            echo -e "${GREEN}[+] dnsx installed successfully${NC}"
        else
            echo -e "${RED}[!] Failed to install dnsx${NC}"
            return 1
        fi
    else
        VERSION=$(dnsx --version 2>/dev/null || echo "version unknown")
        echo -e "${GREEN}[+] dnsx already installed (${VERSION})${NC}"
    fi
}

install_optional_tools() {
    echo -e "${BLUE}[*] Installing optional tools...${NC}"
    
    # Ensure GOPATH and GOBIN are set
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin
    export PATH=$PATH:$GOBIN:/usr/local/go/bin
    
    # Install httpx
    echo -e "${BLUE}[*] Installing httpx...${NC}"
    if ! command -v httpx &> /dev/null; then
        if go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest; then
            echo -e "${GREEN}[+] httpx installed successfully${NC}"
        else
            echo -e "${YELLOW}[!] Failed to install httpx${NC}"
        fi
    else
        VERSION=$(httpx --version 2>/dev/null || echo "version unknown")
        echo -e "${GREEN}[+] httpx already installed (${VERSION})${NC}"
    fi
    
    # Install amass
    echo -e "${BLUE}[*] Installing amass...${NC}"
    if ! command -v amass &> /dev/null; then
        if go install -v github.com/owasp/amass/v3/...@master; then
            echo -e "${GREEN}[+] amass installed successfully${NC}"
        else
            echo -e "${YELLOW}[!] Failed to install amass${NC}"
        fi
    else
        VERSION=$(amass --version 2>/dev/null || echo "version unknown")
        echo -e "${GREEN}[+] amass already installed (${VERSION})${NC}"
    fi
    
    # Install assetfinder
    echo -e "${BLUE}[*] Installing assetfinder...${NC}"
    if ! command -v assetfinder &> /dev/null; then
        if go install -v github.com/tomnomnom/assetfinder@latest; then
            echo -e "${GREEN}[+] assetfinder installed successfully${NC}"
        else
            echo -e "${YELLOW}[!] Failed to install assetfinder${NC}"
        fi
    else
        VERSION=$(assetfinder --help 2>&1 | head -n 1 | awk '{print $2}' || echo "version unknown")
        echo -e "${GREEN}[+] assetfinder already installed (${VERSION})${NC}"
    fi
    
    # Install findomain
    echo -e "${BLUE}[*] Installing findomain...${NC}"
    if ! command -v findomain &> /dev/null; then
        # Try multiple installation methods
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [[ $(uname -m) == "x86_64" ]]; then
                if wget "https://github.com/findomain/findomain/releases/latest/download/findomain-linux" -O "/tmp/findomain"; then
                    chmod +x /tmp/findomain
                    $SUDO mv /tmp/findomain /usr/local/bin/findomain
                    echo -e "${GREEN}[+] findomain installed via binary${NC}"
                else
                    echo -e "${YELLOW}[!] Failed to download findomain binary${NC}"
                fi
            else
                # For other architectures, try compiling
                if go install -v github.com/findomain/findomain/findomain@latest; then
                    echo -e "${GREEN}[+] findomain installed from source${NC}"
                else
                    echo -e "${YELLOW}[!] Failed to install findomain${NC}"
                fi
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                if brew install findomain; then
                    echo -e "${GREEN}[+] findomain installed via brew${NC}"
                else
                    echo -e "${YELLOW}[!] Failed to install findomain via brew${NC}"
                fi
            else
                echo -e "${YELLOW}[!] Homebrew required for findomain on macOS${NC}"
            fi
        fi
        
        # Final check
        if command -v findomain &> /dev/null; then
            VERSION=$(findomain --version 2>/dev/null || echo "version unknown")
            echo -e "${GREEN}[+] findomain confirmed installed (${VERSION})${NC}"
        else
            echo -e "${YELLOW}[!] findomain installation failed${NC}"
        fi
    else
        VERSION=$(findomain --version 2>/dev/null || echo "version unknown")
        echo -e "${GREEN}[+] findomain already installed (${VERSION})${NC}"
    fi
    
    # Install httprobe (alternative to httpx)
    echo -e "${BLUE}[*] Installing httprobe (alternative to httpx)...${NC}"
    if ! command -v httprobe &> /dev/null; then
        if go install -v github.com/tomnomnom/httprobe@latest; then
            echo -e "${GREEN}[+] httprobe installed successfully${NC}"
        else
            echo -e "${YELLOW}[!] Failed to install httprobe${NC}"
        fi
    else
        echo -e "${GREEN}[+] httprobe already installed${NC}"
    fi
}

install_wordlists() {
    echo -e "${BLUE}[*] Installing wordlists...${NC}"
    
    # Install SecLists
    if [ ! -d "/usr/share/seclists" ]; then
        echo -e "${BLUE}[*] Cloning SecLists...${NC}"
        if git clone --depth 1 https://github.com/danielmiessler/SecLists.git /tmp/SecLists; then
            $SUDO mv /tmp/SecLists /usr/share/seclists
            echo -e "${GREEN}[+] SecLists installed${NC}"
        else
            echo -e "${YELLOW}[!] Failed to clone SecLists${NC}"
        fi
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

setup_environment() {
    echo -e "${BLUE}[*] Setting up environment...${NC}"
    
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
    
    # Ensure Go paths are in shell profile
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! grep -q 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' ~/.bashrc 2>/dev/null; then
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! grep -q 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' ~/.zshrc 2>/dev/null; then
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.zshrc
        fi
    fi
    
    echo -e "${GREEN}[+] Environment configured${NC}"
}

verify_installation() {
    echo -e "${BLUE}[*] Verifying installation...${NC}"
    
    # Re-source environment
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        source ~/.bashrc 2>/dev/null || true
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        source ~/.zshrc 2>/dev/null || true
    fi
    
    # Update PATH
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    
    # Required tools verification
    REQUIRED_TOOLS=(subfinder dnsx)
    OPTIONAL_TOOLS=(httpx amass assetfinder findomain httprobe)
    
    echo -e "${BLUE}[Required Tools]${NC}"
    all_required_installed=true
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            version=$($tool --version 2>/dev/null || $tool -version 2>/dev/null || echo "version unknown")
            echo -e "  ${GREEN}✓${NC} $tool - ${version:-installed}"
        else
            echo -e "  ${RED}✗${NC} $tool - NOT INSTALLED"
            all_required_installed=false
        fi
    done
    
    if [ "$all_required_installed" = false ]; then
        echo -e "${RED}[!] Required tools missing. Installation incomplete!${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[Optional Tools]${NC}"
    for tool in "${OPTIONAL_TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            version=$($tool --version 2>/dev/null || $tool -version 2>/dev/null || echo "version unknown")
            echo -e "  ${GREEN}✓${NC} $tool - ${version:-installed}"
        else
            echo -e "  ${YELLOW}⚠${NC} $tool - NOT INSTALLED"
        fi
    done
    
    echo -e "${GREEN}[+] Installation verification complete${NC}"
    return 0
}

show_completion() {
    echo -e "${GREEN}"
    echo "========================================"
    echo "  subHawk Installation Complete!"
    echo "========================================"
    echo -e "${NC}"
    
    echo -e "${BLUE}Installed Tools:${NC}"
    echo "  ✓ subfinder (required)"
    echo "  ✓ dnsx (required)"
    echo "  ✓ httpx (optional)"
    echo "  ✓ amass (optional)"
    echo "  ✓ assetfinder (optional)"
    echo "  ✓ findomain (optional)"
    echo "  ✓ httprobe (optional)"
    
    echo -e "${BLUE}Installed Resources:${NC}"
    echo "  ✓ SecLists (/usr/share/seclists or in ~/go/src/github.com/danielmiessler/SecLists)"
    echo "  ✓ subHawk wordlists (~/.subhawk/wordlists/)"
    echo "  ✓ subHawk configuration (~/.subhawk/config.yaml)"
    
    echo -e "${BLUE}Usage:${NC}"
    echo "  chmod +x subHawk.sh"
    echo "  ./subHawk.sh -d example.com"
    
    echo -e "${YELLOW}"
    echo "Note: You may need to reload your shell or run:"
    echo "  source ~/.bashrc  # (on Linux)"
    echo "  source ~/.zshrc   # (on macOS)"
    echo -e "${NC}"
    
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
    
    echo -e "${BLUE}[*] Starting subHawk complete installation...${NC}"
    
    if install_prerequisites; then
        echo -e "${GREEN}[+] Prerequisites installed${NC}"
    else
        echo -e "${RED}[!] Failed to install prerequisites${NC}"
        exit 1
    fi
    
    if install_required_tools; then
        echo -e "${GREEN}[+] Required tools installed${NC}"
    else
        echo -e "${RED}[!] Failed to install required tools${NC}"
        exit 1
    fi
    
    install_optional_tools
    install_wordlists
    setup_environment
    
    if verify_installation; then
        show_completion
    else
        echo -e "${RED}[!] Installation verification failed${NC}"
        exit 1
    fi
}

# Run installation
main "$@"
