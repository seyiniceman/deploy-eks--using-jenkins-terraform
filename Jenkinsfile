pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "eu-west-1"
        CLUSTER_NAME       = "myapp-eks-cluster"
    }

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Action') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh """
                    # APPLY (default)
                   # terraform apply -auto-approve -input=false

                    # DESTROY (uncomment when needed)
                      terraform destroy -auto-approve -input=false
                    """
                }
            }
        }

        stage('Update kubeconfig & Verify (Apply Only)') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh """
                    # Only relevant after APPLY
                    aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${CLUSTER_NAME}

                    sed -i 's/v1alpha1/v1beta1/g' ~/.kube/config

                    kubectl get nodes
                    kubectl get pods -A
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed'
        }
    }
}
