pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "eu-west-1"
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

        stage('Destroy EKS Infrastructure') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    // This will remove all 62 resources created today
                    sh 'terraform destroy -auto-approve -input=false'
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
