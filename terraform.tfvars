region                     = "us-east-1"
key_name                   = "bastion"
ECR_REPOS                  = ["ecr_backend_api", "ecr_backend_cron"]
FRONTEND_CODE_COMMIT_REPOS = ["TOKENIZATION_AGENT"]
sso_enabled_envs           = ["dev", "uat", "jpmc"]
enable_user_pool           = true