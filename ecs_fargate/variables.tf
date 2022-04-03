variable "app_name" {
  description = "the name for the application service being created"
  type        = string
}

variable "task_name" {
  description = "the fully qualified task name for the task to use"
  type        = string
}

variable "region" {
  description = "the region the service will reside in"
  type        = string
}

variable "image_version" {
  description = "Commit hash i.e. git rev-parse --short HEAD"
  type        = string
}

variable "cpu" {
  description = "the amount of cpu (cpu units) the task will use/require"
  type        = number
}

variable "memory" {
  description = "the amount of memory (MB) the task will use/require"
  type        = number
}

variable "schedule" {
  description = "a cloudwatch events schedule expression which to run the task on"
  type        = string
}

variable "environment_vars" {
  description = "the environment vars to configure for the task, a map of env var name to value"
  default     = {}
  type        = map(string)
}

variable "vpc_id" {
  description = "the id of the VPC in which this service will reside"
  type        = string
}

variable "subnet_ids" {
  description = "the list of subnets in which the service should be provisioned"
  type        = list(string)
}

variable "cluster_arn" {
  description = "arn of the ecs cluster to provision task"
  type        = string
}

variable "security_group_id" {
  description = "id of the security group to associated to ecs cluster tasks"
  type        = string
}