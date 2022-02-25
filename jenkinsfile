pipeline{

    environment{
        IMAGE_NAME = "ic-webapp"
        IMAGE_TAG = "${BUILD_TAG}"
        USERNAME = "sadofrazer"
        CONTAINER_NAME = "ic-webapp-test"
        STAGING_HOST = ""
        PROD_HOST =""
    }

    agent any

    stages{

        stage ('Build image'){
            agent{ label 'test'}
            steps{
                script{
                    sh '''
                      read IMAGE_TAG <<< $(awk '/version/ {sub(/^.* *version/,""); print $2}' releases.txt)
                      docker build -t ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage ('Run a container and Test Image'){
            agent{ label 'test'}
            steps{
                script{
                    sh '''
                       docker stop ${CONTAINER_NAME} || true
                       docker rm ${CONTAINER_NAME} || true
                       docker run -d --name ${CONTAINER_NAME} -p 8080:8080 ${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                       sleep 5
                       curl http://localhost:8080 | grep -iq "IC GROUP"
                    '''
                }
            }
        }

        stage ('save artifact and clean env'){
            agent{ label 'test'}
            environment{
                PASSWORD = credentials('dockerhub_password')
            }
            steps{
                script{
                    sh '''
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
                PGADMIN_PORT = ""
                ODOO_PORT = ""
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ec2_private_key", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    script{	
                        sh '''
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker stop $CONTAINER_NAME || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker rm $CONTAINER_NAME || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker image prune -a || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker run --name $CONTAINER_NAME -d -e PORT=5000 -p 5000:5000 $USERNAME/$IMAGE_NAME:$IMAGE_TAG 
                        '''
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
                PGADMIN_PORT = ""
                ODOO_PORT = ""
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ec2_private_key", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    script{
                        timeout(time: 15, unit: "MINUTES") {
                                input message: 'Do you want to approve the deploy in production?', ok: 'Yes'
                        }	
                        sh '''
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker stop $CONTAINER_NAME || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker rm $CONTAINER_NAME || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker image prune -a || true
                           ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${HOST_IP} docker run --name $CONTAINER_NAME -d -e PORT=5000 -p 5000:5000 $USERNAME/$IMAGE_NAME:$IMAGE_TAG 
                        '''
                    }
                }
            }
        }

    }

}