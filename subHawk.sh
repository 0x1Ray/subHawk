#!/bin/bash

# Enhanced subHawk - Fixed Version
# Professional Subdomain Enumeration Tool with Better Error Handling

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default values
THREADS=100
WORDLIST=""
OUTPUT=""
VERBOSE=false
FAST_MODE=false
DOMAIN=""
FILTER_WILDCARD=true
RESOLVE_IP=true
CHECK_HTTP=true
TIMEOUT=10

# Statistics tracking
TOTAL_FOUND=0
TOTAL_RESOLVED=0
TOTAL_LIVE=0
TOTAL_HTTP=0

show_help() {
    echo -e "${PURPLE}${BOLD}subHawk - Professional Subdomain Enumeration & Validation Tool${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}Usage:${NC}"
    echo "  subhawk -d <domain> [OPTIONS]"
    echo ""
    echo -e "${YELLOW}${BOLD}Options:${NC}"
    echo "  -d, --domain <domain>     Target domain for enumeration"
    echo "  -t, --threads <number>    Number of threads (default: 100)"
    echo "  -w, --wordlist <file>     Custom wordlist for brute force"
    echo "  -f, --fast                Fast mode (limited sources)"
    echo "  -o, --output <file>       Output file (default: <domain>_subhawk.txt)"
    echo "  --timeout <seconds>       Timeout for requests (default: 10)"
    echo "  --no-wildcard-filter      Disable wildcard subdomain filtering"
    echo "  --no-http-check          Skip HTTP/S validation"
    echo "  --no-ip-resolve          Skip IP resolution"
    echo "  -v, --verbose             Verbose output"
    echo "  -h, --help                Show this help message"
    echo ""
    echo -e "${YELLOW}${BOLD}Examples:${NC}"
    echo "  subhawk -d uber.com"
    echo "  subhawk --domain uber.com --threads 200"
    echo "  subhawk -d uber.com -w /path/to/wordlist.txt -o results.txt"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -w|--wordlist)
            WORDLIST="$2"
            shift 2
            ;;
        -f|--fast)
            FAST_MODE=true
            shift
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --no-wildcard-filter)
            FILTER_WILDCARD=false
            shift
            ;;
        --no-http-check)
            CHECK_HTTP=false
            shift
            ;;
        --no-ip-resolve)
            RESOLVE_IP=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate domain
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}[!] Domain is required${NC}"
    show_help
    exit 1
fi

# Set default output if not specified
if [ -z "$OUTPUT" ]; then
    OUTPUT="${DOMAIN}_subhawk_$(date +%Y%m%d_%H%M%S).txt"
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
FINAL_OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$FINAL_OUTPUT_DIR"

# Cleanup function
cleanup() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[*] Cleaning up temporary files...${NC}"
    fi
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

show_banner() {
    echo -e "${PURPLE}"
    echo "    ░██████╗██╗   ██╗██████╗ ██╗  ██╗ █████╗ ██╗    ██╗"
    echo "    ██╔════╝██║   ██║██╔══██╗██║  ██║██╔══██╗██║    ██║"
    echo "    ╚█████╗ ██║   ██║██████╔╝███████║███████║██║ █╗ ██║"
    echo "     ╚═══██╗██║   ██║██╔══██╗██╔══██║██╔══██║██║███╗██║"
    echo "    ██████╔╝╚██████╔╝██████╔╝██║  ██║██║  ██║╚███╔███╔╝"
    echo "    ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ "
    echo -e "${NC}"
    
    echo -e "${CYAN}  ════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Professional Subdomain Enumeration Platform                  ${NC}"
    echo -e "${GREEN}                        Automated Reconnaissance & Validation                    ${NC}"
    echo -e "${CYAN}  ════════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    echo -e "${YELLOW}${BOLD}  TARGET INFORMATION${NC}"
    echo -e "${YELLOW}  ──────────────────${NC}"
    echo -e "${YELLOW}  [+] DOMAIN      : ${DOMAIN}${NC}"
    echo -e "${YELLOW}  [+] THREADS     : ${THREADS}${NC}"
    if [ -n "$WORDLIST" ]; then
        echo -e "${YELLOW}  [+] WORDLIST    : $(basename "$WORDLIST")${NC}"
    fi
    if [ "$FAST_MODE" = true ]; then
        echo -e "${YELLOW}  [+] MODE        : FAST${NC}"
    else
        echo -e "${YELLOW}  [+] MODE        : COMPLETE${NC}"
    fi
    echo -e "${YELLOW}  [+] TIMEOUT     : ${TIMEOUT}s${NC}"
    echo -e "${YELLOW}  [+] OUTPUT      : ${OUTPUT}${NC}"
    echo
}

# Check required tools with better error handling
check_dependencies() {
    echo -e "${BLUE}[*] Verifying required tools...${NC}"
    
    REQUIRED_TOOLS=(dig)
    OPTIONAL_TOOLS=(subfinder dnsx httprobe httpx)
    MISSING_TOOLS=()
    AVAILABLE_TOOLS=()
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            VERSION=$($tool --version 2>/dev/null || $tool -version 2>/dev/null || echo "installed")
            echo -e "${GREEN}[✓]${NC} $tool - ${VERSION:-accessible}"
        else
            echo -e "${RED}[✗]${NC} $tool - NOT FOUND (REQUIRED)"
            MISSING_TOOLS+=("$tool")
        fi
    done
    
    for tool in "${OPTIONAL_TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            VERSION=$($tool --version 2>/dev/null || $tool -version 2>/dev/null || echo "installed")
            echo -e "${GREEN}[✓]${NC} $tool - ${VERSION:-accessible}"
            AVAILABLE_TOOLS+=("$tool")
        else
            echo -e "${YELLOW}[!]${NC} $tool - NOT FOUND (Optional)"
        fi
    done
    
    # If required tools are missing, exit with error
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        echo -e "${RED}[!] Required tools missing: ${MISSING_TOOLS[*]}${NC}"
        echo -e "${YELLOW}[!] Please install the missing tools before running subHawk${NC}"
        exit 1
    fi
    
    # Set available tools
    if [[ " ${AVAILABLE_TOOLS[*]} " =~ " subfinder " ]]; then
        HAS_SUBFINDER=true
    else
        HAS_SUBFINDER=false
    fi
    
    if [[ " ${AVAILABLE_TOOLS[*]} " =~ " dnsx " ]]; then
        HAS_DNSX=true
    else
        HAS_DNSX=false
    fi
    
    if [[ " ${AVAILABLE_TOOLS[*]} " =~ " httprobe " ]]; then
        HAS_HTTPROBE=true
    elif [[ " ${AVAILABLE_TOOLS[*]} " =~ " httpx " ]]; then
        HAS_HTTPX=true
    else
        HAS_HTTPROBE=false
        HAS_HTTPX=false
    fi
}

# Fallback enumeration methods if primary tools aren't available
fallback_enumeration() {
    echo -e "${YELLOW}[*] Using fallback enumeration methods...${NC}"
    
    # Method 1: Certificate transparency logs via crt.sh
    echo -e "${BLUE}[*] Checking certificate transparency logs...${NC}"
    curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" | grep -oE "\"name_value\":\"[^,]*\"" | sed 's/"name_value":"//g' | sed 's/"//g' | sort -u > "$TEMP_DIR/crt_sh.txt" 2>/dev/null
    
    if [ -s "$TEMP_DIR/crt_sh.txt" ]; then
        CRT_COUNT=$(wc -l < "$TEMP_DIR/crt_sh.txt")
        echo -e "${GREEN}[+] crt.sh found $CRT_COUNT subdomains${NC}"
    else
        echo -e "${YELLOW}[!] No subdomains found via crt.sh${NC}"
    fi
    
    # Method 2: HackerTarget API (limited)
    echo -e "${BLUE}[*] Checking HackerTarget API...${NC}"
    curl -s "https://api.hackertarget.com/hostsearch/?q=$DOMAIN" | cut -d',' -f1 | sort -u > "$TEMP_DIR/hackertarget.txt" 2>/dev/null
    
    if [ -s "$TEMP_DIR/hackertarget.txt" ]; then
        HT_COUNT=$(wc -l < "$TEMP_DIR/hackertarget.txt")
        echo -e "${GREEN}[+] HackerTarget found $HT_COUNT subdomains${NC}"
    else
        echo -e "${YELLOW}[!] No subdomains found via HackerTarget${NC}"
    fi
    
    # Method 3: Bufferover.run
    echo -e "${BLUE}[*] Checking Bufferover.run...${NC}"
    curl -s "https://dns.bufferover.run/dns?q=.$DOMAIN" | grep -oE "[a-zA-Z0-9\-\.]*\.$DOMAIN" | sort -u > "$TEMP_DIR/bufferover.txt" 2>/dev/null
    
    if [ -s "$TEMP_DIR/bufferover.txt" ]; then
        BO_COUNT=$(wc -l < "$TEMP_DIR/bufferover.txt")
        echo -e "${GREEN}[+] Bufferover found $BO_COUNT subdomains${NC}"
    else
        echo -e "${YELLOW}[!] No subdomains found via Bufferover${NC}"
    fi
    
    # Combine fallback results
    cat "$TEMP_DIR/crt_sh.txt" "$TEMP_DIR/hackertarget.txt" "$TEMP_DIR/bufferover.txt" 2>/dev/null | sort -u > "$TEMP_DIR/fallback_results.txt"
    FALLBACK_COUNT=$(wc -l < "$TEMP_DIR/fallback_results.txt" 2>/dev/null || echo "0")
    echo -e "${GREEN}[+] Total fallback enumeration found $FALLBACK_COUNT subdomains${NC}"
}

# Passive enumeration with subfinder
run_subfinder() {
    if [ "$HAS_SUBFINDER" = false ]; then
        echo -e "${YELLOW}[!] subfinder not available, using fallback methods${NC}"
        return
    fi
    
    echo -e "${BLUE}[*] Running passive enumeration with subfinder...${NC}"
    
    SUBFINDER_ARGS="-d $DOMAIN -t $THREADS"
    
    if [ "$FAST_MODE" = true ]; then
        SUBFINDER_ARGS="$SUBFINDER_ARGS -silent"
    else
        SUBFINDER_ARGS="$SUBFINDER_ARGS -all -recursive -silent"
    fi
    
    # Run subfinder with error handling
    if subfinder $SUBFINDER_ARGS -o "$TEMP_DIR/subfinder.txt" 2>/dev/null; then
        if [ -s "$TEMP_DIR/subfinder.txt" ]; then
            FOUND_COUNT=$(wc -l < "$TEMP_DIR/subfinder.txt" 2>/dev/null || echo "0")
            echo -e "${GREEN}[+] subfinder found $FOUND_COUNT subdomains${NC}"
        else
            echo -e "${YELLOW}[!] subfinder completed but found 0 subdomains${NC}"
        fi
    else
        echo -e "${RED}[!] subfinder enumeration failed${NC}"
    fi
}

# DNS resolution with fallback methods
resolve_subdomains() {
    echo -e "${BLUE}[*] Resolving subdomains...${NC}"
    
    # Combine all sources
    cat "$TEMP_DIR/subfinder.txt" "$TEMP_DIR/fallback_results.txt" 2>/dev/null | sort -u > "$TEMP_DIR/all_subdomains.txt"
    
    if [ ! -s "$TEMP_DIR/all_subdomains.txt" ]; then
        echo -e "${YELLOW}[!] No subdomains to resolve${NC}"
        
        # Create a basic list with the main domain for testing
        echo "$DOMAIN" > "$TEMP_DIR/all_subdomains.txt"
        echo "www.$DOMAIN" >> "$TEMP_DIR/all_subdomains.txt"
        echo "mail.$DOMAIN" >> "$TEMP_DIR/all_subdomains.txt"
    fi
    
    TOTAL_DISCOVERED=$(wc -l < "$TEMP_DIR/all_subdomains.txt")
    echo -e "${BLUE}[*] Processing $TOTAL_DISCOVERED subdomains...${NC}"
    
    # Use dnsx if available, otherwise fallback to dig
    if [ "$HAS_DNSX" = true ]; then
        echo -e "${BLUE}[*] Using dnsx for DNS resolution...${NC}"
        dnsx -l "$TEMP_DIR/all_subdomains.txt" -silent -o "$TEMP_DIR/resolved.txt" 2>/dev/null
        
        if [ -s "$TEMP_DIR/resolved.txt" ]; then
            RESOLVED_COUNT=$(wc -l < "$TEMP_DIR/resolved.txt")
            echo -e "${GREEN}[+] dnsx resolved $RESOLVED_COUNT subdomains${NC}"
        else
            echo -e "${YELLOW}[!] dnsx found 0 resolved subdomains${NC}"
        fi
    else
        echo -e "${BLUE}[*] Using dig for DNS resolution (fallback)...${NC}"
        
        > "$TEMP_DIR/resolved.txt"  # Clear file
        
        while IFS= read -r subdomain; do
            if [ -n "$subdomain" ]; then
                IP=$(dig +short "$subdomain" 2>/dev/null | head -n 1)
                if [ -n "$IP" ]; then
                    echo "$subdomain" >> "$TEMP_DIR/resolved.txt"
                    if [ "$VERBOSE" = true ]; then
                        echo -e "${GREEN}[+]${NC} $subdomain -> $IP"
                    fi
                elif [ "$VERBOSE" = true ]; then
                    echo -e "${RED}[-]${NC} $subdomain -> No DNS record"
                fi
            fi
        done < "$TEMP_DIR/all_subdomains.txt"
        
        RESOLVED_COUNT=$(wc -l < "$TEMP_DIR/resolved.txt" 2>/dev/null || echo "0")
        echo -e "${GREEN}[+] dig resolved $RESOLVED_COUNT subdomains${NC}"
    fi
    
    TOTAL_RESOLVED=$RESOLVED_COUNT
}

# HTTP/S validation to ensure subdomains are live
validate_http() {
    if [ "$CHECK_HTTP" = false ]; then
        echo -e "${YELLOW}[!] HTTP/S validation disabled${NC}"
        cp "$TEMP_DIR/resolved.txt" "$TEMP_DIR/live_subdomains.txt" 2>/dev/null || touch "$TEMP_DIR/live_subdomains.txt"
        TOTAL_LIVE=$TOTAL_RESOLVED
        TOTAL_HTTP=$TOTAL_RESOLVED
        return
    fi
    
    echo -e "${BLUE}[*] Validating live subdomains with HTTP/S...${NC}"
    
    if [ ! -s "$TEMP_DIR/resolved.txt" ]; then
        echo -e "${YELLOW}[!] No resolved subdomains to validate${NC}"
        
        # Test the main domain as fallback
        echo "$DOMAIN" > "$TEMP_DIR/resolved.txt"
        echo "www.$DOMAIN" >> "$TEMP_DIR/resolved.txt"
    fi
    
    # Use httprobe or httpx if available
    if [ "$HAS_HTTPROBE" = true ]; then
        echo -e "${BLUE}[*] Using httprobe for HTTP validation...${NC}"
        cat "$TEMP_DIR/resolved.txt" | httprobe -t "$((TIMEOUT * 1000))" -c "$THREADS" > "$TEMP_DIR/live_urls.txt" 2>/dev/null
        
        if [ -s "$TEMP_DIR/live_urls.txt" ]; then
            sed 's|^https\?://||' "$TEMP_DIR/live_urls.txt" | sed 's|:.*||' | sort -u > "$TEMP_DIR/live_subdomains.txt"
            LIVE_COUNT=$(wc -l < "$TEMP_DIR/live_subdomains.txt")
            echo -e "${GREEN}[+] httprobe validated $LIVE_COUNT live subdomains${NC}"
        else
            echo -e "${YELLOW}[!] httprobe found 0 live subdomains${NC}"
            touch "$TEMP_DIR/live_subdomains.txt"
        fi
    elif [ "$HAS_HTTPX" = true ]; then
        echo -e "${BLUE}[*] Using httpx for HTTP validation...${NC}"
        httpx -l "$TEMP_DIR/resolved.txt" -silent -threads "$THREADS" -timeout "$TIMEOUT" -o "$TEMP_DIR/live_subdomains.txt" 2>/dev/null
        
        if [ -s "$TEMP_DIR/live_subdomains.txt" ]; then
            LIVE_COUNT=$(wc -l < "$TEMP_DIR/live_subdomains.txt")
            echo -e "${GREEN}[+] httpx validated $LIVE_COUNT live subdomains${NC}"
        else
            echo -e "${YELLOW}[!] httpx found 0 live subdomains${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Neither httprobe nor httpx available, checking basic connectivity...${NC}"
        
        > "$TEMP_DIR/live_subdomains.txt"  # Clear file
        
        # Simple connectivity check with nc or telnet
        while IFS= read -r subdomain; do
            if [ -n "$subdomain" ]; then
                if nc -z -w "$TIMEOUT" "$subdomain" 80 2>/dev/null || nc -z -w "$TIMEOUT" "$subdomain" 443 2>/dev/null; then
                    echo "$subdomain" >> "$TEMP_DIR/live_subdomains.txt"
                    if [ "$VERBOSE" = true ]; then
                        echo -e "${GREEN}[+]${NC} $subdomain -> Live"
                    fi
                elif [ "$VERBOSE" = true ]; then
                    echo -e "${RED}[-]${NC} $subdomain -> Not responding"
                fi
            fi
        done < "$TEMP_DIR/resolved.txt"
        
        LIVE_COUNT=$(wc -l < "$TEMP_DIR/live_subdomains.txt" 2>/dev/null || echo "0")
        echo -e "${GREEN}[+] Basic connectivity check found $LIVE_COUNT live subdomains${NC}"
    fi
    
    TOTAL_LIVE=$(wc -l < "$TEMP_DIR/live_subdomains.txt" 2>/dev/null || echo "0")
    TOTAL_HTTP=$TOTAL_LIVE
}

# If wordlist is provided, perform brute force
run_bruteforce() {
    if [ -n "$WORDLIST" ] && [ -f "$WORDLIST" ]; then
        echo -e "${BLUE}[*] Performing wordlist brute force enumeration...${NC}"
        
        if [ "$HAS_DNSX" = true ]; then
            dnsx -d "$DOMAIN" -w "$WORDLIST" -t "$THREADS" -silent -o "$TEMP_DIR/brute_force.txt" 2>/dev/null
            BRUTE_COUNT=$(wc -l < "$TEMP_DIR/brute_force.txt" 2>/dev/null || echo "0")
            echo -e "${GREEN}[+] Brute force found $BRUTE_COUNT subdomains${NC}"
        else
            echo -e "${YELLOW}[!] dnsx not available for brute force${NC}"
        fi
    fi
}

# Create professional report
create_professional_report() {
    echo -e "${BLUE}[*] Generating professional report...${NC}"
    
    # Combine all valid results
    cat "$TEMP_DIR/live_subdomains.txt" "$TEMP_DIR/brute_force.txt" 2>/dev/null | sort -u > "$TEMP_DIR/final_results.txt"
    
    TOTAL_FOUND=$(wc -l < "$TEMP_DIR/final_results.txt" 2>/dev/null || echo "0")
    
    if [ "$TOTAL_FOUND" -eq 0 ]; then
        echo -e "${YELLOW}[!] No subdomains found - creating minimal report${NC}"
        {
            echo "=================================================================="
            echo "                    SUBHAWK ENUMERATION REPORT                    "
            echo "=================================================================="
            echo "Target Domain    : $DOMAIN"
            echo "Scan Date        : $(date)"
            echo "Scan Mode        : $([ "$FAST_MODE" = true ] && echo "FAST" || echo "COMPLETE")"
            echo "Status           : NO SUBDOMAINS FOUND"
            echo "=================================================================="
            echo ""
            echo "RESULT:"
            echo "-------"
            echo "No valid subdomains were discovered during this enumeration."
            echo ""
            echo "Additional Info:"
            echo "- Check if the domain is accessible publicly"
            echo "- Try using different enumeration sources"
            echo "- Consider manual verification of the domain"
        } > "$OUTPUT"
        return
    fi
    
    # Create professional header
    {
        echo "=================================================================="
        echo "                    SUBHAWK ENUMERATION REPORT                    "
        echo "=================================================================="
        echo "Target Domain    : $DOMAIN"
        echo "Scan Date        : $(date)"
        echo "Scan Mode        : $([ "$FAST_MODE" = true ] && echo "FAST" || echo "COMPLETE")"
        echo "Threads Used     : $THREADS"
        echo "Timeout          : ${TIMEOUT}s"
        echo "HTTP Validation  : $([ "$CHECK_HTTP" = true ] && echo "ENABLED" || echo "DISABLED")"
        echo "=================================================================="
        echo ""
        echo "SUMMARY STATISTICS:"
        echo "------------------"
        echo "Total Discovered : $TOTAL_DISCOVERED"
        echo "DNS Resolved     : $TOTAL_RESOLVED"
        echo "HTTP/S Live      : $TOTAL_HTTP"
        echo "Final Results    : $TOTAL_FOUND"
        echo ""
        echo "VALIDATED SUBDOMAINS:"
        echo "---------------------"
    } > "$OUTPUT"
    
    # Add subdomains to output file with IPs if enabled
    if [ "$RESOLVE_IP" = true ]; then
        while IFS= read -r subdomain; do
            if [ -n "$subdomain" ]; then
                IP=$(dig +short "$subdomain" 2>/dev/null | head -n 1)
                if [ -n "$IP" ]; then
                    echo "$subdomain [$IP]" >> "$OUTPUT"
                else
                    echo "$subdomain [No DNS record]" >> "$OUTPUT"
                fi
            fi
        done < "$TEMP_DIR/final_results.txt"
    else
        cat "$TEMP_DIR/final_results.txt" >> "$OUTPUT"
    fi
    
    echo "" >> "$OUTPUT"
    echo "==================================================================" >> "$OUTPUT"
    echo "Report Generated by subHawk - Professional Subdomain Enumeration" >> "$OUTPUT"
    echo "==================================================================" >> "$OUTPUT"
    
    echo -e "${GREEN}[+] Professional report saved to: $OUTPUT${NC}"
}

# Display final results
show_results() {
    echo -e "${CYAN}"
    echo "  ════════════════════════════════════════════════════════════════════════════════"
    echo -e "${BOLD}                            ENUMERATION COMPLETE                              ${NC}${CYAN}"
    echo "  ════════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    
    echo -e "${YELLOW}${BOLD}FINAL RESULTS:${NC}"
    echo -e "${YELLOW}──────────────${NC}"
    echo -e "${GREEN}[+] Total Discovered          : $TOTAL_DISCOVERED${NC}"
    echo -e "${GREEN}[+] DNS Resolved Subdomains   : $TOTAL_RESOLVED${NC}"
    echo -e "${GREEN}[+] HTTP/S Live Subdomains    : $TOTAL_HTTP${NC}"
    echo -e "${GREEN}[+] Final Valid Results       : $TOTAL_FOUND${NC}"
    echo -e "${GREEN}[+] Report Saved To           : $OUTPUT${NC}"
    echo
    
    if [ "$VERBOSE" = true ] && [ "$TOTAL_FOUND" -gt 0 ]; then
        echo -e "${BLUE}[*] Sample results:${NC}"
        head -n 10 "$TEMP_DIR/final_results.txt" | while IFS= read -r subdomain; do
            if [ -n "$subdomain" ]; then
                echo -e "${CYAN}    ▶ ${subdomain}${NC}"
            fi
        done
        echo
    fi
    
    echo -e "${PURPLE}${BOLD}                    HAPPY HUNTING ;)                         ${NC}"
    echo -e "${CYAN}  ════════════════════════════════════════════════════════════════════════════════${NC}"
}

# Main execution
main() {
    show_banner
    check_dependencies
    
    # Always try fallback enumeration methods
    fallback_enumeration
    run_subfinder
    resolve_subdomains
    validate_http
    run_bruteforce
    create_professional_report
    show_results
}

# Run main function
main
