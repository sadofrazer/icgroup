pipeline{

    environment{
        IMAGE_NAME = "ic-webapp"
        IMAGE_TAG = "${BUILD_TAG}"
        USERNAME = "sadofrazer"
        CONTAINER_NAME = "ic-webapp-test"
        STAGING_HOST = "54.175.114.236"
        PROD_HOST = "54.175.114.236"
        DEPLOY_APP = "no"
    }

    agent any

    stages{

        stage ('Build Image'){
            steps{
                script{
                    sh '''#!/bin/bash
                       read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
                       docker build -t ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage ('Run a container and Test Image'){
            steps{
                script{
                    sh '''#!/bin/bash
                       read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
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
                       read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
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
        stage ('deploy app on Staging env'){
            agent any
            when {
                expression { GIT_BRANCH == 'origin/master'}
            }
            environment{
                HOST_IP = "${STAGING_HOST}"
                PGADMIN_PORT = "8082"
                ODOO_PORT = "8081"
                IC_PORT = "8080"
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ec2_private_key", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    script{	
                        sh '''#!/bin/bash
                           read DEPLOY_APP <<< $(awk '/deploy_app/ {sub(/^.* *deploy_app/,""); print $2}' releases.txt)
                           echo ${DEPLOY_APP}
                        '''
                        if ( env.DEPLOY_APP == "yes"){
                            sh '''#!/bin/bash
                                read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "echo -e 'HOST_IP=${HOST_IP}\nPGADMIN_PORT=${PGADMIN_PORT}\nODOO_PORT=${ODOO_PORT}\nIC_PORT=${IC_PORT}\nUSERNAME=${USERNAME}\nIMAGE_NAME=${IMAGE_NAME}\nIMAGE_TAG=${IMAGE_TAG}' > /home/ubuntu/.env"
                                scp -o StrictHostKeyChecking=no -i ${keyfile} $(pwd)/docker-compose.yml ${NUSER}@${HOST_IP}:/home/ubuntu/docker-compose.yml
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker stop ${CONTAINER_NAME} || true
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker rm ${CONTAINER_NAME} || true
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} cd /home/ubuntu && docker-compose down || true
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} cd /home/ubuntu &&docker-compose up -d
                            '''
                        }
                        else if ( env.DEPLOY_APP == "no"){
                            sh '''#!/bin/bash
                                read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
                                read ODOO_URL <<< $(awk '/ODOO_URL/ {sub(/^.* *ODOO_URL/,""); print $2}' releases.txt)
                                read PGADMIN_URL <<< $(awk '/PGADMIN_URL/ {sub(/^.* *PGADMIN_URL/,""); print $2}' releases.txt)
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker stop ${CONTAINER_NAME} || true
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker rm ${CONTAINER_NAME} || true
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker run -d --name ${CONTAINER_NAME} -p 8085:8080 -e ODOO_URL=${ODOO_URL} -e PGADMIN_URL=${PGADMIN_URL} ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} || true
                            '''  
                        }

                        else {
                            sh 'echo the Deploy_app variable must only be yes or no'
                            sh 'echo ${DEPLOY_APP}'
                        }
                        
                    }
                }
            }
        }

        stage ('deploy app on Prod env'){
            agent any
            when {
                expression { GIT_BRANCH == 'origin/master'}
            }
            environment{
                HOST_IP = "${STAGING_HOST}"
                PGADMIN_PORT = "8082"
                ODOO_PORT = "8081"
                IC_PORT = "8080"
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ec2_private_key", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    script{
                        timeout(time: 15, unit: "MINUTES") {
                                input message: 'Do you want to approve the deploy in production?', ok: 'Yes'
                        }	
                        sh '''#!/bin/bash
                           read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} "echo -e 'HOST_IP=${HOST_IP}\nPGADMIN_PORT=${PGADMIN_PORT}\nODOO_PORT=${ODOO_PORT}\nIC_PORT=${IC_PORT}\nUSERNAME=${USERNAME}\nIMAGE_NAME=${IMAGE_NAME}\nIMAGE_TAG=${IMAGE_TAG}' > /home/ubuntu/.env"
                           scp -o StrictHostKeyChecking=no -i ${keyfile} $(pwd)/docker-compose.yml ${NUSER}@${HOST_IP}:/home/ubuntu/docker-compose.yml 
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker stop ${CONTAINER_NAME} || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker rm ${CONTAINER_NAME} || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} cd /home/ubuntu && docker-compose down || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} cd /home/ubuntu && docker-compose up -d
                        '''
                    }
                }
            }
        }

    }

}