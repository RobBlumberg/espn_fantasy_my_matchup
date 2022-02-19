env = "prod"

aws_region = "us-west-2"

enable_step_functions = false

access_list_cidr_blocks = []

compute_environment_desired_vcpus  = 4
compute_environment_instance_types = ["c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge"]
compute_environment_min_vcpus      = 0
compute_environment_max_vcpus      = 16