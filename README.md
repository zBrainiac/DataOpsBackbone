# **DataOps Unchained: Infrastructure that Scales**

[![Update Local Repository and Run Sonar Scanner](https://github.com/zBrainiac/mother-of-all-Projects/actions/workflows/update-local-repo.yml/badge.svg)](https://github.com/zBrainiac/mother-of-all-Projects/actions/workflows/update-local-repo.yml)
[![Docker Build and Push to Docker Hub (Multi-Arch)](https://github.com/zBrainiac/sql_quality_check/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/zBrainiac/sql_quality_check/actions/workflows/docker-publish.yml)

> **A hands-on reference architecture for fully automated SQL code quality pipelines using SonarQube, GitHub Actions, and Snowflake.**

---

## Why / What / How

### Why?

In large, federated organizations, scaling analytics isn’t just a tech challenge—**it’s an operational one**.  
Manual QA breaks at scale. When you're pushing **1,000+ deployments a day**, **automation, governance, and consistency** are essential.

This showcase project, together with [**Mother-of-all-Projects**](https://github.com/zBrainiac/mother-of-all-Projects) — demonstrates a fully automated DataOps setup designed to enforce SQL code quality, structure release flows, and scale confidently with Snowflake and GitHub Actions.

---

### What?

A DataOps pipeline that automates:

- Syncing changes from GitHub
- SQL linting & validation (SonarQube + regex rules)
- Zero-copy Snowflake DB cloning
- Building and testing releases
- Packaging deployable artifacts

#### Overview of the infrastructure:
![overview infrastructure](images/DataOps_infra_overview.png)

---

### How?

It combines:

- **GitHub Actions** (with custom self-hosted runners)
- **SonarQube** extended with SQL & Text plugins
- **Docker Compose** for local stack orchestration
- **Snowflake CLI** for deployment and zero-copy cloning
- **SQLUnit** for automated SQL testing

---

## Project Structure

- **[mother-of-all-Projects](https://github.com/zBrainiac/mother-of-all-Projects)**  
  GitHub workflows, SQL refactoring logic, Snowflake deployment scripts, and validation via SQLUnit.

- **[DataOps Backbone](https://github.com/zBrainiac/DataOpsBackbone)**  
  Dockerized infrastructure stack for:
  - SonarQube + PostgreSQL
  - GitHub self-hosted runners
  - Local development/testing

---
## SQL Linting Rules and Regex Patterns
This list provides a few examples of SQL validation rules, each of which is paired with a regular expression (regex) that can be used to identify non-compliant code using the Community Text plugin of SonarQube.

Backups of these rules, which can be restored as a Quality Profile, are available in the repository ([link](backup/2025-08-04_quality_profiles_text_plugin.xml)).

#### 1. Disallow `CREATE SCHEMA` without `IF NOT EXISTS` or `REPLACE`
```regex
(?i)^\s*CREATE\s+(?!OR\s+REPLACE\b)(?!.*\bIF\s+NOT\s+EXISTS\b).*?\bSCHEMA\b
```

#### 2. Disallow CREATE TABLE without IF NOT EXISTS or REPLACE
```regex
(?is)^(?!\s*--).*CREATE\s+(?!OR\s+REPLACE\b|.*IF\s+NOT\s+EXISTS\b).*TABLE\b
```

#### 3. Disallow CREATE statements with hardcoded database and/or schema prefix
```regex
(?i)^(?!\s*--)\s*create\s+(or\s+replace\s+)?(table|view|schema)\s+(if\s+not\s+exists\s+)?[a-z0-9_]+\.[a-z0-9_]+(\.[a-z0-9_]+)?
```

#### 4. Disallow GRANT statements to PUBLIC
```regex
(?i)^(?!\s*--).*grant\s+.*\s+to\s+public\b
```

#### 5. Disallow dropping objects without IF EXISTS
```regex
(?i)^\s*DROP\s+(SCHEMA|TABLE|VIEW)\s+(?!IF\s+EXISTS\b)
```

#### 6. Disallow hardcoded USE DATABASE, USE SCHEMA, or USE ROLE statements
```regex
(?i)^(?!\s*--)\s*USE\s+(DATABASE|SCHEMA|ROLE)\b
```

#### 7. Disallow usage of TIMESTAMP types other than TIMESTAMP_TZ
```regex
(?i)(?<!--.*)\bTIMESTAMP(_NTZ|_LTZ)?(\s*\(\s*\d+\s*\))?\b
```

#### 8. Schema names must have a prefix (RAW_, REF_, CON_, AGG_, DP_, DM_)
```regex
(?i)^(?!\s*--)\s*CREATE\s+(OR\s+REPLACE\s+)?SCHEMA\s+(IF\s+NOT\s+EXISTS\s+)?(?:[a-z0-9_]+\.)?(?!RAW_|REF_|CON_|AGG_|DP_|DM_)[a-z0-9_]+;
```

#### 9. (Dynamic) Table | Views names must begin with a 3-character alphanumeric component code followed by an underscore
```regex
(?i)^(?!\s*--)(?:\s*create(?:\s+or\s+replace)?|\s*alter)\s+(dynamic\s+)?table\s+(if\s+not\s+exists\s+)?(?:[A-Z0-9_]+\.){0,2}(?![A-Z0-9]{3}_)[A-Z_][A-Z0-9_]*
```

#### 10. Disallow Cross-Database Dependencies
```regex
^.*cross_db_true.*$
```

#### 11. Disallow Cross-Schema Dependencies
```regex
^.*cross_schema_true.*$
```

## Monitoring
### Issue overview
![Issue overview](images/sq_rules.png)

### Issue within code
![Issue within code](images/sq_Issue_within_code.png)

### Technical dept
![Technical dept](images/sq_technical_dept.png)


### Monitor the history of test case execution
![unitth_overview.png](images/unitth_overview.png)

## Quick Setup Guide

### Step 1: Snowflake Config

`~/.snowflake/config.toml`
```toml
[connections.sfseeurope-demo_ci_user]
account = "<your_account>"
user = "ci_user"
database = "<db>"
schema = "<schema>"
warehouse = "<warehouse>"
role = "SYSADMIN"
authenticator = "SNOWFLAKE_JWT"
private_key_file = "/path/to/private_key.pem"
```

`private_key.pem`
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCn4h4yObmnbPM3
...
SN3iZYUz88eg2c3nbQkXdQg=
-----END PRIVATE KEY-----
```

`.env`
```dotenv
# GitHub
GH_RUNNER_TOKEN=<...>
GITHUB_OWNER=zBrainiac
GITHUB_REPO_1=mother-of-all-Projects

# SonarQube
POSTGRES_USER=<...>
POSTGRES_PASSWORD=<...>
POSTGRES_DB=<...>
SONAR_JDBC_USERNAME=<...>
SONAR_JDBC_PASSWORD=<...>

# Snowflake
CONNECTION_NAME=sfseeurope-demo_ci_user
SNOW_PRIVATE_KEY_PATH=/path/to/private_key.pem
```

---

### Step 2: Encode & Upload Secrets

```bash
base64 -b 0 -i ~/.snowflake/config.toml | tr -d '\n' > SNOW_CONFIG_B64
base64 -i ~/.snowflake/private_key.pem | tr -d '\n' > SNOW_KEY_B64
```

Upload the following secrets to GitHub:

- `SNOW_CONFIG_B64`
- `SNOW_KEY_B64`
- `SONAR_TOKEN` (see below step 3.)

---
### Step 3: Generate a SONAR_TOKEN (for user `ci_user`)

1. Start your local stack via `./start.sh`
2. Log in to SonarQube [http://localhost:9000](http://localhost:9000) as `admin`
3. Go to **My Account** > **Security**
4. Under **Generate Tokens**:
 - **Name** the token (e.g., `ci_user`)
 - **Type** of the token `global analysis token`
 - Click **Generate**
5. Copy the token (you won’t see it again).
6. Use as `SONAR_TOKEN` in your CI/CD pipeline.

---

### Step 4: Run It

1. Start your local stack via `./start.sh`
2. Access SonarQube at: [http://localhost:9000](http://localhost:9000)  
  **Login**: `admin` / `ThisIsNotSecure1234!` (default 'admin')
3. Trigger your GitHub workflow
4. Check results in sonarqube 
5. monitor SQLUnit test results (incl. history) at: [http://localhost:8080](http://localhost:9080/index.html)

---

## Final Thoughts

This is not just a demo. It's a **reusable framework** to scale DataOps — combining validation, governance, and automation into one consistent, testable workflow.
