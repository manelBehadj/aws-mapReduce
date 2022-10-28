set -e

# import cli cmd functions
source utils/cli_helper.sh

function setup {
    if [[ -f "backup.txt" ]]; then
        rm -f keypair.pem
    fi

    #Setup network security
    create_security_group
    create_keypair

    #Setup EC2 instances
    SUBNETS_1=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output text)    
    
    echo "Launch EC2 instance..."
    INSTANCE_ID = $(launch_ec2_instance $SUBNETS_2 "m4.large")

    echo "Waiting for instance to complete initialization...."
    aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
    INSTANCE_DNS=$(get_ec2_public_dns $INSTANCE_ID)
}

function comparaison {
    scp -i lab_key.pem pg4300.txt ubuntu@$INSTANCE_DNS:/home/ubuntu

    ssh -i lab_key.pem ubuntu@$INSTANCE_DNS  '{ time cat /home/ubuntu/pg4300.txt |tr " " "\n" | sort | uniq -c ; }' 2>> outputs/linux_time.txt

    ssh -i lab_key.pem ubuntu@$INSTANCE_DNS 'bash -s' < run_hadoop.sh 2>> outputs/hadoop_time.txt

    ssh -i lab_key.pem ubuntu@$INSTANCE_DNS 'bash -s' < run_spark.sh 2>> outputs/spark_time.txt
}

# Main
setup
comparaison