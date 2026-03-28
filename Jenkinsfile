pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "eu-west-1"
        CLUSTER_NAME = "myapp-eks-cluster"
    }

    stages {

        stage('Provision EKS Cluster') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {

                    sh '''
                    terraform init
                    terraform plan
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        // 🔴 VERY IMPORTANT
        stage('Wait for EKS Cluster') {
            steps {
                sh '''
                echo "Waiting for EKS cluster to be ACTIVE..."
                aws eks wait cluster-active \
                --region $AWS_DEFAULT_REGION \
                --name $CLUSTER_NAME
                '''
            }
        }

        stage('Update kubeconfig') {
            steps {
                sh '''
                aws eks update-kubeconfig \
                --region $AWS_DEFAULT_REGION \
                --name $CLUSTER_NAME
                '''
            }
        }

        stage('Verify Cluster') {
            steps {
                sh 'kubectl get nodes'
            }
        }

        // 🔥 NEXT STEP (you can enable later)
        // stage('Deploy App') {
        //     steps {
        //         sh 'kubectl apply -f k8s/'
        //     }
        // }

    }
}
