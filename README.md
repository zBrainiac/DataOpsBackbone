



Implementation: GitHub Actions + Docker
Assuming you store your secrets like this in GitHub:

Step 0: Create a CONFIG file (.toml) and a key to connect to Snowflake.

- snow cli config (~/.snowflake/config.toml)
```
[connections.sfseeurope-demo_ci_user]
account = "<your snowflake "Account Identifier">"
user = "<snowflake user e.g. "ci_user">"
database = "<db>"
schema = "<schema>"
warehouse = "<warehouse>"
role = "SYSADMIN"
authenticator = "SNOWFLAKE_JWT"
private_key_file = "xxx/xxx/private_key.pem"
```

- private_key.pem
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCn4h4yObmnbPM3
...
SN3iZYUz88eg2c3nbQkXdQg=
-----END PRIVATE KEY-----
```
.env file
```
# GitHub
GH_RUNNER_TOKEN=
GITHUB_OWNER=zBrainiac
GITHUB_REPO_1=mother-of-all-Projects

# Sonar
POSTGRES_USER=<...>
POSTGRES_PASSWORD=<...>
POSTGRES_DB=<...>
SONAR_JDBC_USERNAME=<...>
SONAR_JDBC_PASSWORD=<...>

# Snowflake
CONNECTION_NAME=sfseeurope-demo_ci_user
SNOW_PRIVATE_KEY_PATH=/path/to/key.pem
```

Step 1: Encode the files (on your machine)

- base64 -b 0 -i ~/.snowflake/config.toml | tr -d '\n' > SNOW_CONFIG_B64
- base64 -i ~/.snowflake/snowflake_private_key.pem | tr -d '\n' > SNOW_KEY_B64



Step 2: Upload the contents of these files into GitHub Secrets:

- SNOW_CONFIG_B64
- SNOW_KEY_B64
- SONAR_TOKEN




Step 2: Inject in GitHub Actions Workflow

http://localhost:9000/
- admin
- ThisIsNotSecure1234!