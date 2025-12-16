#!/bin/bash

echo "🔍 Verifying subHawk Installation..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if script is installed system-wide
if command -v subhawk &> /dev/null; then
    echo -e "${GREEN}[✓] subHawk is installed system-wide${NC}"
    INSTALL_PATH=$(which subhawk)
    echo -e "${BLUE}[*] Installation path: $INSTALL_PATH${NC}"
else
    echo -e "${YELLOW}[!] subHawk is not installed system-wide${NC}"
    echo -e "${BLUE}[*] Checking local installation...${NC}"
    
    if [ -f "./subhawk.sh" ]; then
        echo -e "${GREEN}[✓] subHawk script found locally${NC}"
        INSTALL_PATH="./subhawk.sh"
    else
        echo -e "${RED}[✗] subHawk script not found locally${NC}"
        exit 1
    fi
fi

# Check dependencies
echo -e "\n${BLUE}[*] Checking dependencies...${NC}"

REQUIRED_TOOLS=(dig curl)
OPTIONAL_TOOLS=(subfinder dnsx httprobe httpx nc)
MISSING_REQUIRED=()
MISSING_OPTIONAL=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        VERSION=$($tool --version 2>/dev/null || echo "installed")
        echo -e "${GREEN}[✓]${NC} $tool - available"
    else
        echo -e "${RED}[✗]${NC} $tool - MISSING (REQUIRED)"
        MISSING_REQUIRED+=("$tool")
    fi
done

for tool in "${OPTIONAL_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}[✓]${NC} $tool - available"
    else
        echo -e "${YELLOW}[!]${NC} $tool - NOT INSTALLED (Optional)"
        MISSING_OPTIONAL+=("$tool")
    fi
done

if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
    echo -e "\n${RED}[✗] Required tools missing: ${MISSING_REQUIRED[*]}${NC}"
    echo -e "${YELLOW}Please install the missing required tools before using subHawk${NC}"
    exit 1
fi

# Test basic functionality
echo -e "\n${BLUE}[*] Testing basic functionality...${NC}"

# Test with a simple domain
TEST_DOMAIN="example.com"
echo -e "${BLUE}[*] Testing with $TEST_DOMAIN...${NC}"

if [ -f "$INSTALL_PATH" ]; then
    # Run a quick test
    timeout 30s bash "$INSTALL_PATH" -d "$TEST_DOMAIN" --fast --no-http-check -o /tmp/subhawk_test.txt 2>/dev/null
    
    if [ -f "/tmp/subhawk_test.txt" ]; then
        RESULT_COUNT=$(grep -c "\.example\.com" /tmp/subhawk_test.txt 2>/dev/null || echo "0")
        if [ "$RESULT_COUNT" -gt 0 ]; then
            echo -e "${GREEN}[✓] subHawk working correctly - found $RESULT_COUNT subdomains for $TEST_DOMAIN${NC}"
        else
            echo -e "${YELLOW}[!] subHawk ran but found 0 subdomains for $TEST_DOMAIN${NC}"
        fi
        rm -f /tmp/subhawk_test.txt
    else
        echo -e "${YELLOW}[!] Could not generate test output${NC}"
    fi
else
    echo -e "${RED}[✗] Cannot find subHawk script at $INSTALL_PATH${NC}"
    exit 1
fi

echo -e "\n${GREEN}[✓] Verification completed!${NC}"
echo -e "${BLUE}[*] Missing optional tools (these enhance functionality but aren't required):${NC}"
if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    echo -e "${YELLOW}    ${MISSING_OPTIONAL[*]}${NC}"
else
    echo -e "${GREEN}    None - all optional tools installed${NC}"
fi

echo -e "\n${GREEN}🎉 subHawk is ready to use!${NC}"
echo -e "${BLUE}Example usage:${NC}"
echo -e "${BLUE}  subhawk -d target.com${NC}"
echo -e "${BLUE}  subhawk -d target.com -w wordlist.txt -t 200${NC}"
