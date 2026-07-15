pipeline {
    agent any

    environment {
        // 1. AWS Instance IDs
        DB_INSTANCE_ID       = 'i-05c0050be3334e158'
        BACKEND_INSTANCE_ID  = 'i-0c5e9f6b1a4517f61'
        FRONTEND_INSTANCE_ID = 'i-0c5e9f6b1a4517f61'
        AWS_DEFAULT_REGION   = 'ap-south-1'

        // 2. Docker Hub Configuration 
        DOCKER_HUB_USER      = 'dattaprasads01'
        
        // Credentials ID from Jenkins
        DOCKER_CREDS_ID      = 'docker-hub-creds'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/dattaprasads-24/employee_management_portal.git'
            }
        }

        stage('Build & Push Images to Docker Hub') {
            steps {
                script {
                    echo "Logging into Docker Hub..."
                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_CREDS_ID}", passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    }

                    echo "Building and Pushing Backend Image..."
                    sh "docker build -t ${env.DOCKER_HUB_USER}/employee-backend:latest ./backend"
                    sh "docker push ${env.DOCKER_HUB_USER}/employee-backend:latest"

                    echo "Building and Pushing Frontend Image..."
                    sh "docker build -t ${env.DOCKER_HUB_USER}/employee-frontend:latest ./frontend"
                    sh "docker push ${env.DOCKER_HUB_USER}/employee-frontend:latest"
                }
            }
        }

        stage('Deploy Database') {
            steps {
                script {
                    echo "Deploying Database Container via SSM..."
                    sh """
                    aws ssm send-command \
                        --instance-ids "${DB_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "docker stop mysql-db || true",
                            "docker rm mysql-db || true",
                            "docker run -d --name mysql-db -p 3306:3306 -e MYSQL_ROOT_PASSWORD=RootPassword123 -e MYSQL_DATABASE=employee_db -e MYSQL_USER=employee_user -e MYSQL_PASSWORD=EmployeePassword123 mysql:8.0"
                        ]'
                    """
                }
            }
        }

        stage('Deploy Backend via Pull') {
            steps {
                script {
                    echo "Pulling and Running Backend Container via SSM..."
                    sh """
                    aws ssm send-command \
                        --instance-ids "${BACKEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "docker pull ${env.DOCKER_HUB_USER}/employee-backend:latest",
                            "docker stop backend-app || true",
                            "docker rm backend-app || true",
                            "docker run -d --name backend-app -p 5000:5000 ${env.DOCKER_HUB_USER}/employee-backend:latest"
                        ]'
                    """
                }
            }
        }

        stage('Deploy Frontend via Pull') {
            steps {
                script {
                    echo "Pulling and Running Frontend Container via SSM..."
                    sh """
                    aws ssm send-command \
                        --instance-ids "${FRONTEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "docker pull ${env.DOCKER_HUB_USER}/employee-frontend:latest",
                            "docker stop frontend-app || true",
                            "docker rm frontend-app || true",
                            "docker run -d --name frontend-app -p 80:80 ${env.DOCKER_HUB_USER}/employee-frontend:latest"
                        ]'
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up local Jenkins Docker images..."
            sh "docker logout || true"
        }
    }
}
