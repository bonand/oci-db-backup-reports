# OCI Database Backup Report Generator

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![OCI CLI](https://img.shields.io/badge/OCI-CLI-orange.svg)](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

Bash script to generate detailed reports on Oracle Cloud Infrastructure (OCI) database backups with filtering capabilities and automatic Object Storage upload.

## 📋 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
- [Parameters](#-parameters)
- [Examples](#-examples)
- [IAM Policies](#-iam-policies)
- [Output](#-output)
- [Report Structure](#-report-structure)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **Comprehensive Reports**: Generate detailed tabular reports on OCI database backups
- **Advanced Filtering**: Filter by time period and specific database names (single or multiple)
- **Object Storage Integration**: Automatically save reports to OCI Object Storage
- **Multi-Database Support**: Analyze all databases or a specific subset
- **Formatted Output**: Readable reports with tabular formatting
- **Daily Granularity**: View backups with start date
- **Complete Metadata**: Includes backup type, status, size, and database information

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
./oci_backup_report.sh <COMPARTMENT_OCID> <START_DATE> <END_DATE> [DB_NAME_LIST] [BUCKET_NAME]
```

## 📊 Parameters

| Parameter | Required | Description | Format/Example |
|-----------|----------|-------------|----------------|
| `COMPARTMENT_OCID` | ✅ | OCID of the OCI compartment to analyze | `ocid1.compartment.oc1..aaaaaaa...` |
| `START_DATE` | ✅ | Start date of the period | `YYYY-MM-DD` (e.g., `2026-03-01`) |
| `END_DATE` | ✅ | End date of the period | `YYYY-MM-DD` (e.g., `2026-03-31`) |
| `DB_NAME_LIST` | ❌ | List of database names (comma-separated) | `db1,db2,db3` or `''` for all |
| `BUCKET_NAME` | ❌ | Object Storage bucket name to save the report | `my-backup-bucket` |

## 💡 Examples

### 1. Report for All Databases

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31
```

### 2. Report for a Single Database

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK"
```

### 3. Report for Multiple Databases

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK,DORATST,PRICING"
```

### 4. Save to Object Storage (All DBs)

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  '' \
  my-backup-reports-bucket
```

### 5. Save to Object Storage (Specific Databases)

```bash
./oci_backup_report.sh \
  ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq \
  2026-03-01 \
  2026-03-31 \
  "MILK,DORATST" \
  my-backup-reports-bucket
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

## 📤 Output

### Console Output

```
Generazione Report Backup OCI...
Compartment: ocid1.compartment.oc1..aaaaaaaah6u76kznr7igdlquo4parzst66njfepfj3zysn3hx3xhdp77krbq
Period: 2026-03-01 to 2026-03-31
DB Filter: MILK,DORATST
Bucket OS: my-backup-reports-bucket
Report File: backup_report_2026-03-01_2026-03-31.txt

Retrieving database list...
Found 2 databases matching the filter.
Processing database 2 of 2...

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

=== UPLOAD OBJECT STORAGE ===
Namespace OCI: my-namespace
Uploading report...
Report successfully saved to Object Storage!
  Namespace: my-namespace
  Bucket: my-backup-reports-bucket
  Object: backup_report_2026-03-01_2026-03-31.txt
  URL: https://objectstorage.eu-milan-1.oraclecloud.com/n/my-namespace/b/my-backup-reports-bucket/o/backup_report_2026-03-01_2026-03-31.txt

Report completed.
```

## 📄 Report Structure

The generated report includes:

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

## 📝 Changelog

### v1.0.0 (2026-03-20)
- ✅ Initial release
- ✅ OCI database backup report support
- ✅ Filtering by period and database names
- ✅ Object Storage saving
- ✅ Formatted tabular output
- ✅ Multi-database support

## 📜 License

Distributed under the GNU General Public License v3.0. See `LICENSE` for more information.

## 👨‍ Authors

- **Andrea Bonadonna** - *Initial work*

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

---

**Note**: This script is provided "as is" without warranties of any kind. Use it at your own risk. Always test in a development environment before using in production.
