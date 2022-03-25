pipeline {
    agent any
    tools {
        terraform 'terraform'
    }
	environment {
        GOOGLE_APPLICATION_CREDENTIALS     = credentials('gcp-secret-key-id')
    }
    stages{
        stage('Terraform Init'){
            steps{
                sh label: '',script: 'terraform init'
            }
        }
	stage('Terraform Plan'){
            steps{
                sh label: '',script: 'terraform plan'
            }
        }
        stage('Terraform Apply'){
            steps{
                sh label: '',script: 'terraform apply --auto-approve'
            }
	stage('Terraform Destroy'){
            steps{
                sh label: '',script: 'terraform destroy'
            }
        }
    }
  }
}
