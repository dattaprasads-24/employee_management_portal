pipeline {
    agent any

    environment {
        //  Your actual AWS Instance IDs
        FRONTEND_INSTANCE_ID = 'i-0d2002d9b502e5122'
        BACKEND_INSTANCE_ID  = 'i-0b06dd88bc9d33be5'
        DATABASE_INSTANCE_ID = 'i-087b8a625d86269bc'

        AWS_REGION           = 'ap-south-1' // Mumbai Region
        DOCKER_HUB_USER      = 'dattaprasads01'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Fetching the latest code from GitHub...'
                checkout scm
            }
        }

        stage('Build & Push Backend') {
            steps {
                echo 'Building and pushing backend Docker image...'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    // 🪄 Single quotes ensure special characters in password are handled perfectly without shell parsing errors
                    sh 'echo "$PASS" | docker login -u "$USER" --password-stdin'
                    sh "cd backend && docker build --no-cache -t ${DOCKER_HUB_USER}/employee-backend:latest ."
                    sh "docker push ${DOCKER_HUB_USER}/employee-backend:latest"
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                echo 'Building and pushing frontend Docker image...'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    // 🪄 Secure stdin method applied to frontend stage as well
                    sh 'echo "$PASS" | docker login -u "$USER" --password-stdin'
                    sh "cd frontend && docker build --no-cache -t ${DOCKER_HUB_USER}/employee-frontend:latest ."
                    sh "docker push ${DOCKER_HUB_USER}/employee-frontend:latest"
                }
            }
        }

        stage('Deploy to Database Server') {
            steps {
                echo 'Deploying database container via AWS SSM...'
                sh """
                aws ssm send-command \
                    --instance-ids "${DATABASE_INSTANCE_ID}" \
                    --region "${AWS_REGION}" \
                    --document-name "AWS-RunShellScript" \
                    --parameters 'commands=[
                        "sudo docker stop mysql-db || true",
                        "sudo docker rm mysql-db || true",
                        "sudo docker run -d --name mysql-db -p 3306:3306 -e MYSQL_ROOT_PASSWORD=RootPassword123 -e MYSQL_DATABASE=employee_db -e MYSQL_USER=employee_user -e MYSQL_PASSWORD=EmployeePassword123 -v /home/ubuntu/employee_management_portal/database/init.sql:/docker-entrypoint-initdb.d/init.sql mysql:8.0"
                    ]'
                """
            }
        }

        stage('Deploy to Backend Server') {
            steps {
                echo 'Deploying latest backend container via AWS SSM...'
                sh """
                aws ssm send-command \
                    --instance-ids "${BACKEND_INSTANCE_ID}" \
                    --region "${AWS_REGION}" \
                    --document-name "AWS-RunShellScript" \
                    --parameters 'commands=[
                        "sudo docker pull ${DOCKER_HUB_USER}/employee-backend:latest",
                        "sudo docker stop backend-app || true",
                        "sudo docker rm backend-app || true",
                        "sudo docker run -d --name backend-app -p 5000:5000 ${DOCKER_HUB_USER}/employee-backend:latest"
                    ]'
                """
            }
        }

        stage('Deploy to Frontend Server') {
            steps {
                echo 'Deploying latest frontend container via AWS SSM...'
                sh """
                aws ssm send-command \
                    --instance-ids "${FRONTEND_INSTANCE_ID}" \
                    --region "${AWS_REGION}" \
                    --document-name "AWS-RunShellScript" \
                    --parameters 'commands=[
                        "sudo docker pull ${DOCKER_HUB_USER}/employee-frontend:latest",
                        "sudo docker stop frontend-app || true",
                        "sudo docker rm frontend-app || true",
                        "sudo docker run -d --name frontend-app -p 80:80 ${DOCKER_HUB_USER}/employee-frontend:latest"
                    ]'
                """
            }
        }
    }

    post {
        success {
            echo 'Success: Complete 3-tier application deployed successfully via automated pipeline!'
        }
        failure {
            echo 'Error: Pipeline failed. Please check the console logs for debugging.'
        }
    }
}
