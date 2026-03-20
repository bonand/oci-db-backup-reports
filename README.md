# OCI Database Backup Report Generator

[![License](https://img.shields.io/badge/License-GNU%20GPL%203.0-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![OCI CLI](https://img.shields.io/badge/OCI-CLI-orange.svg)](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
[![Version](https://img.shields.io/badge/Version-1.1.0-purple.svg)](https://github.com/your-username/oci-db-backup-report/releases)

Bash script to generate detailed reports on Oracle Cloud Infrastructure (OCI) database backups with filtering capabilities, automatic Object Storage upload, and support for both TEXT and JSON output formats.

## 📋 Table of Contents

- [Features](#-features)
- [What's New in v1.1.0](#-whats-new-in-v110)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
- [Parameters](#-parameters)
- [Examples](#-examples)
- [IAM Policies](#-iam-policies)
- [Output Formats](#-output-formats)
- [Report Structure](#-report-structure)
- [Integration Examples](#-integration-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [Changelog](#-changelog)
- [License](#-license)

## ✨ Features

- **Comprehensive Reports**: Generate detailed tabular reports on OCI database backups
- **Advanced Filtering**: Filter by time period and specific database names (single or multiple)
- **Object Storage Integration**: Automatically save reports to OCI Object Storage
- **Multi-Database Support**: Analyze all databases or a specific subset
- **Dual Output Formats**: Support for both TEXT (human-readable) and JSON (machine-readable) formats
- **Daily Granularity**: View backups with start date
- **Complete Metadata**: Includes backup type, status, size, and database information
- **Third-Party Integration**: JSON output for monitoring systems, APIs, and automation tools

## 🆕 What's New in v1.1.0

### JSON Output Support

The script now supports **JSON output format** for integration with third-party applications, monitoring systems, or automation tools.

#### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Machine-Readable** | Easy to parse for applications and scripts |
| **Structured Data** | Hierarchically organized data |
| **API-Friendly** | Compatible with REST APIs and webhooks |
| **Monitoring Ready** | Integrates with Prometheus, Grafana, Datadog |
| **Automation Ready** | Ideal for CI/CD pipelines and orchestration |

## 📋 Requirements

### Required Software

- **Bash** 4.0+
- **OCI CLI** configured and authenticated
- **jq** (JSON processor)
- **column** (util-linux or bsdmainutils)

### Verify Requirements

```bash
# Check Bash version
bash --version

# Check OCI CLI
oci --version

# Check jq
jq --version

# Check column
column --version
```

### OCI CLI Configuration

```bash
# Configure OCI CLI (if not already done)
oci setup config

# Validate configuration
oci config validate
```

## 🚀 Installation

### Clone the Repository

```bash
git clone https://github.com/your-username/oci-db-backup-report.git
cd oci-db-backup-report
```

### Execution Permissions

```bash
chmod +x oci_backup_report.sh
```

### Verify Installation

```bash
./oci_backup_report.sh --help
```

## 📖 Usage

### Syntax

```bash
./oci_backup_report.sh <COMPARTMENT_OCID> <START_DATE> <END_DATE> [DB_NAME_LIST] [BUCKET_NAME] [OUTPUT_FORMAT]
```

## 📊 Parameters

| Parameter | Required | Description | Format/Example |
|-----------|----------|-------------|----------------|
| `COMPARTMENT_OCID` | ✅ | OCID of the OCI compartment to analyze | `ocid1.compartment.oc1..aaaaaaa...` |
| `START_DATE` | ✅ | Start date of the period | `YYYY-MM-DD` (e.g., `2026-03-01`) |
| `END_DATE` | ✅ | End date of the period | `YYYY-MM-DD` (e.g., `2026-03-31`) |
| `DB_NAME_LIST` | ❌ | List of database names (comma-separated) | `db1,db2,db3` or `''` for all |
| `BUCKET_NAME` | ❌ | Object Storage bucket name to save the report | `my-backup-bucket` |
| `OUTPUT_FORMAT` | ❌ | Output format | `text` (default) or `json` |

## 💡 Examples

### Text Output Examples

#### 1. Report for All Databases (Text)

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31
```

#### 2. Report for a Single Database (Text)

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK"
```

#### 3. Report for Multiple Databases (Text)

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK,DORATST,PRICING"
```

#### 4. Save Text Report to Object Storage

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  '' \
  my-backup-reports-bucket
```

### JSON Output Examples

#### 5. Generate JSON Report (Console Output)

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK,DORATST" \
  '' \
  json
```

#### 6. Save JSON Report to Object Storage

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK,DORATST" \
  my-backup-reports-bucket \
  json
```

#### 7. JSON Output with All Databases

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  '' \
  '' \
  json
```

## 🔐 IAM Policies

### Minimum Required Permissions

Create the following IAM policies in your OCI tenancy:

```bash
# Permissions to read databases and backups
Allow group <your-group> to read database-family in compartment <compartment-name>

# Permissions for Object Storage (only if using report saving)
Allow group <your-group> to manage objects in compartment <compartment-name> where target.bucket.name='<bucket-name>'
Allow group <your-group> to read buckets in compartment <compartment-name>
Allow group <your-group> to read tenancies in tenancy
```

### Variable Substitution

- `<your-group>`: OCI IAM group name
- `<compartment-name>`: Target compartment name
- `<bucket-name>`: Object Storage bucket name (if used)

### Complete Policy Example

```bash
Allow group dba-team to read database-family in compartment production
Allow group dba-team to manage objects in compartment production where target.bucket.name='backup-reports'
Allow group dba-team to read buckets in compartment production
Allow group dba-team to read tenancies in tenancy
```

## 📤 Output Formats

### Text Output (Human-Readable)

```
================================================================================
                    OCI DATABASE BACKUP REPORT
================================================================================

Generated on: 2026-03-20 14:30:45
Compartment: ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq
Period: 2026-03-01 to 2026-03-31
DB Filter: MILK,DORATST

--------------------------------------------------------------------------------
DATE            DB_NAME               BACKUP_NAME                 TYPE            STATUS          SIZE_GB
----            -------               -----------                 ----            -----           ---------
2026-03-10      MILK                  Automatic Backup            INCREMENTAL     ACTIVE          9536.056640625
2026-03-15      MILK                  Manual Backup               FULL            ACTIVE          9540.125
2026-03-12      DORATST               Automatic Backup            FULL            ACTIVE          4520.125

--------------------------------------------------------------------------------
Total backups found: 3
================================================================================
```

### JSON Output (Machine-Readable)

```json
{
  "report": {
    "metadata": {
      "generated_at": "2026-03-20T14:30:45Z",
      "report_type": "OCI_DATABASE_BACKUP",
      "version": "1.0.0"
    },
    "filters": {
      "compartment_ocid": "ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq",
      "period": {
        "start_date": "2026-03-01",
        "end_date": "2026-03-31"
      },
      "database_filter": "MILK,DORATST"
    },
    "summary": {
      "total_backups": 3,
      "total_size_gb": 14056.306640625
    },
    "backups": [
      {
        "date": "2026-03-10",
        "db_name": "MILK",
        "backup_name": "Automatic Backup",
        "type": "INCREMENTAL",
        "status": "ACTIVE",
        "size_gb": 9536.056640625
      },
      {
        "date": "2026-03-15",
        "db_name": "MILK",
        "backup_name": "Manual Backup",
        "type": "FULL",
        "status": "ACTIVE",
        "size_gb": 9540.125
      },
      {
        "date": "2026-03-12",
        "db_name": "DORATST",
        "backup_name": "Automatic Backup",
        "type": "FULL",
        "status": "ACTIVE",
        "size_gb": 4520.125
      }
    ]
  }
}
```

## 📄 Report Structure

### Text Report Structure

1. **Header**
   - Generation date and time
   - Compartment OCID
   - Analyzed period
   - Applied filters

2. **Backup Table**
   - **DATE**: Backup start date (YYYY-MM-DD)
   - **DB_NAME**: Database name
   - **BACKUP_NAME**: Backup name
   - **TYPE**: Backup type (FULL/INCREMENTAL)
   - **STATUS**: Backup status (ACTIVE/CREATING/FAILED/etc.)
   - **SIZE_GB**: Size in GB

3. **Footer**
   - Total backups found
   - Summary statistics

### JSON Report Structure

```json
{
  "report": {
    "metadata": {           // Report metadata
      "generated_at": "",   // ISO8601 timestamp
      "report_type": "",    // Report type identifier
      "version": ""         // Script version
    },
    "filters": {            // Applied filters
      "compartment_ocid": "",
      "period": {
        "start_date": "",
        "end_date": ""
      },
      "database_filter": ""
    },
    "summary": {            // Summary statistics
      "total_backups": 0,
      "total_size_gb": 0
    },
    "backups": []           // Array of backup objects
  }
}
```

## 🔗 Integration Examples

### Parse JSON with jq

```bash
# Get total number of backups
./oci_backup_report.sh ... json | jq '.report.summary.total_backups'

# Get all backup names
./oci_backup_report.sh ... json | jq '.report.backups[].backup_name'

# Filter by backup type
./oci_backup_report.sh ... json | jq '.report.backups[] | select(.type == "FULL")'

# Calculate total size
./oci_backup_report.sh ... json | jq '.report.summary.total_size_gb'

# Get failed backups
./oci_backup_report.sh ... json | jq '.report.backups[] | select(.status != "ACTIVE")'

# Export to CSV
./oci_backup_report.sh ... json | jq -r '.report.backups[] | [.date, .db_name, .backup_name, .type, .status, .size_gb] | @csv'
```

### Integrate with Monitoring Systems

#### Prometheus/Grafana

```bash
# Export metrics for Prometheus
./oci_backup_report.sh ... json | jq -r '
  "oci_backup_total_backups \(.report.summary.total_backups)",
  "oci_backup_total_size_gb \(.report.summary.total_size_gb)",
  (.report.backups[] | "oci_backup_size_gb{db=\"\(.db_name)\",type=\"\(.type)\"} \(.size_gb)")
' > /var/lib/node_exporter/textfile_collector/oci_backups.prom
```

#### Datadog

```bash
# Send to Datadog API
./oci_backup_report.sh ... json | jq '.report.summary' | \
  curl -X POST "https://api.datadoghq.com/api/v1/series" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "Content-Type: application/json" \
  -d @-
```

### Webhook Integration

```bash
# Send report to webhook
./oci_backup_report.sh ... json | jq '.report' | \
  curl -X POST -H "Content-Type: application/json" \
  -d @- https://your-webhook-endpoint.com/backups
```

### CI/CD Pipeline Integration

#### GitHub Actions

```yaml
- name: Generate Backup Report
  run: |
    ./oci_backup_report.sh \
      ${{ secrets.OCI_COMPARTMENT_OCID }} \
      $(date -d "yesterday" +%Y-%m-%d) \
      $(date -d "yesterday" +%Y-%m-%d) \
      '' \
      '' \
      json > backup_report.json
    
- name: Upload Report Artifact
  uses: actions/upload-artifact@v3
  with:
    name: backup-report
    path: backup_report.json
```

#### Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Generate Backup Report') {
            steps {
                sh '''
                    ./oci_backup_report.sh \
                        ${OCI_COMPARTMENT_OCID} \
                        $(date -d "yesterday" +%Y-%m-%d) \
                        $(date -d "yesterday" +%Y-%m-%d) \
                        '' \
                        '' \
                        json > backup_report.json
                '''
            }
        }
        stage('Archive Report') {
            steps {
                archiveArtifacts artifacts: 'backup_report.json'
            }
        }
    }
}
```

### Scheduled Execution (Cron)

```bash
# Daily backup report at 8 AM
0 8 * * * /path/to/oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaa... \
  $(date -d "yesterday" +%Y-%m-%d) \
  $(date -d "yesterday" +%Y-%m-%d) \
  '' \
  my-backup-bucket \
  json >> /var/log/backup-report.log 2>&1

# Weekly summary every Monday at 9 AM
0 9 * * 1 /path/to/oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaa... \
  $(date -d "last week" +%Y-%m-%d) \
  $(date +%Y-%m-%d) \
  '' \
  my-backup-bucket \
  json >> /var/log/backup-report-weekly.log 2>&1
```

### Python Integration

```python
import subprocess
import json

# Generate report
result = subprocess.run([
    './oci_backup_report.sh',
    'ocid1.compartment.oc1..aaaaaaa...',
    '2026-03-01',
    '2026-03-31',
    '',
    '',
    'json'
], capture_output=True, text=True)

# Parse JSON
report = json.loads(result.stdout)

# Process data
for backup in report['report']['backups']:
    print(f"{backup['db_name']}: {backup['backup_name']} ({backup['size_gb']} GB)")
```

## 🔧 Troubleshooting

### Error: "OCI CLI not found"

**Solution**: Install OCI CLI

```bash
pip install oci-cli
# or
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

### Error: "jq not found"

**Solution**: Install jq

```bash
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# macOS
brew install jq
```

### Error: "Unable to retrieve Object Storage namespace"

**Solution**: Verify IAM permissions and OCI CLI configuration

```bash
# Verify configuration
oci config validate

# Test namespace access
oci os ns get
```

### Error: "Bucket not found"

**Solution**: Create the bucket or verify the name

```bash
# List existing buckets
oci os bucket list --namespace-name <your-namespace>

# Create bucket
oci os bucket create \
  --namespace-name <your-namespace> \
  --compartment-id <compartment-ocid> \
  --name <bucket-name>
```

### Error: "No databases found"

**Solution**: Verify compartment OCID and permissions

```bash
# List databases in compartment
oci db database list --compartment-id <compartment-ocid>
```

### Error: "Permission denied"

**Solution**: Verify IAM policies and group membership

```bash
# Verify user and groups
oci iam user get --user-id <your-user-ocid>
```

### Error: "Invalid output format"

**Solution**: Use only `text` or `json` as output format

```bash
# Correct usage
./oci_backup_report.sh ... text
./oci_backup_report.sh ... json

# Incorrect usage
./oci_backup_report.sh ... xml  # Will fail
```

## 🤝 Contributing

Contributions are welcome! Follow these steps:

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Guidelines

- Use bash scripting best practices
- Maintain compatibility with Bash 4.0+
- Document new features
- Test with different scenarios
- Ensure both text and JSON output work correctly

## 📝 Changelog

### v1.1.0 (2026-03-25)
- ✅ **NEW**: JSON output format support
- ✅ **NEW**: Structured metadata in JSON reports
- ✅ **NEW**: Summary statistics in JSON (total backups, total size)
- ✅ **NEW**: Content-Type handling for Object Storage uploads
- ✅ **NEW**: Integration examples for monitoring systems
- ✅ **NEW**: CI/CD pipeline examples
- ✅ Improved error handling for invalid output formats
- ✅ Updated documentation with JSON examples
- ✅ Added webhook integration examples

### v1.0.0 (2026-03-20)
- ✅ Initial release
- ✅ OCI database backup report support
- ✅ Filtering by period and database names
- ✅ Object Storage saving
- ✅ Formatted tabular output
- ✅ Multi-database support

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👨‍ Authors

- **OCI Cloud Architect** - *Initial work*

## 🙏 Acknowledgments

- Oracle Cloud Infrastructure Team
- Contributors and users who provided feedback

## 📞 Support

For issues, questions, or suggestions:
- Open an [Issue](https://github.com/your-username/oci-db-backup-report/issues)
- Contact the maintainer

## 🔗 Useful Resources

- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
- [OCI Database Service](https://docs.oracle.com/en-us/iaas/database.htm)
- [OCI Object Storage](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/managingobjects.htm)
- [JQ Manual](https://stedolan.github.io/jq/manual/)
- [OCI IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/policygetstarted.htm)

---

**Note**: This script is provided "as is" without warranties of any kind. Use it at your own risk. Always test in a development environment before using in production.
```
