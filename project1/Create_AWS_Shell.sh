#!/bin/bash
# Creating VPC and printing VPC_ID
VPC=$(aws ec2 create-vpc \
    --cidr-block "172.16.0.0/16" \
    --tag-specification ResourceType=vpc,Tags='[{Key="project",Value="wecloud"},{Key="Name",Value="VPC1"}]')
VPC_ID=$(echo $VPC | grep vpc | awk '{ print $8}')
echo $VPC_ID

# Creating Internet Gateway
IGW=$(aws ec2 create-internet-gateway \
    --tag-specifications ResourceType=internet-gateway,Tags='[{Key="project",Value="wecloud"},{Key="Name",Value="IGW1"}]')
IGW_ID=$(echo $IGW | awk '{print $2}')
echo $IGW_ID

# Attaching Internet Gateway to the VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

# Creating public subnet
Subnet=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block "172.16.1.0/24" \
    --tag-specifications ResourceType=subnet,Tags='[{Key="project",Value="wecloud"},{Key="Name",Value="Public-Subnet"}]')
Subnet_ID=$(echo $Subnet | grep subnet | awk '{print $14}')
echo $Subnet_ID

# Enabling auto-assign public IP on public subnet
aws ec2 modify-subnet-attribute \
    --subnet-id $Subnet_ID \
    --map-public-ip-on-launch

# Creating Route table for public subnet
RouteTable=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications ResourceType=route-table,Tags='[{Key="project",Value="wecloud"},{Key="Name",Value="Public_RouteTable"}]')
RouteTable_ID=$(echo $RouteTable | awk '{print $3}')
echo $RouteTable_ID

# Creating Routing rule to Internet gateway
aws ec2 create-route \
    --route-table-id $RouteTable_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

# Associating public subnet with the public route table
Associate_RT=$(aws ec2 associate-route-table \
    --subnet-id $Subnet_ID \
    --route-table-id $RouteTable_ID)

# Creating Security group
SG=$(aws ec2 create-security-group \
    --group-name MySecurityGroup \
    --vpc-id $VPC_ID \
    --description "My Security Group" \
    --tag-specifications ResourceType=security-group,Tags='[{Key="project",Value="wecloud"},{Key="Name",Value="SG"}]')
SG_ID=$(echo $SG | awk '{print $1}')
echo $SG_ID

# Creating firewall rule - Allow SSH traffic 
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Creating firewall rule - Allow ICMP traffic 
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol icmp \
    --port -1 \
    --cidr 0.0.0.0/0

# Creating Keypair
MyKeyPair=$(aws ec2 create-key-pair \
    --key-name "MyKeyPair" \
    --query 'KeyMaterial' \
    --output text)
echo $MyKeyPair > MyKeyPair

# Creating EC2 instances - Master Node rule
MasterNode1=$(aws ec2 run-instances \
    --image-id ami-0261755bbcb8c4a84 \
    --instance-type t2.small \
    --subnet-id $Subnet_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --user-data file://text.txt \
    --tag-specifications ResourceType=instance,Tags='[{Key="Name",Value="Master-Node-01"}]')
    
# Creating Worker Node1
WorkerNode1=$(aws ec2 run-instances \
    --image-id ami-0261755bbcb8c4a84 \
    --instance-type t2.micro \
    --subnet-id $Subnet_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --user-data file://text.txt \
    --tag-specifications ResourceType=instance,Tags='[{Key="Name",Value="Worker-Node-01"}]')

# Creating Worker Node2
WorkerNode2=$(aws ec2 run-instances \
    --image-id ami-0261755bbcb8c4a84 \
    --instance-type t2.micro \
    --subnet-id $Subnet_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --user-data file://text.txt \
    --tag-specifications ResourceType=instance,Tags='[{Key="Name",Value="Worker-Node-02"}]')


