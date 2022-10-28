set -e

# import cli cmd functions
source utils/cli_helper.sh

function setup {
    if [[ -f "backup.txt" ]]; then
        rm -f keypair.pem backup.txt
    fi

    #Setup network security
    create_security_group
    create_keypair

    #Setup EC2 instances
    SUBNETS_1=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output text)    
    
    echo "Launch EC2 instance..."
    INSTANCE_ID=$(launch_ec2_instance $SUBNETS_1 "m4.large")
    echo "INSTANCE_ID=\"$INSTANCE_ID\"" >>backup.txt 

    echo "Waiting for instance to complete initialization...."
    aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
    INSTANCE_DNS=$(get_ec2_public_dns $INSTANCE_ID)
}

function comparaison {
    echo "Waiting for spark to be running...."
    while :; do
        curl -s --fail -o /dev/null "http://$INSTANCE_DNS:8080" && break
        sleep 3
    done
    echo "Spark and Hadoop are ready."
    rm -f outputs/*
    scp -i keypair.pem pg4300.txt ubuntu@$INSTANCE_DNS:/home/ubuntu
    ssh -i keypair.pem ubuntu@$INSTANCE_DNS  '{ time cat /home/ubuntu/pg4300.txt |tr " " "\n" | sort | uniq -c ; }' 2>> outputs/linux_time.txt
    ssh -i keypair.pem ubuntu@$INSTANCE_DNS 'bash -s' < run_hadoop.sh 2>> outputs/hadoop_time.txt
    ssh -i keypair.pem ubuntu@$INSTANCE_DNS 'bash -s' < run_spark.sh 2>> outputs/spark_time.txt
}

function wipe {

    source backup.txt

    ## Terminate the ec2 instances
    if [[ -n "${INSTANCE_ID}" ]]; then
        echo "Terminate the ec2 instance..."
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID
        ## Wait for instances to enter 'terminated' state
        echo "Wait for instances to enter 'terminated' state..."
        aws ec2 wait instance-terminated --instance-ids ${CLUSTER_ONE_INSTANCES[@]} ${CLUSTER_TWO_INSTANCES[@]}
        echo "instance terminated"
    fi

    # Delete Key pair
    if [[ -f "backup.txt" ]]; then
        ## Delete key pair
        echo "Delete key pair..."
        aws ec2 delete-key-pair --key-name keypair
        rm -f keypair.pem
        echo "key pair Deleted"
    fi    

    ## Delete custom security group
    if [[ -n "$SECURITY_GROUP_ID" ]]; then
        echo "Delete custom security group..."
        delete_security_group $SECURITY_GROUP_ID
        echo "Security-group deleted"
    fi
}

# Main
setup
comparaison
wipe