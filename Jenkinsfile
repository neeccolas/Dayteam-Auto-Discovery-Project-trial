pipeline {
  agent any
  tools {
    terraform 'terraform'
  }
  stages {
    stage('trivy scan') {
      steps {
        sh 'trivy fs --scanners misconfig .' // . to mean current directory
      }
    }
    stage('terraform init') {
      steps {
        sh 'terraform init'
      }
    }
    stage('terraform format') {
      steps {
        sh 'terraform fmt --recursive'
      }
    }
    stage('terraform validate') {
      steps {
        sh 'terraform validate'
      }
    }
    stage('terraform plan') {
      steps {
        sh 'terraform plan'
      }
    }
    stage('terraform action') {
      steps {
        sh 'terraform ${action} -auto-approve'
      }
    }
  }
}