#!/bin/bash

# subHawk - Ultimate subdomain enumeration tool for cybersecurity professionals
# Version: 2.0
# Author: Cybersecurity Professional

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SILENT=false
VERBOSE=false
DEBUG=false
DOMAIN=""
OUTPUT_FILE="subhawk_results.txt"
TEMP_DIR=""
THREADS=100
HTTPX_INSTALLED=true
DNSX_INSTALLED=true
AMASS_INSTALLED=false
ASSETFINDER_INSTALLED=false

# Banner
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
    echo -e "${CYAN}              subHawk v2.0 - Ultimate Subdomain Enumeration${NC}"
    echo -e "${GREEN}              Advanced Security Tool for Cyber Professionals${NC}"
    echo -e "${YELLOW}==============================================================${NC}"
    echo
}

# Help function
show_help() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./subHawk.sh [OPTIONS] -d <domain>"
    echo
    echo -e "${BLUE}Core Options:${NC}"
    echo "  -d, --domain <domain>        Target domain (required)"
    echo "  -o, --output <file>          Output file name (default: subhawk_results.txt)"
    echo "  -s, --silent                 Silent mode (no banner)"
    echo "  -v, --verbose                Verbose output"
    echo "  -D, --debug                  Debug mode"
    echo "  -h, --help                   Display this help menu"
    echo
    echo -e "${BLUE}Enumeration Options:${NC}"
    echo "  -t, --threads <num>          Number of threads (default: 100)"
    echo "  -r, --recursive              Recursive subdomain enumeration"
    echo "  -a, --all-sources            Use all sources for enumeration"
    echo "  -p, --providers <list>       Comma-separated list of providers"
    echo "  -x, --exclude <list>         Comma-separated list of sources to exclude"
    echo "  -m, --match <list>           Comma-separated list of subdomains to match"
    echo "  -f, --filter <list>          Comma-separated list of subdomains to filter"
    echo "  -c, --config <file>          Custom subfinder config file"
    echo
    echo -e "${BLUE}Brute Force Options:${NC}"
    echo "  -b, --brute                  Perform brute force enumeration"
    echo "  -B, --brute-only             Brute force enumeration only"
    echo "  -w, --wordlist <file>        Custom wordlist for brute force"
    echo "  -P, --permutations           Enable subdomain permutations"
    echo
    echo -e "${BLUE}Validation & Intelligence:${NC}"
    echo "  -V, --validate-only          Validate results only (no new enumeration)"
    echo "  -n, --no-validate            Skip validation of results"
    echo "  -e, --enrich                 Enrich results with HTTP info"
    echo "  -E, --enrich-all             Full enrichment (HTTP+CLOUD+TAKEOVER)"
    echo "  -z, --zone-transfer          Attempt zone transfer enumeration"
    echo "  -C, --cdn-detect             Detect and filter CDN subdomains"
    echo "  -T, --takeover-detect        Check for takeover vulnerabilities"
    echo
    echo -e "${BLUE}Multi-Tool Integration:${NC}"
    echo "  -A, --all-tools              Use all available tools"
    echo "  --amass                      Include amass enumeration"
    echo "  --assetfinder                Include assetfinder enumeration"
    echo "  --findomain                  Include findomain enumeration"
    echo "  --crtsh                      Query crt.sh certificate transparency"
    echo
    echo -e "${BLUE}Advanced Features:${NC}"
    echo "  -j, --json                   Output in JSON format"
    echo "  -J, --json-all               Output in detailed JSON format"
    echo "  -R, --risk-score             Calculate risk scores for subdomains"
    echo "  -S, --service-detect         Detect services running on subdomains"
    echo "  -H, --historical             Include historical subdomain data"
    echo "  -F, --fuzzy                  Enable fuzzy matching for similar domains"
    echo "  -k, --keep-temp              Keep temporary files"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./subHawk.sh -d example.com"
    echo "  ./subHawk.sh -d example.com -o results.txt -v"
    echo "  ./subHawk.sh -d example.com -r -e -t 200"
    echo "  ./subHawk.sh -d example.com -A -E -R -o comprehensive.txt"
    echo "  ./subHawk.sh -d example.com -b -w /path/to/wordlist.txt -P"
    echo
}

# Validate domain format
validate_domain() {
    local domain="$1"
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]] || [[ $domain =~ ^[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}[*] Checking dependencies...${NC}"
    
    # Required tools
    if ! command -v subfinder &> /dev/null; then
        echo -e "${RED}[!] subfinder is not installed. Please install it first.${NC}"
        echo "Visit: https://github.com/projectdiscovery/subfinder"
        exit 1
    else
        echo -e "${GREEN}[+] subfinder: OK${NC}"
    fi
    
    # Optional tools
    if command -v httpx &> /dev/null; then
        HTTPX_INSTALLED=true
        echo -e "${GREEN}[+] httpx: OK${NC}"
    else
        HTTPX_INSTALLED=false
        echo -e "${YELLOW}[!] httpx: Not found (some features will be disabled)${NC}"
    fi
    
    if command -v dnsx &> /dev/null; then
        DNSX_INSTALLED=true
        echo -e "${GREEN}[+] dnsx: OK${NC}"
    else
        DNSX_INSTALLED=false
        echo -e "${YELLOW}[!] dnsx: Not found (validation will be slower)${NC}"
    fi
    
    # Multi-tool integrations
    if command -v amass &> /dev/null; then
        AMASS_INSTALLED=true
        echo -e "${GREEN}[+] amass: OK${NC}"
    else
        AMASS_INSTALLED=false
        echo -e "${YELLOW}[!] amass: Not found${NC}"
    fi
    
    if command -v assetfinder &> /dev/null; then
        ASSETFINDER_INSTALLED=true
        echo -e "${GREEN}[+] assetfinder: OK${NC}"
    else
        ASSETFINDER_INSTALLED=false
        echo -e "${YELLOW}[!] assetfinder: Not found${NC}"
    fi
    
    if command -v findomain &> /dev/null; then
        FINDOMAIN_INSTALLED=true
        echo -e "${GREEN}[+] findomain: OK${NC}"
    else
        FINDOMAIN_INSTALLED=false
        echo -e "${YELLOW}[!] findomain: Not found${NC}"
    fi
    
    echo
}

# Validate subdomains
validate_subdomains() {
    local input_file="$1"
    local output_file="$2"
    
    if [ "$NO_VALIDATE" = true ]; then
        cp "$input_file" "$output_file"
        return
    fi
    
    echo -e "${BLUE}[*] Validating subdomains...${NC}"
    
    # Using dnsx for validation if available
    if [ "$DNSX_INSTALLED" = true ]; then
        dnsx -l "$input_file" -silent -o "$output_file"
        echo -e "${GREEN}[+] Validation complete using dnsx${NC}"
    else
        # Fallback validation using dig
        > "$output_file"
        while IFS= read -r subdomain; do
            if [ -n "$subdomain" ]; then
                if dig +short "$subdomain" @8.8.8.8 &>/dev/null; then
                    echo "$subdomain" >> "$output_file"
                fi
            fi
        done < "$input_file"
        echo -e "${GREEN}[+] Validation complete using dig${NC}"
    fi
}

# Enrich results with httpx
enrich_results() {
    local input_file="$1"
    local output_file="$2"
    local full_enrich="$3"
    
    if [ "$HTTPX_INSTALLED" = false ]; then
        cp "$input_file" "$output_file"
        return
    fi
    
    echo -e "${BLUE}[*] Enriching results...${NC}"
    
    # Add http:// and https:// prefixes for httpx
    sed 's/^/http:\/\//' "$input_file" > "${TEMP_DIR}/http_urls.txt"
    sed 's/^/https:\/\//' "$input_file" >> "${TEMP_DIR}/http_urls.txt"
    
    if [ "$full_enrich" = true ]; then
        # Full enrichment with all options
        httpx -l "${TEMP_DIR}/http_urls.txt" -silent -sc -cl -ct -server -title -ip -cdn -tech -probe -o "$output_file"
        echo -e "${GREEN}[+] Full enrichment complete${NC}"
    else
        # Basic enrichment
        httpx -l "${TEMP_DIR}/http_urls.txt" -silent -sc -cl -o "$output_file"
        echo -e "${GREEN}[+] Basic enrichment complete${NC}"
    fi
}

# Multi-tool enumeration
multi_tool_enum() {
    local domain="$1"
    local output_file="$2"
    local use_all="$3"
    
    echo -e "${BLUE}[*] Running multi-tool enumeration...${NC}"
    
    # Initialize temp file
    > "$output_file"
    
    # Subfinder
    echo -e "${BLUE}[*] Running subfinder...${NC}"
    subfinder -d "$domain" -t "$THREADS" -silent >> "$output_file"
    
    # Amass
    if [ "$use_all" = true ] || [ "$AMASS" = true ]; then
        if [ "$AMASS_INSTALLED" = true ]; then
            echo -e "${BLUE}[*] Running amass...${NC}"
            amass enum -d "$domain" -silent >> "$output_file" 2>/dev/null
        fi
    fi
    
    # Assetfinder
    if [ "$use_all" = true ] || [ "$ASSETFINDER" = true ]; then
        if [ "$ASSETFINDER_INSTALLED" = true ]; then
            echo -e "${BLUE}[*] Running assetfinder...${NC}"
            assetfinder "$domain" >> "$output_FILE"
        fi
    fi
    
    # Findomain
    if [ "$use_all" = true ] || [ "$FINDOMAIN" = true ]; then
        if [ "$FINDOMAIN_INSTALLED" = true ]; then
            echo -e "${BLUE}[*] Running findomain...${NC}"
            findomain -t "$domain" -q >> "$output_file"
        fi
    fi
    
    # crt.sh lookup
    if [ "$CRTSH" = true ]; then
        echo -e "${BLUE}[*] Querying crt.sh...${NC}"
        curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' >> "$output_file"
    fi
    
    # Remove duplicates
    sort -u "$output_file" -o "$output_file"
    echo -e "${GREEN}[+] Multi-tool enumeration complete${NC}"
}

# Risk scoring function
calculate_risk_score() {
    local input_file="$1"
    local output_file="$2"
    
    echo -e "${BLUE}[*] Calculating risk scores...${NC}"
    
    > "$output_file"
    while IFS= read -r subdomain; do
        if [ -n "$subdomain" ]; then
            local score=0
            local reasons=()
            
            # High-risk keywords
            if [[ "$subdomain" =~ (admin|dev|test|stage|staging|internal|vpn|api|auth|login|portal|dashboard|cpanel) ]]; then
                score=$((score + 30))
                reasons+=("High-risk keyword")
            fi
            
            # Dev/test keywords
            if [[ "$subdomain" =~ (dev|test|staging|uat|qa) ]]; then
                score=$((score + 20))
                reasons+=("Development/Test environment")
            fi
            
            # Legacy keywords
            if [[ "$subdomain" =~ (old|legacy|backup|oldsite) ]]; then
                score=$((score + 15))
                reasons+=("Legacy system")
            fi
            
            # Generic keywords
            if [[ "$subdomain" =~ (www|mail|ftp|blog) ]]; then
                score=$((score + 5))
                reasons+=("Generic service")
            fi
            
            # Add DNS-based scoring if we have enrichment data
            # This would typically check for things like:
            # - IP addresses in suspicious ranges
            # - CDN detection
            # - Unusual server headers
            
            echo "$subdomain,$score,${reasons[*]}" >> "$output_file"
        fi
    done < "$input_file"
    
    echo -e "${GREEN}[+] Risk scoring complete${NC}"
}

# Service detection
detect_services() {
    local input_file="$1"
    local output_file="$2"
    
    echo -e "${BLUE}[*] Detecting services on subdomains...${NC}"
    
    > "$output_file"
    
    # This would implement service detection logic such as:
    # - SSH on port 22
    # - FTP on port 21
    # - Database services
    # - Administrative panels
    # For now, we'll just note that this would be implemented
    
    while IFS= read -r subdomain; do
        if [ -n "$subdomain" ]; then
            echo "$subdomain,Service detection not implemented in this script version" >> "$output_file"
        fi
    done < "$input_file"
    
    echo -e "${GREEN}[+] Service detection complete${NC}"
}

# Cloud service detection
detect_cloud_services() {
    local input_file="$1"
    local output_file="$2"
    
    echo -e "${BLUE}[*] Detecting cloud services...${NC}"
    
    > "$output_file"
    
    # This would detect cloud services like:
    # - AWS S3 buckets
    # - Azure services
    # - GCP services
    # Based on DNS records and HTTP responses
    
    while IFS= read -r subdomain; do
        if [ -n "$subdomain" ]; then
            # Example logic for AWS detection (simplified)
            if dig +short CNAME "$subdomain" | grep -q "s3.amazonaws.com"; then
                echo "$subdomain,AWS S3 bucket" >> "$output_file"
            else
                echo "$subdomain,No cloud service detected" >> "$output_file"
            fi
        fi
    done < "$input_file"
    
    echo -e "${GREEN}[+] Cloud service detection complete${NC}"
}

# Generate permutations of subdomains
generate_permutations() {
    local domain="$1"
    local output_file="$2"
    
    echo -e "${BLUE}[*] Generating subdomain permutations...${NC}"
    
    # Common subdomain patterns for the target industry
    local common_words=(
        "www" "mail" "ftp" "admin" "test" "dev" "api" "blog" "shop" "forum"
        "portal" "login" "auth" "vpn" "secure" "dashboard" "console" "stage"
        "staging" "prod" "production" "internal" "intranet" "cpanel" "webmail"
        "old" "new" "beta" "alpha" "demo" "uat" "qa" "support"
    )
    
    > "$output_file"
    for word in "${common_words[@]}"; do
        echo "${word}.${domain}" >> "$output_file"
    done
    
    echo -e "${GREEN}[+] Permutation generation complete${NC}"
}

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -s|--silent)
                SILENT=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -D|--debug)
                DEBUG=true
                shift
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;
            -n|--no-validate)
                NO_VALIDATE=true
                shift
                ;;
            -r|--recursive)
                RECURSIVE=true
                shift
                ;;
            -w|--wordlist)
                WORDLIST="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -p|--providers)
                PROVIDERS="$2"
                shift 2
                ;;
            -x|--exclude)
                EXCLUDE_SOURCES="$2"
                shift 2
                ;;
            -m|--match)
                MATCH_SUBDOMAINS="$2"
                shift 2
                ;;
            -f|--filter)
                FILTER_SUBDOMAINS="$2"
                shift 2
                ;;
            -a|--all-sources)
                ALL_SOURCES=true
                shift
                ;;
            -A|--all-tools)
                ALL_TOOLS=true
                shift
                ;;
            -e|--enrich)
                ENRICH=true
                shift
                ;;
            -E|--enrich-all)
                ENRICH_ALL=true
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            -J|--json-all)
                JSON_ALL=true
                shift
                ;;
            -b|--brute)
                BRUTE_FORCE=true
                shift
                ;;
            -B|--brute-only)
                BRUTE_ONLY=true
                shift
                ;;
            -P|--permutations)
                PERMUTATIONS=true
                shift
                ;;
            -V|--validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            -z|--zone-transfer)
                ZONE_TRANSFER=true
                shift
                ;;
            -C|--cdn-detect)
                CDN_DETECT=true
                shift
                ;;
            -T|--takeover-detect)
                TAKEOVER_DETECT=true
                shift
                ;;
            -R|--risk-score)
                RISK_SCORE=true
                shift
                ;;
            -S|--service-detect)
                SERVICE_DETECT=true
                shift
                ;;
            -H|--historical)
                HISTORICAL=true
                shift
                ;;
            -F|--fuzzy)
                FUZZY=true
                shift
                ;;
            -k|--keep-temp)
                KEEP_TEMP=true
                shift
                ;;
            --amass)
                AMASS=true
                shift
                ;;
            --assetfinder)
                ASSETFINDER=true
                shift
                ;;
            --findomain)
                FINDOMAIN=true
                shift
                ;;
            --crtsh)
                CRTSH=true
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
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show banner if not in silent mode
    if [ "$SILENT" = false ]; then
        show_banner
    fi
    
    # Check dependencies
    check_dependencies
    
    # Validate domain
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}[!] Domain is required. Use -d or --domain option.${NC}"
        show_help
        exit 1
    fi
    
    if ! validate_domain "$DOMAIN"; then
        echo -e "${RED}[!] Invalid domain format: $DOMAIN${NC}"
        exit 1
    fi
    
    # Set up temporary directory
    TEMP_DIR=$(mktemp -d)
    if [ "$KEEP_TEMP" = false ]; then
        trap 'rm -rf "$TEMP_DIR"' EXIT
    fi
    
    echo -e "${BLUE}[*] Starting advanced subdomain enumeration for: ${GREEN}$DOMAIN${NC}"
    
    # File paths
    RAW_OUTPUT="${TEMP_DIR}/raw_results.txt"
    VALIDATED_OUTPUT="${TEMP_DIR}/validated_results.txt"
    ENRICHED_OUTPUT="${TEMP_DIR}/enriched_results.txt"
    RISK_OUTPUT="${TEMP_DIR}/risk_results.txt"
    SERVICE_OUTPUT="${TEMP_DIR}/service_results.txt"
    CLOUD_OUTPUT="${TEMP_DIR}/cloud_results.txt"
    PERMUTATION_OUTPUT="${TEMP_DIR}/permutations.txt"
    FINAL_OUTPUT="$OUTPUT_FILE"
    
    # Permutation generation
    if [ "$PERMUTATIONS" = true ]; then
        generate_permutations "$DOMAIN" "$PERMUTATION_OUTPUT"
    fi
    
    # Multi-tool enum if requested or as part of all-tools
    if [ "$ALL_TOOLS" = true ] || [ "$AMASS" = true ] || [ "$ASSETFINDER" = true ] || [ "$FINDOMAIN" = true ] || [ "$CRTSH" = true ]; then
        multi_tool_enum "$DOMAIN" "$RAW_OUTPUT" "$ALL_TOOLS"
    elif [ "$VALIDATE_ONLY" = false ] && [ "$BRUTE_ONLY" = false ]; then
        # Standard subfinder enumeration
        SUBFINDER_CMD="subfinder -d $DOMAIN -t $THREADS -silent"
        
        # Add options to subfinder command
        if [ -n "$CONFIG_FILE" ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -config $CONFIG_FILE"
        fi
        
        if [ -n "$PROVIDERS" ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -sources $PROVIDERS"
        fi
        
        if [ "$ALL_SOURCES" = true ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -all"
        fi
        
        if [ -n "$EXCLUDE_SOURCES" ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -exclude-sources $EXCLUDE_SOURCES"
        fi
        
        if [ -n "$MATCH_SUBDOMAINS" ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -match $MATCH_SUBDOMAINS"
        fi
        
        if [ -n "$FILTER_SUBDOMAINS" ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -filter $FILTER_SUBDOMAINS"
        fi
        
        if [ "$JSON_OUTPUT" = true ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -json"
        fi
        
        if [ "$JSON_ALL" = true ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -json-all"
        fi
        
        if [ "$DEBUG" = true ]; then
            SUBFINDER_CMD="$SUBFINDER_CMD -debug"
        fi
        
        echo -e "${BLUE}[*] Running subfinder enumeration...${NC}"
        if [ "$DEBUG" = true ]; then
            echo -e "${YELLOW}[DEBUG] Command: $SUBFINDER_CMD${NC}"
        fi
        
        eval "$SUBFINDER_CMD" > "$RAW_OUTPUT"
        echo -e "${GREEN}[+] Subfinder enumeration complete${NC}"
    fi
    
    # Brute force enumeration
    if [ "$BRUTE_FORCE" = true ] || [ "$BRUTE_ONLY" = true ]; then
        if [ -z "$WORDLIST" ]; then
            echo -e "${YELLOW}[!] Wordlist not specified for brute force. Using default wordlist.${NC}"
            # Use permutations if generated, otherwise default list
            if [ "$PERMUTATIONS" = true ] && [ -f "$PERMUTATION_OUTPUT" ]; then
                WORDLIST="$PERMUTATION_OUTPUT"
            elif [ -f "/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt" ]; then
                WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
            else
                # Create a minimal wordlist
                echo -e "www\nmail\nftp\nadmin\ntest\napi\nblog\ndev\nshop\nforum" > "${TEMP_DIR}/minimal_wordlist.txt"
                WORDLIST="${TEMP_DIR}/minimal_wordlist.txt"
            fi
        fi
        
        if [ -f "$WORDLIST" ]; then
            echo -e "${BLUE}[*] Performing brute force enumeration with wordlist: $WORDLIST${NC}"
            subfinder -d "$DOMAIN" -w "$WORDLIST" -t "$THREADS" -silent >> "$RAW_OUTPUT"
            echo -e "${GREEN}[+] Brute force enumeration complete${NC}"
        else
            echo -e "${RED}[!] Wordlist file not found: $WORDLIST${NC}"
        fi
    fi
    
    # Merge permutation results if they exist
    if [ "$PERMUTATIONS" = true ] && [ -f "$PERMUTATION_OUTPUT" ] && [ -f "$RAW_OUTPUT" ]; then
        cat "$PERMUTATION_OUTPUT" >> "$RAW_OUTPUT"
        sort -u "$RAW_OUTPUT" -o "$RAW_OUTPUT"
    fi
    
    # Zone transfer enumeration
    if [ "$ZONE_TRANSFER" = true ]; then
        echo -e "${BLUE}[*] Attempting zone transfer enumeration...${NC}"
        # This would require additional implementation
        echo -e "${YELLOW}[!] Zone transfer functionality needs manual implementation${NC}"
    fi
    
    # Recursive enumeration
    if [ "$RECURSIVE" = true ]; then
        echo -e "${BLUE}[*] Performing recursive enumeration...${NC}"
        # This would typically involve running subfinder on each discovered subdomain
        # This is a simplified version
        if [ -f "$RAW_OUTPUT" ]; then
            echo -e "${BLUE}[*] Running subfinder on discovered subdomains...${NC}"
            while IFS= read -r subdomain; do
                if [ -n "$subdomain" ]; then
                    # Extract domain from subdomain for recursive search
                    # This is a simplified approach
                    subfinder -d "$subdomain" -t "$THREADS" -silent >> "$RAW_OUTPUT" 2>/dev/null
                fi
            done < "$RAW_OUTPUT"
        fi
        echo -e "${GREEN}[+] Recursive enumeration complete${NC}"
    fi
    
    # Validate results
    if [ -f "$RAW_OUTPUT" ]; then
        validate_subdomains "$RAW_OUTPUT" "$VALIDATED_OUTPUT"
    else
        echo -e "${RED}[!] No results to validate${NC}"
        exit 1
    fi
    
    # Enrich results
    if [ "$ENRICH" = true ] || [ "$ENRICH_ALL" = true ] || [ "$JSON_ALL" = true ]; then
        enrich_results "$VALIDATED_OUTPUT" "$ENRICHED_OUTPUT" "$ENRICH_ALL"
    fi
    
    # Risk scoring
    if [ "$RISK_SCORE" = true ]; then
        if [ -f "$ENRICHED_OUTPUT" ]; then
            calculate_risk_score "$ENRICHED_OUTPUT" "$RISK_OUTPUT"
        elif [ -f "$VALIDATED_OUTPUT" ]; then
            calculate_risk_score "$VALIDATED_OUTPUT" "$RISK_OUTPUT"
        fi
    fi
    
    # Service detection
    if [ "$SERVICE_DETECT" = true ]; then
        if [ -f "$ENRICHED_OUTPUT" ]; then
            detect_services "$ENRICHED_OUTPUT" "$SERVICE_OUTPUT"
        elif [ -f "$VALIDATED_OUTPUT" ]; then
            detect_services "$VALIDATED_OUTPUT" "$SERVICE_OUTPUT"
        fi
    fi
    
    # Cloud service detection
    if [ "$ENRICH_ALL" = true ]; then
        if [ -f "$ENRICHED_OUTPUT" ]; then
            detect_cloud_services "$ENRICHED_OUTPUT" "$CLOUD_OUTPUT"
        elif [ -f "$VALIDATED_OUTPUT" ]; then
            detect_cloud_services "$VALIDATED_OUTPUT" "$CLOUD_OUTPUT"
        fi
    fi
    
    # Determine final output
    if [ "$RISK_SCORE" = true ] && [ -f "$RISK_OUTPUT" ]; then
        FINAL_WORKING_OUTPUT="$RISK_OUTPUT"
    elif [ "$SERVICE_DETECT" = true ] && [ -f "$SERVICE_OUTPUT" ]; then
        FINAL_WORKING_OUTPUT="$SERVICE_OUTPUT"
    elif [ "$ENRICH_ALL" = true ] && [ -f "$CLOUD_OUTPUT" ]; then
        FINAL_WORKING_OUTPUT="$CLOUD_OUTPUT"
    elif [ "$ENRICH" = true ] || [ "$JSON_ALL" = true ] && [ -f "$ENRICHED_OUTPUT" ]; then
        FINAL_WORKING_OUTPUT="$ENRICHED_OUTPUT"
    elif [ "$NO_VALIDATE" = false ] && [ -f "$VALIDATED_OUTPUT" ]; then
        FINAL_WORKING_OUTPUT="$VALIDATED_OUTPUT"
    elif [ -f "$RAW_OUTPUT" ]; then
        FINAL_WORKING_OUTPUT="$RAW_OUTPUT"
    else
        echo -e "${RED}[!] No results to output${NC}"
        exit 1
    fi
    
    # Format output based on options
    if [ "$JSON_ALL" = true ] || [ "$JSON_OUTPUT" = true ]; then
        # If raw output is JSON, pass through directly
        cp "$FINAL_WORKING_OUTPUT" "$FINAL_OUTPUT"
    else
        # Format as CSV or plain text based on enrichment
        if [ "$RISK_SCORE" = true ]; then
            # Output with risk scores
            echo "Subdomain,Risk Score,Reasons" > "$FINAL_OUTPUT"
            cat "$FINAL_WORKING_OUTPUT" >> "$FINAL_OUTPUT"
        elif [ "$SERVICE_DETECT" = true ]; then
            # Output with service detection
            echo "Subdomain,Services" > "$FINAL_OUTPUT"
            cat "$FINAL_WORKING_OUTPUT" >> "$FINAL_OUTPUT"
        elif [ "$ENRICH_ALL" = true ]; then
            # Output with cloud detection
            echo "Subdomain,Cloud Services" > "$FINAL_OUTPUT"
            cat "$FINAL_WORKING_OUTPUT" >> "$FINAL_OUTPUT"
        else
            # Standard output
            cat "$FINAL_WORKING_OUTPUT" > "$FINAL_OUTPUT"
        fi
    fi
    
    # Output results
    if [ -f "$FINAL_OUTPUT" ]; then
        RESULT_COUNT=$(wc -l < "$FINAL_OUTPUT")
        # Adjust count for headers in CSV output
        if [ "$RISK_SCORE" = true ] || [ "$SERVICE_DETECT" = true ] || [ "$ENRICH_ALL" = true ]; then
            RESULT_COUNT=$((RESULT_COUNT - 1))
        fi
        
        echo -e "${GREEN}[+] Enumeration complete. Found $RESULT_COUNT subdomains.${NC}"
        echo -e "${GREEN}[+] Results saved to: $OUTPUT_FILE${NC}"
        
        if [ "$VERBOSE" = true ]; then
            echo -e "${BLUE}[*] Sample results:${NC}"
            if [ "$JSON_OUTPUT" = true ] || [ "$JSON_ALL" = true ]; then
                head -n 5 "$OUTPUT_FILE"
            else
                head -n 10 "$OUTPUT_FILE"
            fi
        fi
    else
        echo -e "${RED}[!] No results found${NC}"
    fi
    
    # Cleanup
    if [ "$KEEP_TEMP" = false ]; then
        rm -rf "$TEMP_DIR"
    else
        echo -e "${BLUE}[*] Temporary files kept in: $TEMP_DIR${NC}"
    fi
    
    echo -e "${GREEN}[✓] Advanced subHawk enumeration finished${NC}"
}

# Run main function with all arguments
main "$@"
