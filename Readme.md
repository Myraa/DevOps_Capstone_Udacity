## Setup:
* Kubernetes Clusters (i.e. Dev and Prod) running on AWS EKS
* Cluster Version: 1.11
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