pipeline{

    environment{
        IMAGE_NAME = "ic-webapp"
        IMAGE_TAG = "${sh(script:'awk \'/version/ {sub(/^.* *version/,""); print $2}\' releases.txt', returnStdout: true).trim()}"
        USERNAME = "sadofrazer"
        CONTAINER_NAME = "ic-webapp-test"
        STAGING_HOST = "20.228.192.173"
        PROD_HOST = "20.228.192.173"
        ODOO_URL = "${sh(script:'awk \'/ODOO_URL/ {sub(/^.* *ODOO_URL/,""); print $2}\' releases.txt', returnStdout: true).trim()}"
        PGADMIN_URL = "${sh(script:'awk \'/PGADMIN_URL/ {sub(/^.* *PGADMIN_URL/,""); print $2}\' releases.txt', returnStdout: true).trim()}"
        DEPLOY_APP = "${sh(script:'awk \'/deploy_app/ {sub(/^.* *deploy_app/,""); print $2}\' releases.txt', returnStdout: true).trim()}"
    }

    agent any

    stages{

        stage ('Build Image'){
            steps{
                script{
                    sh '''#!/bin/bash
                       docker build -t ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
                       docker build -t ansible-ubuntu ./ansible
                    '''
                }
            }
        }

        stage ('Run a container and Test Image'){
            steps{
                script{
                    sh '''#!/bin/bash
                       docker stop ${CONTAINER_NAME} || true
                       docker rm ${CONTAINER_NAME} || true
                       docker run -d --name ${CONTAINER_NAME} -p 8085:8080 ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                       sleep 5
                       curl http://localhost:8085 | grep -iq "IC GROUP"
                    '''
                }
            }
        }

        stage ('save artifact and clean env'){
            environment{
                PASSWORD = credentials('dockerhub_password')
            }
            steps{
                script{
                    sh '''#!/bin/bash
                       docker login -u ${USERNAME} -p ${PASSWORD}
                       docker push ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                       docker stop ${CONTAINER_NAME}
                       docker rm ${CONTAINER_NAME}
                       docker rmi ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                       docker logout
                    '''
                }
            }
        }

        stage ('Deploy staging infra'){
            
            steps{
                withCredentials([file(credentialsId: 'aws_credentials', variable: 'FILE')]) {
                    script{
                        sh '''#!/bin/bash
                            ls $HOME/.aws || mkdir $HOME/.aws
                            cp $FILE $HOME/.aws/credentials
                            cd terraform
                            terraform --version || curl https://releases.hashicorp.com/terraform/1.1.7/terraform_1.1.7_linux_amd64.zip > terraform.zip
                            terraform --version || unzip terraform.zip
                            terraform --version || chmod +x terraform
                            terraform --version || mv terraform /usr/sbin/terraform
                            terraform --version
                            cd staging
                            terraform init --reconfigure
                            terraform apply --auto-approve
                            terraform output --raw ec2_public_ip
                            terraform output --raw ec2_public_ip > $HOME/.aws/public_ip.txt
                        '''
                    }
                }
            }
        }

        stage ('deploy app on Staging env'){
            agent any
            when {
                expression { GIT_BRANCH == 'origin/terraform-feat'}
            }
            environment{
                HOST_IP = sh(script:'cat $HOME/.aws/public_ip.txt', returnStdout: true).trim()
                PGADMIN_PORT = "8082"
                ODOO_PORT = "8081"
                IC_PORT = "80"
                HOST_USER = "ubuntu"
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ec2_private_key", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    script{	
                        if ( env.DEPLOY_APP == "yes"){
                            sh '''#!/bin/bash
                                echo "deploy_app=${DEPLOY_APP}"
                                echo $HOST_IP
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker stop ${CONTAINER_NAME} || true"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker rm ${CONTAINER_NAME} || true"
                                cd ansible
                                ansible --version || sudo apt install ansible -y || yum install epel-release ansible -y
                                ansible-playbook -i hosts.yml ic-play.yml -e ansible_user=${HOST_USER} -e IC_IMAGE_NAME=${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} -e HOST_IP=${HOST_IP} --private-key ${keyfile}
                            '''
                        }
                        else if ( env.DEPLOY_APP == "no"){
                            echo "ODOO_URL = ${env.ODOO_URL} et PGADMIN_URL= ${env.PGADMIN_URL}"
                            sh '''#!/bin/bash
                                echo "deploy_app=${DEPLOY_APP}"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker stop ${CONTAINER_NAME} || true"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker rm ${CONTAINER_NAME} || true"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker run -d --name ${CONTAINER_NAME} -p ${IC_PORT}:8080 -e ODOO_URL=${ODOO_URL} -e PGADMIN_URL=${PGADMIN_URL} ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} || true"
                            '''  
                        }

                        else {
                            sh 'echo the Deploy_app variable must only be yes or no'
                            sh 'echo "deploy_app=${DEPLOY_APP}"'
                        }
                        
                    }
                }
            }
        }

        stage ('Deploy prod infra'){
            
            steps{
                withCredentials([file(credentialsId: 'aws_credentials', variable: 'FILE')]) {
                    script{
                        timeout(time: 15, unit: "MINUTES") {
                            input message: 'Do you want to approve the deploy in production?', ok: 'Yes'
                        }
                        sh '''#!/bin/bash
                            ls $HOME/.aws || mkdir $HOME/.aws
                            cp $FILE $HOME/.aws/credentials
                            cd terraform
                            terraform --version || curl https://releases.hashicorp.com/terraform/1.1.7/terraform_1.1.7_linux_amd64.zip > terraform.zip
                            terraform --version || unzip terraform.zip
                            terraform --version || chmod +x terraform
                            terraform --version || mv terraform /usr/sbin/terraform
                            terraform --version
                            cd staging && terraform init -reconfigure && terraform destroy -auto-approve
                            cd ../prod
                            terraform init --reconfigure
                            terraform apply --auto-approve
                            terraform output --raw ec2_public_ip > $HOME/.aws/public_ip.txt
                        '''
                        env.HOST_IP = sh(script:'cat $HOME/.aws/public_ip.txt', returnStdout: true).trim()
                    }
                }
            }
        }

        stage ('deploy app on Prod env'){
            agent {
                docker {
                    image('ansible-ubuntu')
                    args ' -u root'
                }
            }
            when {
                expression { GIT_BRANCH == 'origin/terraform-feat'}
            }
            environment{
                PGADMIN_PORT = "8082"
                ODOO_PORT = "8081"
                IC_PORT = "80"
                HOST_USER = "ubuntu"
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ec2_private_key", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    script{	
                        if ( env.DEPLOY_APP == "yes"){
                            sh '''
                                ansible --version || apt install ansible -y || yum install epel-release ansible -y
                                echo "deploy_app=${DEPLOY_APP}"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker stop ${CONTAINER_NAME} || true"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker rm ${CONTAINER_NAME} || true"
                                cd ansible
                                ansible-playbook -i hosts.yml ic-play.yml -e ansible_user=${HOST_USER} -e IC_IMAGE_NAME=${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} -e HOST_IP=${HOST_IP} --private-key ${keyfile}
                            '''
                        }
                        else if ( env.DEPLOY_APP == "no"){
                            echo "ODOO_URL = ${env.ODOO_URL} et PGADMIN_URL= ${env.PGADMIN_URL}"
                            sh '''#!/bin/bash
                                echo "deploy_app=${DEPLOY_APP}"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker stop ${CONTAINER_NAME} || true"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker rm ${CONTAINER_NAME} || true"
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "docker run -d --name ${CONTAINER_NAME} -p ${IC_PORT}:8080 -e ODOO_URL=${ODOO_URL} -e PGADMIN_URL=${PGADMIN_URL} ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} || true"
                            ''' 
                        }

                        else {
                            sh 'echo the Deploy_app variable must only be yes or no'
                            sh 'echo "deploy_app=${DEPLOY_APP}"'
                        }
                    }
                }
            }
        }

    }

}