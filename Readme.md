## Setup:
* Kubernetes Clusters (i.e. Dev and Prod) running on AWS EKS
* Cluster Version: 1.14
* Docker Registry: AWS ECR
* Application Language: For now, just used a sample index.html file
* CI/CD Tool: Jenkins
## Prerequisites:
* Create an AWS ECR Repo for the Application. For example, app-ecr.
* Provision an EC2 Server with Jenkins Installed on it.
* Ensure yq and curl are installed on the server.
* Install Docker and kubectl on the server.
* Kube config files for both the clusters i.e. Dev and Prod are kept inside .kube directory in Jenkins Home i.e. /var/lib/     jenkins/.kube.
* Execute the below command to get the Kube config file. Copy the contents of the ~/.kube/config and paste in a new file in    Jenkins Home i.e. /var/lib/jenkins/.kube/dev-config. Repeat this step for both the clusters. For Prod config, the config     file is available at /var/lib/jenkins/.kube/prod-config.
```bash
aws eks update-kubeconfig --name <CLUSTER_NAME> --region us-east-1
```  
## WorkFlow
* Create a Pipeline Job with the Jenkinsfile provided in the Github Repo. 
* The pipeline takes following user Inputs
    1.  GIT_BRANCH: Git Branch to use for the application source code.
    2.  ACCOUNT: AWS Account Number.
    3.  PROD_BLUE_SERVICE: If we already have a blue environment, specify the live blue service name in the Prod cluster.        Otherwise, leave blank.
    4.  ECR_REPO_NAME: Name of the existing AWS ECR Repo name where the built docker images will be pushed.
* Once the above parameters provided, it will trigget the following jobs in the pipeline.
    *   Clone - Clones the source code repository
    *   Lint HTML - Lints the index.html
    *   Build Docker Image- Builds the docker image for the app and pushes the image to ECR.
    *   Deploy on Dev-The built image is deployed on the Dev K8s cluster using kubectl. It’s an in-place deployment where        the existing deployment is updated with the docker image.
    *   UserInput-This step needs a manual intervention for proceeding to the Prod environment. Two user inputs are required     here(Note- When you run it for the very first time, make sure you select both check boxes):
        *   DEPLOY_TO_PROD: Tick mark to deploy the built docker image to Prod Cluster.
        *   PROD_BULE_DEPLOYMENT: Tick mark if it’s a fresh deployment on the prod cluster.
    *   Deplot to Prod: If selected to proceed to prod, this step deploys the image on Prod cluster using “kubectl apply”        command. It creates a green deployment and a temporary green LoadBalancer Service.
    *   Validate: This step can contain multiple test cases to validate application functionality. In our case, we have a        sample application(just 1 index.html) for which we have provided a curl command on a specific path to test the           application.
    *   Patch Live Service and Delete Blue: Once validated successfully, this step patches the existing live blue service        using the “kubectl patch” command to point the live service(previously deployed service) to the latest deployment        and delete the blue deployment as well as temporary green service.

