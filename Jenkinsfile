pipeline {
    agent any
    
    environment{
        DOCKER_TAG = getDockerTag()
        NEXUS_URL  = "localhost:8082"
        IMAGE_URL_WITH_TAG = "${NEXUS_URL}/node-app:${DOCKER_TAG}"
        IMAGE_WITH_DOCKER_TAG = "ashishvkumar/nodeapp:${DOCKER_TAG}"
    }
    
    stages{
        stage('Build Docker Image'){
            steps{
                // sh "docker build . -t ashishvkumar/nodeapp:${DOCKER_TAG}"
                sh "docker build . -t ${IMAGE_URL_WITH_TAG}"
                sh "docker tag ${IMAGE_URL_WITH_TAG} ${IMAGE_WITH_DOCKER_TAG}"
            }
        }
    
    
        stage('Docker push'){
            steps{
                withCredentials([string(credentialsId: 'dockerhub', variable: 'dockerhubPwd')]) {
                    sh "docker login -u ashishvkumar -p${dockerhubPwd}"
                }
                sh "docker push ashishvkumar/nodeapp:${DOCKER_TAG}"
            }
        }
    
        stage('Nexus Push'){
            steps{
                withCredentials([string(credentialsId: 'nexus-pwd', variable: 'nexusPwd')]) {
                    sh "docker login -u admin -p ${nexusPwd} ${NEXUS_URL}"
                    sh "docker push ${IMAGE_URL_WITH_TAG}"
                }
            }
        }
    
        stage('Deploy to K8S'){
            steps{
                sh "chmod +x changeTag.sh"
                sh "./changeTag.sh ${DOCKER_TAG}"
                sshagent(['tomcat-dev']) {
                    sh "scp -o StrictHostKeyChecking=no services.yml node-app-pod.yml jenkins@localhost:/var/lib/jenkins/node-app/" 
                    script{
                        try{
                            sh "ssh jenkins@localhost 'kubectl apply -f node-app/'"
                        }catch(error){
                            sh "ssh jenkins@localhost 'kubectl create -f node-app/'"
                        }
                    }
                }
            }
        }
    
        stage('Docker Deploy Dev'){
            steps{
                sshagent(['tomcat-dev']) {
                    withCredentials([string(credentialsId: 'nexus-pwd', variable: 'nexusPwd')]) {
                        sh "ssh jenkins@localhost docker login -u admin -p ${nexusPwd} ${NEXUS_URL}"
                    }
				    // Remove existing container, if container name does not exists still proceed with the build
                    sh script: "ssh jenkins@localhost docker rm -f nodeapp",  returnStatus: true
                    sh "ssh jenkins@localhost docker run -d -p 8085:8080 --name nodeapp ${IMAGE_URL_WITH_TAG}"
                }
            }
        }

    }
}

def getDockerTag(){
    def tag  = sh script: 'git rev-parse --short HEAD', returnStdout: true
    return tag
}
