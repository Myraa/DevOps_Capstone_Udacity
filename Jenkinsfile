#!/usr/bin/env groovy

properties([
    parameters(
        [
            string(defaultValue: "master", description: 'Which Git Branch to clone?', name: 'GIT_BRANCH'),
            string(defaultValue: "477498628656", description: 'AWS Account Number?', name: 'ACCOUNT'),
            string(defaultValue: "devopscapstoneudacity", description: 'AWS ECR Repository where built docker images will be pushed.', name: 'ECR_REPO_NAME')
        ]
    )
])
try{

    stage('clone repository'){
        node('master'){
            cleanWs()
            checkout scm
        }

    }
    stage('Lint HTML'){
        node{
            sh 'tidy -q -e *.html'
        }
        
    }
    stage('Build Docker image'){
        node('master'){
            withAWS(credentials: 'blueocean', region: 'us-east-1'){
            sh "\$(aws ecr get-login --no-include-email --region us-east-1)"
            GIT_COMMIT_ID = sh (
                script: 'git log -1 --pretty=%H',
                returnStdout: true
            ).trim()
            TIMESTAMP = sh(
                script: 'date +%Y%m%d%H%M%S',
                returnStdout: true
            ).trim()
            echo "Git commit Id: $GIT_COMMIT_ID"
            IMAGETAG = "${GIT_COMMIT_ID}-${TIMESTAMP}"
            sh "docker build -t ${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${ECR_REPO_NAME}:${IMAGETAG} ."
            sh "docker push ${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${ECR_REPO_NAME}:${IMAGETAG}"

            }

        }
            
    }
    stage('Deploy on Dev'){
        node('master'){
            withAWS(credentials: 'blueocean', region: 'us-east-1'){
            withEnv(["JENKINS_HOME=/home/jenkins","KUBECONFIG=${JENKINS_HOME}/.kube/dev-config","IMAGE=${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${ECR_REPO_NAME}:${IMAGETAG}"]){
        	sh "echo jenkins home is ${JENKINS_HOME}"
            sh "echo kubeconfig is ${KUBECONFIG}"
            sh "kubectl config current-context"
            sh "sed -i 's|IMAGE|${IMAGE}|g' k8s/deployment.yaml"
            sh "sed -i 's|IMAGE|${IMAGE}|g' k8s/deployment.yaml"
        	sh "sed -i 's|ENVIRONMENT|dev|g' k8s/*.yaml"
        	sh "sed -i 's|BUILD_NUMBER|01|g' k8s/*.yaml"
        	sh "kubectl apply -f k8s"
            DEPLOYMENT = sh (
          		script: 'cat k8s/deployment.yaml | yq -r .metadata.name',
          		returnStdout: true
        	).trim()
        	echo "Creating k8s resources..."
        	sleep 180
        	DESIRED= sh (
          		script: "kubectl get deployment/$DEPLOYMENT | awk '{print \$2}' | grep -v DESIRED",
          		returnStdout: true
         	).trim()
        	CURRENT= sh (
          		script: "kubectl get deployment/$DEPLOYMENT | awk '{print \$3}' | grep -v CURRENT",
          		returnStdout: true
         	).trim()
            if (DESIRED.equals(CURRENT)) {
          		currentBuild.result = "SUCCESS"
          		return
        	} else {
          		error("Deployment Unsuccessful.")
          		currentBuild.result = "FAILURE"
          		return
        	} 

            }
        
        }
        }
    }

    
}
catch(err){
    currentBuild.result = "FAILURE"
    throw err
}