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
        sh 'tidy -q -e *.html'
    }
    stage('Build Docker image'){
        node{
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
    
}
catch(err){
    currentBuild.result = "FAILURE"
    throw err
}