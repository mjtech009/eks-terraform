
# ################################ Data source of Route Table entry between STO and TA #############################

# Data Source for Peering connection 

# data "aws_vpc_peering_connection" "peering" {
#   filter {
#     name   = "tag-value"
#     values = ["dev VPC Peering between sto and ta"]
#   }
#   filter {
#     name   = "tag-key"
#     values = ["Name"]
#   }
# }


# ###################################

# # Data Source for sto vpc cidr

# data "aws_vpc" "ta" {
#   filter {
#     name   = "tag-value"
#     values = ["${local.var.customer}-${local.var.env}-${local.var.company}-ta-vpc"]
#   }
#   filter {
#     name   = "tag-key"
#     values = ["Name"]
#   }
# }