#!/bin/bash

###############################################################################
# OCI Database Backup Report Generator
# Autore: OCI Cloud Architect
# Descrizione: Genera un report tabulare dei backup per i DB in un compartment
#              e lo salva in OCI Object Storage Bucket
#              Opzionale: filtro per uno o più nomi database (comma-separated)
# Requisiti: oci-cli, jq, column
###############################################################################

set -e

# Colori per l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione di aiuto
usage() {
    echo "Usage: $0 <COMPARTMENT_OCID> <START_DATE> <END_DATE> [DB_NAME_LIST] [BUCKET_NAME]"
    echo ""
    echo "Parameters:"
    echo "  COMPARTMENT_OCID  : OCID of compartment to scan"
    echo "  START_DATE        : Start date (Format: YYYY-MM-DD)"
    echo "  END_DATE          : End date (Format: YYYY-MM-DD)"
    echo "  DB_NAME_LIST      : (Optional) List of database names, comma separated"
    echo "  BUCKET_NAME       : (Optional) OCI Object Storage bucket name for the report upload"
    echo ""
    echo "Examples:"
    echo "  All DBs, only console output:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31"
    echo ""
    echo "  With filter on specific DBs, only console output:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 db1,db2"
    echo ""
    echo "  Upload the report to Object Storage:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 db1,db2 my-backup-bucket"
    echo ""
    echo "  Without DBs filter but with upload to a bucket:"
    echo "    $0 ocid1.compartment.oc1..aaaaaaa... 2023-10-01 2023-10-31 '' my-backup-bucket"
    exit 1
}

# Pre-requisite check
check_prereqs() {
    if ! command -v oci &> /dev/null; then
        echo -e "${RED}Error: OCI CLI not found. Please install oci-cli.${NC}"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq not found. Pleas install jq for JSON parsing.${NC}"
        exit 1
    fi
    if ! command -v column &> /dev/null; then
        echo -e "${RED}Error: column not found. Pleas install bsdmainutils or util-linux.${NC}"
        exit 1
    fi
}

# Data format validation
normalize_date() {
    local input_date=$1
    local time_suffix=$2
    
    if ! [[ $input_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}Error: Invalid data format for '$input_date'. Use YYYY-MM-DD.${NC}"
        exit 1
    fi
    
    echo "${input_date}${time_suffix}"
}

# OCID validation
validate_ocid() {
    local ocid=$1
    if ! [[ $ocid =~ ^ocid1\.compartment\.oc1\..* ]]; then
        echo -e "${RED}Error: Compartment OCID not valid.${NC}"
        exit 1
    fi
}

# Converte lista comma-separated in array bash
parse_db_list() {
    local input="$1"
    echo "$input" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Recupera namespace OCI Object Storage
get_namespace() {
    local compartment_id="$1"
    oci os ns get --query 'data' --raw-output 2>/dev/null
}

# Upload file a OCI Object Storage
upload_to_oci_os() {
    local file_path="$1"
    local namespace="$2"
    local bucket_name="$3"
    local object_name="$4"
    
    echo -e "${BLUE}Upload del report in corso...${NC}"
    
    oci os object put \
        --namespace-name "$namespace" \
        --bucket-name "$bucket_name" \
        --name "$object_name" \
        --file "$file_path" \
        --content-type "text/plain" \
        --force \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Report salvato con successo in Object Storage!${NC}"
        echo "  Namespace: $namespace"
        echo "  Bucket: $bucket_name"
        echo "  Oggetto: $object_name"
        #echo "  URL: https://objectstorage.${OCI_REGION}.oraclecloud.com/n/$namespace/b/$bucket_name/o/$object_name"
        return 0
    else
        echo -e "${RED}Errore durante l'upload in Object Storage.${NC}"
        return 1
    fi
}

# Main Script
main() {
    check_prereqs

    if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
        usage
    fi

    COMP_OCID=$1
    START_DATE_RAW=$2
    END_DATE_RAW=$3
    FILTER_DB_LIST="${4:-}"  # Parametro opzionale (comma-separated)
    BUCKET_NAME="${5:-}"     # Parametro opzionale (bucket name)

    validate_ocid "$COMP_OCID"
    
    # Converti date per il filtro JMESPath (ISO8601)
    START_TIME=$(normalize_date "$START_DATE_RAW" "T00:00:00.000Z")
    END_TIME=$(normalize_date "$END_DATE_RAW" "T23:59:59.999Z")

    # Genera nome file report
    REPORT_FILENAME="backup_report_${START_DATE_RAW}_${END_DATE_RAW}.txt"
    
    # Recupera regione OCI dal config
    OCI_REGION=$(oci config get --profile DEFAULT region 2>/dev/null || echo "unknown")

    echo -e "${GREEN}Generazione Report Backup OCI...${NC}"
    echo "Compartment: $COMP_OCID"
    echo "Periodo: $START_DATE_RAW al $END_DATE_RAW"
    if [ -n "$FILTER_DB_LIST" ]; then
        echo -e "Filtro DB: ${YELLOW}$FILTER_DB_LIST${NC}"
    fi
    if [ -n "$BUCKET_NAME" ]; then
        echo -e "Bucket OS: ${BLUE}$BUCKET_NAME${NC}"
        echo "File report: $REPORT_FILENAME"
    fi
    echo ""

    # Gestione filtro database
    declare -a DB_FILTER_ARRAY
    if [ -n "$FILTER_DB_LIST" ]; then
        # Converte la lista comma-separated in array
        while IFS= read -r db_name; do
            [ -n "$db_name" ] && DB_FILTER_ARRAY+=("$db_name")
        done < <(parse_db_list "$FILTER_DB_LIST")
        
        if [ ${#DB_FILTER_ARRAY[@]} -eq 0 ]; then
            echo -e "${RED}Errore: Lista database vuota o non valida.${NC}"
            exit 1
        fi
    fi

    # Recupera tutti i Database ID e nomi nel compartment
    echo "Recupero lista database..."
    DB_LIST=$(oci db database list \
        --compartment-id "$COMP_OCID" \
        --query 'data[*].{id: id, dbName: "db-name"}' \
        --raw-output \
        2>/dev/null)

    if [ -z "$DB_LIST" ] || [ "$DB_LIST" == "[]" ]; then
        echo -e "${YELLOW}Nessun database trovato nel compartment specificato.${NC}"
        exit 0
    fi

    # Filtra per nome database se specificato
    if [ ${#DB_FILTER_ARRAY[@]} -gt 0 ]; then
        # Passa l'array come argomento jq per evitare problemi di quoting
        DB_NAMES_JSON=$(printf '%s\n' "${DB_FILTER_ARRAY[@]}" | jq -R . | jq -s .)
        
        DB_OCIDS=$(echo "$DB_LIST" | jq -r --argjson dbnames "$DB_NAMES_JSON" '.[] | select(.dbName as $db | $dbnames | index($db)) | .id')
        
        if [ -z "$DB_OCIDS" ]; then
            echo -e "${RED}Errore: Nessun database trovato con i nomi specificati.${NC}"
            echo "Database cercati: ${DB_FILTER_ARRAY[*]}"
            echo ""
            echo "Database disponibili nel compartment:"
            echo "$DB_LIST" | jq -r '.[].dbName' | while read -r name; do
                echo "  - $name"
            done
            exit 1
        fi
        
        DB_COUNT=$(echo "$DB_OCIDS" | wc -l)
        echo -e "${GREEN}Trovati $DB_COUNT database corrispondenti al filtro.${NC}"
    else
        DB_OCIDS=$(echo "$DB_LIST" | jq -r '.[].id')
        DB_COUNT=$(echo "$DB_LIST" | jq 'length')
        echo -e "${GREEN}Trovati $DB_COUNT database nel compartment.${NC}"
    fi

    # Crea file temporaneo per i dati
    TEMP_FILE=$(mktemp)
    REPORT_FILE=$(mktemp --suffix=".txt")
    trap "rm -f $TEMP_FILE $REPORT_FILE" EXIT

    # Contatore per progresso
    DB_CURRENT=0

    # Itera su ogni Database e raccogli i dati
    for DB_ID in $DB_OCIDS; do
        
        DB_CURRENT=$((DB_CURRENT + 1))
        echo -ne "\rElaborazione database $DB_CURRENT di $DB_COUNT..."

        # Query JMESPath con campi kebab-case quotati
        BACKUPS=$(oci db backup list \
            --database-id "$DB_ID" \
            --query "data[?\"time-started\" >= '$START_TIME' && \"time-started\" <= '$END_TIME'].{\"time-started\": \"time-started\", \"display-name\": \"display-name\", \"type\": \"type\", \"lifecycle-state\": \"lifecycle-state\", \"database-size-in-gbs\": \"database-size-in-gbs\"}" \
            --raw-output \
            2>/dev/null)

        if [ "$BACKUPS" != "[]" ] && [ -n "$BACKUPS" ]; then
            # Recupera Nome Database
            DB_NAME=$(oci db database get --database-id "$DB_ID" --query 'data."db-name"' --raw-output 2>/dev/null)
            
            # jq syntax per campi con trattini usando .["field-name"]
            echo "$BACKUPS" | jq -r --arg dbname "$DB_NAME" '.[] | "\(.["time-started"] | split("T")[0])\t\($dbname[0:20])\t\(.["display-name"][0:25])\t\(.["type"])\t\(.["lifecycle-state"])\t\(.["database-size-in-gbs"])"' 2>/dev/null >> "$TEMP_FILE"
        fi
    done

    echo ""

    # Costruisci il report completo
    {
        echo "================================================================================"
        echo "                    OCI DATABASE BACKUP REPORT"
        echo "================================================================================"
        echo ""
        echo "Generato il: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Compartment: $COMP_OCID"
        echo "Periodo: $START_DATE_RAW al $END_DATE_RAW"
        if [ -n "$FILTER_DB_LIST" ]; then
            echo "Filtro DB: $FILTER_DB_LIST"
        else
            echo "Filtro DB: Tutti i database"
        fi
        echo ""
        echo "--------------------------------------------------------------------------------"
        echo "DATA            DB_NAME               BACKUP_NAME                 TIPO            STATO           DIMENSIONE_GB"
        echo "----            -------               -----------                 ----            -----           -------------"
        
        if [ -s "$TEMP_FILE" ]; then
            column -t -s $'\t' < "$TEMP_FILE"
        else
            echo "Nessun backup trovato nel periodo specificato."
        fi
        
        echo ""
        echo "--------------------------------------------------------------------------------"
        if [ -s "$TEMP_FILE" ]; then
            echo "Totale backup trovati: $(wc -l < "$TEMP_FILE")"
        else
            echo "Totale backup trovati: 0"
        fi
        echo "================================================================================"
    } > "$REPORT_FILE"

    # Stampa report a console
    echo ""
    cat "$REPORT_FILE"

    # Upload a Object Storage se bucket specificato
    if [ -n "$BUCKET_NAME" ]; then
        echo ""
        echo -e "${BLUE}=== UPLOAD OBJECT STORAGE ===${NC}"
        
        # Recupera namespace
        NAMESPACE=$(get_namespace "$COMP_OCID")
        
        if [ -z "$NAMESPACE" ]; then
            echo -e "${RED}Errore: Impossibile recuperare il namespace Object Storage.${NC}"
            echo "Verifica i permessi IAM per il compartment."
            exit 1
        fi
        
        echo "Namespace OCI: $NAMESPACE"
        
        # Verifica esistenza bucket
        BUCKET_EXISTS=$(oci os bucket get --namespace-name "$NAMESPACE" --bucket-name "$BUCKET_NAME" --query 'data.name' --raw-output 2>/dev/null)
        
        if [ -z "$BUCKET_EXISTS" ]; then
            echo -e "${RED}Errore: Bucket '$BUCKET_NAME' non trovato nel namespace '$NAMESPACE'.${NC}"
            exit 1
        fi
        
        # Upload del report
        upload_to_oci_os "$REPORT_FILE" "$NAMESPACE" "$BUCKET_NAME" "$REPORT_FILENAME"
    fi

    echo ""
    echo -e "${GREEN}Report completato.${NC}"
}

main "$@"
