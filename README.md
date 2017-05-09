### Create a VPC for DMZ purposes

*How to deploy*

Plan

```
terraform plan -var main_vpc_id=vpc-dea471b8 -var peer_vpc_cidr=100.64.0.0/24
```

Todo: 
- Autoscaling group of 1
- Userdata bash script for IPTables
