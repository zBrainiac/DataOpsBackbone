# 🧠 **DataOps Unchained: Infrastructure that Scales**

[![Update Local Repository and Run Sonar Scanner](https://github.com/zBrainiac/mother-of-all-Projects/actions/workflows/update-local-repo.yml/badge.svg)](https://github.com/zBrainiac/mother-of-all-Projects/actions/workflows/update-local-repo.yml)

> **A hands-on reference architecture for fully automated SQL code quality pipelines using SonarQube, GitHub Actions, and Snowflake.**

---

## ⚙️ Why / What / How

### ❓ Why?

In large, federated organizations, scaling analytics isn’t just a tech challenge—**it’s an operational one**.  
Manual QA breaks at scale. When you're pushing **1,000+ deployments a day**, **automation, governance, and consistency** are essential.

This showcase project, together with [**Mother-of-all-Projects**](https://github.com/zBrainiac/mother-of-all-Projects) — demonstrates a fully automated DataOps setup designed to enforce SQL code quality, structure release flows, and scale confidently with Snowflake and GitHub Actions.

---

### ✅ What?

A DataOps pipeline that automates:

- 🔄 Syncing changes from GitHub
- 🧪 SQL linting & validation (SonarQube + regex rules)
- 🧬 Zero-copy Snowflake DB cloning
- 🚀 Building and testing releases
- 📦 Packaging deployable artifacts

#### Overview of the infrastructure:
![overview infrastructure](images/DataOps_infra_overview.png)

---

### 🚀 How?

It combines:

- **GitHub Actions** (with custom self-hosted runners)
- **SonarQube** extended with SQL & Text plugins
- **Docker Compose** for local stack orchestration
- **Snowflake CLI** for deployment and zero-copy cloning
- **SQLUnit** for automated SQL testing

---

## 🧱 Project Structure

- **[`mother-of-all-Projects`](https://github.com/zBrainiac/mother-of-all-Projects)**  
  GitHub workflows, SQL refactoring logic, Snowflake deployment scripts, and validation via SQLUnit.

- **[`sql_quality_check`](https://github.com/zBrainiac/sql_quality_check)**  
  Dockerized infrastructure stack for:
  - SonarQube + PostgreSQL
  - GitHub self-hosted runners
  - Local development/testing

---
## Monitoring
### Issue overview
![Issue overview](images/sq_rules.png)

### Issue within code
![Issue within code](images/sq_Issue_within_code.png)

### Technical dept
![Technical dept](images/sq_technical_dept.png)

## ⚡ Quick Setup Guide

### 🛠️ Step 1: Snowflake Config

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

### 🔐 Step 2: Encode & Upload Secrets

```bash
base64 -b 0 -i ~/.snowflake/config.toml | tr -d '\n' > SNOW_CONFIG_B64
base64 -i ~/.snowflake/private_key.pem | tr -d '\n' > SNOW_KEY_B64
```

Upload the following secrets to GitHub:

- `SNOW_CONFIG_B64`
- `SNOW_KEY_B64`
- `SONAR_TOKEN`

---

### 🔁 Step 3: Run It

- Start your local stack via `docker-compose`
- Access SonarQube at: [http://localhost:9000](http://localhost:9000)  
  **Login**: `admin` / `ThisIsNotSecure1234!`
- Trigger your GitHub workflow

---

## 🧠 Final Thoughts

This is not just a demo. It's a **reusable framework** to scale DataOps — combining validation, governance, and automation into one consistent, testable workflow.
