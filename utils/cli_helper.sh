#!/bin/bash


######
## Function that create a security group and add ingress rules
# GLOBALS: 
# 	SECURITY_GROUP_ID : The generated security group id 
# OUTPUTS: 
# 	The generated security group Id
######
function create_security_group {
    echo "Create security group..."
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name hadoop-security-group \
        --description 'Security group for hadoop lab' \
        --query 'GroupId' \
        --output text)

    #Save the returned SECURITY_GROUP_ID as backups    
    echo "SECURITY_GROUP_ID=\"$SECURITY_GROUP_ID\"" >>backup.txt    
    add_security_ingress_rules '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]},{"IpProtocol": "tcp", "FromPort": 8080, "ToPort": 8080, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'
    echo "Done"
}

######
## Function that add ingress rules to an existing security group
# GLOBALS: 
# 	SECURITY_GROUP_ID : The generated security group id 
# ARGUMENTS: 
# 	rules permissions to add
# OUTPUTS: 
# 	Add ingress rules on port 22(ssh) and 8080(spark ui)
######
function add_security_ingress_rules {
    echo "Add ingress rules"
    local rules_permissions=$1
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --ip-permissions "${rules_permissions}"
}

######
## Function that create a keypair and import the key localy
# OUTPUTS: 
# 	Create a key on aws and save the generated key on a local file
######
function create_keypair {
    echo "Create a key-pair... "
    aws ec2 create-key-pair --key-name keypair --query 'KeyMaterial' --output text >keypair.pem
    ## Change access to key pair to make it secure
    chmod 400 keypair.pem
    echo "Done"
}

######
## Function that lanch an ubuntu instance(m4.large)
# GLOBALS: 
# 	SECURITY_GROUP_ID : The generated security group id 
# ARGUMENTS: 
# 	Subnet Id
#   Instance type = m4.large 
#   setup script to install hadoop and spark
# OUTPUTS: 
# 	Create a new instance with spark and hadoop running on it
######
function launch_ec2_instance {
    local subnet=$1
    local instance_type=$2
    aws ec2 run-instances \
        --image-id ami-09e67e426f25ce0d7 \
        --instance-type $instance_type \
        --count 1 \
        --subnet-id $subnet --key-name keypair \
        --monitoring "Enabled=true" \
        --security-group-ids $SECURITY_GROUP_ID \
        --user-data file://config/setup.txt \
        --query 'Instances[*].InstanceId[]' \
        --output text
}

######
## Function that get the public dns of an instance
# ARGUMENTS: 
# 	Created instance id
# OUTPUTS: 
# 	 the public dns value
######
function get_ec2_public_dns {
    local instance_id=$1
    aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Reservations[].Instances[].PublicDnsName' \
    --output text
}

######
## Function that delete a security group
# ARGUMENTS: 
# 	security group id
# OUTPUTS: 
# 	delete the security id 
######
function delete_security_group {
    local security_group_id=$1
    aws ec2 delete-security-group --group-id $security_group_id
}

