#!/usr/bin/env groovy

properties([
    parameters(
        [
            string(defaultValue: "master", description: 'Which Git Branch to clone?', name: 'GIT_BRANCH'),
            string(defaultValue: "477498628656", description: 'AWS Account Number?', name: 'ACCOUNT'),
            string(defaultValue: "devopscapstone-prod-svc", description: 'Blue Service Name to patch in Prod Environment', name: 'PROD_BLUE_SERVICE'),
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
        	sh "sed -i 's|ENVIRONMENT|dev|g' k8s/*.yaml"
        	sh "sed -i 's|BUILD_NUMBER|${BUILD_NUMBER}|g' k8s/*.yaml"
        	sh "kubectl apply -f k8s"
            sh "echo jenkins home is ${JENKINS_HOME}"
            DEPLOYMENT = sh (
          		script: 'cat k8s/deployment.yaml | yq r - metadata.name',
          		returnStdout: true
        	).trim()
        	echo "Creating k8s resources for deployment ${DEPLOYMENT}..."
        	sleep 180
        	DESIRED= sh (
          		script: "kubectl get deployment/$DEPLOYMENT | awk '{print \$2}' | grep -v DESIRED | cut -f2 -d '/'",
          		returnStdout: true
         	).trim()
        	CURRENT= sh (
          		script: "kubectl get deployment/$DEPLOYMENT | awk '{print \$2}' | grep -v CURRENT | cut -f1 -d '/'",
          		returnStdout: true
         	).trim()
             sh "echo Desired deployment is ${DESIRED}"
             sh "echo current deployment is ${CURRENT}"
            if (DESIRED.equals(CURRENT)) {
          		currentBuild.result = "SUCCESS"
          		return
        	} else {
          		error("Deployment Unsuccessful.")
          		currentBuild.result = "FAILURE"
          		return
        	} 
        	echo "Creating k8s resources..."
        	sleep 180

            }
        
            }
        }
    }

    
}
catch(err){
    currentBuild.result = "FAILURE"
    throw err
}

def userInput
try {
	timeout(time: 60, unit: 'SECONDS') {
	userInput = input message: 'Proceed to Production?', parameters: [booleanParam(defaultValue: false, description: 'Ticking this box will do a deployment on Prod', name: 'DEPLOY_TO_PROD'),
                                                                 booleanParam(defaultValue: false, description: 'First Deployment on Prod?', name: 'PROD_BLUE_DEPLOYMENT')]}
}

catch (err) {
    def user = err.getCauses()[0].getUser()
    echo "Aborted by:\n ${user}"
    currentBuild.result = "SUCCESS"
    return
}
    stage('Deploy on Prod'){
        node('master'){
        if (userInput['DEPLOY_TO_PROD'] == true) { 
            withAWS(credentials: 'blueocean', region: 'us-east-1'){
            withEnv(["JENKINS_HOME=/home/jenkins","KUBECONFIG=${JENKINS_HOME}/.kube/prod-config","IMAGE=${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${ECR_REPO_NAME}:${IMAGETAG}"]){
        	sh "echo Deploying to Production..."  
            sh "echo jenkins home is ${JENKINS_HOME}"
            sh "echo kubeconfig is ${KUBECONFIG}"
            sh "kubectl config current-context"
            sh "sed -i 's|IMAGE|${IMAGE}|g' k8s/deployment.yaml"
        	sh "sed -i 's|dev|prod|g' k8s/*.yaml"
        	sh "kubectl apply -f k8s"
            sh "echo jenkins home is ${JENKINS_HOME}"
            
        	echo "Creating k8s resources..."
        	sleep 180

            }
        
            }
        }
        else {
        	echo "Aborted Production Deployment..!!"
        	currentBuild.result = "SUCCESS"
        	return
    	} 
        }
    }

    stage('Validate Prod Green Env') {
        node('master'){
            if (userInput['PROD_BLUE_DEPLOYMENT'] == false) {
                withAWS(credentials: 'blueocean', region: 'us-east-1'){
    	        withEnv(["KUBECONFIG=${JENKINS_HOME}/.kube/prod-config"]){
        	        GREEN_SVC_NAME = sh (
          		        script: "cat k8s/service.yaml | yq r - metadata.name | tr -d '\"'",
          		        returnStdout: true
        	        ).trim()
                    echo "GREEN service Name ${GREEN_SVC_NAME}"
        	        GREEN_LB = sh (
          		    script: "kubectl get svc ${GREEN_SVC_NAME} -o jsonpath=\"{.status.loadBalancer.ingress[*].hostname}\"",
          		    returnStdout: true
        	        ).trim()
        	        echo "Green ENV LB: ${GREEN_LB}"
        	        RESPONSE = sh (
          		        script: "curl -s -o /dev/null -w \"%{http_code}\" http://${GREEN_LB}/index.html -I",
          		        returnStdout: true
        	        ).trim()
         	        if (RESPONSE == "200") {
          		        echo "Application is working fine. Proceeding to patch the service to point to the latest deployment..."
        	        }
        	        else {
          		        echo "Application didnot pass the test case. Not Working"
          		        currentBuild.result = "FAILURE"
        	        }
      	        }
                }  
            }
        }
    }

    stage('Patch Prod Blue Service') {
    node('master'){
      if (userInput['PROD_BLUE_DEPLOYMENT'] == false) {
        withAWS(credentials: 'blueocean', region: 'us-east-1'){
      	withEnv(["KUBECONFIG=${JENKINS_HOME}/.kube/prod-config"]){
        	BLUE_VERSION = sh (
            	script: "kubectl get svc/${PROD_BLUE_SERVICE} -o yaml | yq r - spec.selector.version",
          	returnStdout: true
        	).trim()
        	CMD = "kubectl get deployment -l version=${BLUE_VERSION} | awk '{if(NR>1)print \$1}'"
        	BLUE_DEPLOYMENT_NAME = sh (
            	script: "${CMD}",
          		returnStdout: true
        	).trim()
        	echo "${BLUE_DEPLOYMENT_NAME}"
          	sh """kubectl patch svc  "${PROD_BLUE_SERVICE}" -p '{\"spec\":{\"selector\":{\"app\":\"devopscapstone\",\"version\":\"${BUILD_NUMBER}\"}}}'"""
          	echo "Deleting Blue Environment..."
          	sh "kubectl delete svc ${GREEN_SVC_NAME}"
          	sh "kubectl delete deployment ${BLUE_DEPLOYMENT_NAME}"
      	}
      }
    }
    }
}

