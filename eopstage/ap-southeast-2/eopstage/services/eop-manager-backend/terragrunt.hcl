terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.96.9"
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/ecs-eop-manager-backend.hcl"
  expose = true
}

locals {
  db_secrets_manager_arn = "arn:aws:secretsmanager:ap-southeast-2:564180615104:secret:RDSDBConfig-roeweY"

  # List of environment variables and container images for each container that are specific to this environment. The map
  # key here should correspond to the map keys of the _container_definitions_map input defined in envcommon.
  service_environment_variables = {
    (include.envcommon.locals.service_name) = [
      {
        name  = "CONFIG_SECRETS_SECRETS_MANAGER_DB_ID"
        value = local.db_secrets_manager_arn
      },
    ]
  }
  container_images = {
    (include.envcommon.locals.service_name) = "${include.envcommon.locals.container_image}:${local.tag}"
  }

  # Specify the app image tag here so that it can be overridden in a CI/CD pipeline.
  tag = "a23b80c41a770f46c76b0751971789a41d7c607d"
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # The Container definitions of the ECS service. The following environment specific parameters are injected into the
  # common definition defined in the envcommon config:
  # - Image tag
  # - Secrets manager ARNs
  container_definitions = [
    for name, definition in include.envcommon.inputs._container_definitions_map :
    merge(
      definition,
      {
        name        = name
        image       = local.container_images[name]
        environment = concat(definition.environment, local.service_environment_variables[name])
      },
    )
  ]

  secrets_access = [
    local.db_secrets_manager_arn,
  ]
}