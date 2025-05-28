# Analytics engineering with dbt

Template repository for the projects and environment of the course: Analytics engineering with dbt

> Please note that this sets some environment variables so if you create some new terminals please load them again.

## License

Apache 2.0


# Module call to apply RBAC grants for a Snowflake role
# Assigns privileges to a role for specific Snowflake objects based on a nested dictionary
locals {
  # Compute account_role_name based on terraform.workspace
  account_role_name = terraform.workspace == "prod" ? "SF_ENGINEERING_USER_ROLE_PROD" : "SF_ENGINEERING_USER_ROLE_NONPROD"

  # Nested dictionary defining privileges for each object
  object_privileges = {
    database_grants_engineering_role = {
      "DB_SOURCE_A"       = ["USAGE", "CREATE SCHEMA"]
      "DB_SOURCE_B"       = ["USAGE"]
      "DB_SOURCE_PRIMARY" = []
    }
    warehouse_grants_engineering_role = {
      "WH_SOURCE_A"       = ["USAGE"]
      "WH_SOURCE_B"       = ["USAGE"]
      "WH_SOURCE_PRIMARY" = []
    }
    schema_grants_engineering_role = {
      "DB_SOURCE_A"       = ["CREATE TABLE", "CREATE VIEW"]
      "DB_SOURCE_B"       = ["CREATE TABLE"]
      "DB_SOURCE_PRIMARY" = []
    }
  }
}

module "rbac-sf_user_grant_role_privileges" {
  source = "../module/grants"

  # Ensure databases and warehouses exist before applying grants
  depends_on = [
    snowflake_database.database_abc_a,
    snowflake_database.database_abc_b,
    snowflake_database.database_abc_primary,
    snowflake_warehouse.warehouse_abc_a,
    snowflake_warehouse.warehouse_abc_b,
    snowflake_warehouse.warehouse_abc_primary
  ]

  # Use dynamic account_role_name
  account_role_name = local.account_role_name

  # Combine database, warehouse, and schema grants
  on_account_obj_grants = concat(
    # Database grants
    flatten([
      for object_name, privileges in local.object_privileges.database_grants_engineering_role : [
        {
          object_name   = object_name
          object_type   = "DATABASE"
          privileges    = privileges
          env_to_deploy = [terraform.workspace]
        }
        if length(privileges) > 0
      ]
    ]),
    # Warehouse grants
    flatten([
      for object_name, privileges in local.object_privileges.warehouse_grants_engineering_role : [
        {
          object_name   = object_name
          object_type   = "WAREHOUSE"
          privileges    = privileges
          env_to_deploy = [terraform.workspace]
        }
        if length(privileges) > 0
      ]
    ]),
    # Schema grants (ALL_SCHEMAS_IN_DATABASE)
    flatten([
      for object_name, privileges in local.object_privileges.schema_grants_engineering_role : [
        {
          object_name   = object_name
          object_type   = "ALL_SCHEMAS_IN_DATABASE"
          privileges    = privileges
          env_to_deploy = [terraform.workspace]
        }
        if length(privileges) > 0
      ]
    ])
  )
}

# Resource definitions for databases
resource "snowflake_database" "database_abc_a" {
  name = "DB_SOURCE_A"
}

resource "snowflake_database" "database_abc_b" {
  name = "DB_SOURCE_B"
}

resource "snowflake_database" "database_abc_primary" {
  name = "DB_SOURCE_PRIMARY"
}

# Resource definitions for warehouses
resource "snowflake_warehouse" "warehouse_abc_a" {
  name = "WH_SOURCE_A"
}

resource "snowflake_warehouse" "warehouse_abc_b" {
  name = "WH_SOURCE_B"
}

resource "snowflake_warehouse" "warehouse_abc_primary" {
  name = "WH_SOURCE_PRIMARY"
}
