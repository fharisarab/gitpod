variable "cluster" {
  type = object({
    name = string
  })
  default = {
    name = "gitpod-cluster"
  }
}
