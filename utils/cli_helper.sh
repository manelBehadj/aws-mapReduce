#!/bin/bash

function create_security_group {
    echo "Create security group..."
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name hadoop-security-group \
        --description 'Security group for hadoop lab' \
        --query 'GroupId' \
        --output text)
        
    echo "SECURITY_GROUP_ID=\"$SECURITY_GROUP_ID\"" >>backup.txt    
    add_security_ingress_rules '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]},{"IpProtocol": "tcp", "FromPort": 8080, "ToPort": 8080, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'
    echo "Done"
}

function add_security_ingress_rules {
    echo "Add ingress rules"
    local rules_permissions=$1
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --ip-permissions "${rules_permissions}"
}

function create_keypair {
    echo "Create a key-pair... "
    aws ec2 create-key-pair --key-name keypair --query 'KeyMaterial' --output text >keypair.pem
    ## Change access to key pair to make it secure
    chmod 400 keypair.pem
    echo "Done"
}

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

function get_ec2_public_dns {
    local instance_id=$1
    aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Reservations[].Instances[].PublicDnsName' \
    --output text
}

function delete_security_group {
    local security_group_id=$1
    aws ec2 delete-security-group --group-id $security_group_id
}

