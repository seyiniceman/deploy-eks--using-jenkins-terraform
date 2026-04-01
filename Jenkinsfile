pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "eu-west-1"
        CLUSTER_NAME       = "myapp-eks-cluster"
        TF_VAR_aws_profile = "" 
    }

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform apply -auto-approve -input=false'
                }
            }
        }

        stage('Update kubeconfig & Verify') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    # Force the AWS CLI to generate a v1beta1 config
                    aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${CLUSTER_NAME}

                    # If the above still fails, manually fix the config file API version
                    sed -i 's/v1alpha1/v1beta1/g' ~/.kube/config

                    kubectl get nodes
                    kubectl get pods -A
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
