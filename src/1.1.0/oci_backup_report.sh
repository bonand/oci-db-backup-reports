#!/bin/bash

###############################################################################
# OCI Database Backup Report Generator
# Author: OCI Cloud Architect
# Description: Generates tabular reports on OCI database backups with filtering
#              capabilities and automatic Object Storage upload.
#              Supports both TEXT and JSON output formats.
# Requirements: oci-cli, jq, column
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
usage() {
    echo "Usage: $0 <COMPARTMENT_OCID> <START_DATE> <END_DATE> [DB_NAME_LIST] [BUCKET_NAME] [OUTPUT_FORMAT]"
    echo ""
    echo "Parameters:"
    echo "  COMPARTMENT_OCID  : OCID of the OCI compartment to analyze"
    echo "  START_DATE        : Start date (Format: YYYY-MM-DD)"
    echo "  END_DATE          : End date (Format: YYYY-MM-DD)"
    echo "  DB_NAME_LIST      : (Optional) Comma-separated list of database names"
    echo "  BUCKET_NAME       : (Optional) Object Storage bucket name to save the report"
    echo "  OUTPUT_FORMAT     : (Optional) Output format: 'text' (default) or 'json'"
    echo ""
    echo "Examples:"
    echo "  All DBs, text output (default):"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31"
    echo ""
    echo "  Filter specific DBs, text output:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 db1,db2"
    echo ""
    echo "  Save report to Object Storage:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 db1,db2 my-backup-bucket"
    echo ""
    echo "  JSON output for third-party applications:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 db1,db2 '' json"
    echo ""
    echo "  JSON output saved to Object Storage:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 db1,db2 my-backup-bucket json"
    exit 1
}

# Check prerequisites
check_prereqs() {
    if ! command -v oci &> /dev/null; then
        echo -e "${RED}Error: OCI CLI not found. Install oci-cli.${NC}"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq not found. Install jq for JSON parsing.${NC}"
        exit 1
    fi
    if ! command -v column &> /dev/null; then
        echo -e "${RED}Error: column not found. Install bsdmainutils or util-linux.${NC}"
        exit 1
    fi
}

# Validate date format
normalize_date() {
    local input_date=$1
    local time_suffix=$2
    
    if ! [[ $input_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}Error: Invalid date format for '$input_date'. Use YYYY-MM-DD.${NC}"
        exit 1
    fi
    
    echo "${input_date}${time_suffix}"
}

# Validate OCID
validate_ocid() {
    local ocid=$1
    if ! [[ $ocid =~ ^ocid1\.compartment\.oc1\..* ]]; then
        echo -e "${RED}Error: Invalid Compartment OCID.${NC}"
        exit 1
    fi
}

# Convert comma-separated list to bash array
parse_db_list() {
    local input="$1"
    echo "$input" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Get OCI Object Storage namespace
get_namespace() {
    oci os ns get --query 'data' --raw-output 2>/dev/null
}

# Upload file to OCI Object Storage
upload_to_oci_os() {
    local file_path="$1"
    local namespace="$2"
    local bucket_name="$3"
    local object_name="$4"
    local content_type="$5"
    
    echo -e "${BLUE}Uploading report...${NC}"
    
    oci os object put \
        --namespace-name "$namespace" \
        --bucket-name "$bucket_name" \
        --name "$object_name" \
        --file "$file_path" \
        --content-type "$content_type" \
        --force \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Report successfully saved to Object Storage!${NC}"
        echo "  Namespace: $namespace"
        echo "  Bucket: $bucket_name"
        echo "  Object: $object_name"
        echo "  URL: https://objectstorage.${OCI_REGION}.oraclecloud.com/n/$namespace/b/$bucket_name/o/$object_name"
        return 0
    else
        echo -e "${RED}Error during Object Storage upload.${NC}"
        return 1
    fi
}

# Generate JSON report
generate_json_report() {
    local temp_file="$1"
    local comp_ocid="$2"
    local start_date="$3"
    local end_date="$4"
    local db_filter="$5"
    local output_file="$6"
    
    # Build JSON structure
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local backup_count=$(wc -l < "$temp_file" 2>/dev/null || echo "0")
    
    # Create JSON from backup data
    local backups_json="[]"
    if [ -s "$temp_file" ]; then
        backups_json=$(cat "$temp_file" | jq -R -s '
            split("\n") | 
            map(select(length > 0)) | 
            map(split("\t")) | 
            map({
                "date": .[0],
                "db_name": .[1],
                "backup_name": .[2],
                "type": .[3],
                "status": .[4],
                "size_gb": (.[5] | tonumber? // 0)
            })
        ')
    fi
    
    # Build complete JSON report
    jq -n \
        --arg timestamp "$timestamp" \
        --arg compartment "$comp_ocid" \
        --arg start_date "$start_date" \
        --arg end_date "$end_date" \
        --arg db_filter "$db_filter" \
        --argjson backup_count "$backup_count" \
        --argjson backups "$backups_json" \
        '{
            "report": {
                "metadata": {
                    "generated_at": $timestamp,
                    "report_type": "OCI_DATABASE_BACKUP",
                    "version": "1.0.0"
                },
                "filters": {
                    "compartment_ocid": $compartment,
                    "period": {
                        "start_date": $start_date,
                        "end_date": $end_date
                    },
                    "database_filter": (if $db_filter == "" then "all" else $db_filter end)
                },
                "summary": {
                    "total_backups": $backup_count,
                    "total_size_gb": ($backups | map(.size_gb) | add // 0)
                },
                "backups": $backups
            }
        }' > "$output_file"
}

# Generate text report
generate_text_report() {
    local temp_file="$1"
    local comp_ocid="$2"
    local start_date="$3"
    local end_date="$4"
    local db_filter="$5"
    local output_file="$6"
    
    {
        echo "================================================================================"
        echo "                    OCI DATABASE BACKUP REPORT"
        echo "================================================================================"
        echo ""
        echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Compartment: $comp_ocid"
        echo "Period: $start_date to $end_date"
        if [ -n "$db_filter" ]; then
            echo "DB Filter: $db_filter"
        else
            echo "DB Filter: All databases"
        fi
        echo ""
        echo "--------------------------------------------------------------------------------"
        echo "DATE        DB_NAME  BACKUP_NAME       TYPE         STATUS  SIZE_GB"
        echo "----------  -------  ----------------  -----------  ------  --------------  "
        
        if [ -s "$temp_file" ]; then
            column -t -s $'\t' < "$temp_file"
        else
            echo "No backups found in the specified period."
        fi
        
        echo ""
        echo "--------------------------------------------------------------------------------"
        if [ -s "$temp_file" ]; then
            echo "Total backups found: $(wc -l < "$temp_file")"
        else
            echo "Total backups found: 0"
        fi
        echo "================================================================================"
    } > "$output_file"
}

# Main Script
main() {
    check_prereqs

    if [ "$#" -lt 3 ] || [ "$#" -gt 6 ]; then
        usage
    fi

    COMP_OCID=$1
    START_DATE_RAW=$2
    END_DATE_RAW=$3
    FILTER_DB_LIST="${4:-}"      # Optional (comma-separated)
    BUCKET_NAME="${5:-}"         # Optional (bucket name)
    OUTPUT_FORMAT="${6:-text}"   # Optional (text or json)

    # Validate output format
    if [[ "$OUTPUT_FORMAT" != "text" && "$OUTPUT_FORMAT" != "json" ]]; then
        echo -e "${RED}Error: Invalid output format '$OUTPUT_FORMAT'. Use 'text' or 'json'.${NC}"
        exit 1
    fi

    validate_ocid "$COMP_OCID"
    
    # Convert dates for JMESPath filter (ISO8601)
    START_TIME=$(normalize_date "$START_DATE_RAW" "T00:00:00.000Z")
    END_TIME=$(normalize_date "$END_DATE_RAW" "T23:59:59.999Z")

    # Generate report filename based on format
    if [ "$OUTPUT_FORMAT" == "json" ]; then
        REPORT_FILENAME="backup_report_${START_DATE_RAW}_${END_DATE_RAW}.json"
        CONTENT_TYPE="application/json"
    else
        REPORT_FILENAME="backup_report_${START_DATE_RAW}_${END_DATE_RAW}.txt"
        CONTENT_TYPE="text/plain"
    fi
    
    # Get OCI region from config
    OCI_REGION=$(oci config get --profile DEFAULT region 2>/dev/null || echo "unknown")

    echo -e "${GREEN}Generating OCI Backup Report...${NC}"
    echo "Compartment: $COMP_OCID"
    echo "Period: $START_DATE_RAW to $END_DATE_RAW"
    echo -e "Output Format: ${YELLOW}${OUTPUT_FORMAT^^}${NC}"
    if [ -n "$FILTER_DB_LIST" ]; then
        echo -e "DB Filter: ${YELLOW}$FILTER_DB_LIST${NC}"
    fi
    if [ -n "$BUCKET_NAME" ]; then
        echo -e "Bucket OS: ${BLUE}$BUCKET_NAME${NC}"
        echo "Report File: $REPORT_FILENAME"
    fi
    echo ""

    # Database filter management
    declare -a DB_FILTER_ARRAY
    if [ -n "$FILTER_DB_LIST" ]; then
        # Convert comma-separated list to array
        while IFS= read -r db_name; do
            [ -n "$db_name" ] && DB_FILTER_ARRAY+=("$db_name")
        done < <(parse_db_list "$FILTER_DB_LIST")
        
        if [ ${#DB_FILTER_ARRAY[@]} -eq 0 ]; then
            echo -e "${RED}Error: Empty or invalid database list.${NC}"
            exit 1
        fi
    fi

    # Get all Database IDs and names in compartment
    echo "Retrieving database list..."
    DB_LIST=$(oci db database list \
        --compartment-id "$COMP_OCID" \
        --query 'data[*].{id: id, dbName: "db-name"}' \
        --raw-output \
        2>/dev/null)

    if [ -z "$DB_LIST" ] || [ "$DB_LIST" == "[]" ]; then
        echo -e "${YELLOW}No databases found in the specified compartment.${NC}"
        exit 0
    fi

    # Filter by database name if specified
    if [ ${#DB_FILTER_ARRAY[@]} -gt 0 ]; then
        # Pass array as jq argument to avoid quoting issues
        DB_NAMES_JSON=$(printf '%s\n' "${DB_FILTER_ARRAY[@]}" | jq -R . | jq -s .)
        
        DB_OCIDS=$(echo "$DB_LIST" | jq -r --argjson dbnames "$DB_NAMES_JSON" '.[] | select(.dbName as $db | $dbnames | index($db)) | .id')
        
        if [ -z "$DB_OCIDS" ]; then
            echo -e "${RED}Error: No databases found with specified names.${NC}"
            echo "Databases searched: ${DB_FILTER_ARRAY[*]}"
            echo ""
            echo "Available databases in compartment:"
            echo "$DB_LIST" | jq -r '.[].dbName' | while read -r name; do
                echo "  - $name"
            done
            exit 1
        fi
        
        DB_COUNT=$(echo "$DB_OCIDS" | wc -l)
        echo -e "${GREEN}Found $DB_COUNT databases matching filter.${NC}"
    else
        DB_OCIDS=$(echo "$DB_LIST" | jq -r '.[].id')
        DB_COUNT=$(echo "$DB_LIST" | jq 'length')
        echo -e "${GREEN}Found $DB_COUNT databases in compartment.${NC}"
    fi

    # Create temporary files for data
    TEMP_FILE=$(mktemp)
    REPORT_FILE=$(mktemp --suffix=".$OUTPUT_FORMAT")
    trap "rm -f $TEMP_FILE $REPORT_FILE" EXIT

    # Progress counter
    DB_CURRENT=0

    # Iterate over each Database and collect data
    for DB_ID in $DB_OCIDS; do
        
        DB_CURRENT=$((DB_CURRENT + 1))
        echo -ne "\rProcessing database $DB_CURRENT of $DB_COUNT..."

        # JMESPath query with quoted kebab-case fields
        BACKUPS=$(oci db backup list \
            --database-id "$DB_ID" \
            --query "data[?\"time-started\" >= '$START_TIME' && \"time-started\" <= '$END_TIME'].{\"time-started\": \"time-started\", \"display-name\": \"display-name\", \"type\": \"type\", \"lifecycle-state\": \"lifecycle-state\", \"database-size-in-gbs\": \"database-size-in-gbs\"}" \
            --raw-output \
            2>/dev/null)

        if [ "$BACKUPS" != "[]" ] && [ -n "$BACKUPS" ]; then
            # Get Database Name
            DB_NAME=$(oci db database get --database-id "$DB_ID" --query 'data."db-name"' --raw-output 2>/dev/null)
            
            # jq syntax for fields with dashes using .["field-name"]
            # Output tab-separated for both formats (JSON will transform later)
            echo "$BACKUPS" | jq -r --arg dbname "$DB_NAME" '.[] | "\(.["time-started"] | split("T")[0])\t\($dbname[0:20])\t\(.["display-name"][0:25])\t\(.["type"])\t\(.["lifecycle-state"])\t\(.["database-size-in-gbs"])"' 2>/dev/null >> "$TEMP_FILE"
        fi
    done

    echo ""

    # Generate report based on format
    if [ "$OUTPUT_FORMAT" == "json" ]; then
        echo -e "${BLUE}Generating JSON report...${NC}"
        generate_json_report "$TEMP_FILE" "$COMP_OCID" "$START_DATE_RAW" "$END_DATE_RAW" "$FILTER_DB_LIST" "$REPORT_FILE"
    else
        echo -e "${BLUE}Generating text report...${NC}"
        generate_text_report "$TEMP_FILE" "$COMP_OCID" "$START_DATE_RAW" "$END_DATE_RAW" "$FILTER_DB_LIST" "$REPORT_FILE"
    fi

    # Output report to console
    echo ""
    if [ "$OUTPUT_FORMAT" == "json" ]; then
        # Pretty print JSON to console
        jq '.' "$REPORT_FILE"
    else
        cat "$REPORT_FILE"
    fi

    # Upload to Object Storage if bucket specified
    if [ -n "$BUCKET_NAME" ]; then
        echo ""
        echo -e "${BLUE}=== UPLOAD OBJECT STORAGE ===${NC}"
        
        # Get namespace
        NAMESPACE=$(get_namespace)
        
        if [ -z "$NAMESPACE" ]; then
            echo -e "${RED}Error: Unable to retrieve Object Storage namespace.${NC}"
            echo "Verify IAM permissions and OCI CLI configuration."
            exit 1
        fi
        
        echo "OCI Namespace: $NAMESPACE"
        
        # Verify bucket exists
        BUCKET_EXISTS=$(oci os bucket get --namespace-name "$NAMESPACE" --bucket-name "$BUCKET_NAME" --query 'data.name' --raw-output 2>/dev/null)
        
        if [ -z "$BUCKET_EXISTS" ]; then
            echo -e "${RED}Error: Bucket '$BUCKET_NAME' not found in namespace '$NAMESPACE'.${NC}"
            exit 1
        fi
        
        # Upload report
        upload_to_oci_os "$REPORT_FILE" "$NAMESPACE" "$BUCKET_NAME" "$REPORT_FILENAME" "$CONTENT_TYPE"
    fi

    echo ""
    echo -e "${GREEN}Report completed.${NC}"
}

main "$@"
