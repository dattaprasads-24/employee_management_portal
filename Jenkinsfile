pipeline {
    agent any

    environment {
        // Replace with your actual AWS EC2 Instance IDs
        DB_INSTANCE_ID       = 'i-05c0050be3334e158'
        BACKEND_INSTANCE_ID  = 'i-07768fb71153b6365'
        FRONTEND_INSTANCE_ID = 'i-0c5e9f6b1a4517f61'
        AWS_DEFAULT_REGION   = 'ap-south-1'
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Fetching the latest code from GitHub repository
                git branch: 'main', url: 'https://github.com/dattaprasads-24/employee_management_portal.git'
            }
        }

        stage('Deploy Database') {
            steps {
                script {
                    echo "Deploying MySQL Container on Database Server..."
                    sh """
                    aws ssm send-command \
                        --instance-ids "${DB_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "apt-get update -y && apt-get install -y docker-ce || true",
                            "docker stop mysql-db || true",
                            "docker rm mysql-db || true",
                            "docker run -d --name mysql-db -p 3306:3306 -e MYSQL_ROOT_PASSWORD=RootPassword123 -e MYSQL_DATABASE=employee_db -e MYSQL_USER=employee_user -e MYSQL_PASSWORD=EmployeePassword123 mysql:8.0"
                        ]'
                    """
                }
            }
        }

        stage('Deploy Backend') {
            steps {
                script {
                    echo "Deploying Backend Container..."
                    // Preparing backend directory structure on target server
                    sh """
                    aws ssm send-command \
                        --instance-ids "${BACKEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "mkdir -p /home/ubuntu/backend",
                            "echo \"FROM node:18-alpine\nWORKDIR /app\nRUN npm init -y && npm install express mysql2 cors\nCOPY server.js .\nEXPOSE 5000\nCMD [\\\"node\\\", \\\"server.js\\\"]\" > /home/ubuntu/backend/Dockerfile"
                        ]'
                    """
                    
                    // Reading server.js from Jenkins workspace and writing it via SSM
                    String serverJsContent = readFile('backend/server.js').replace('"', '\\"').replace('$', '\\$')
                    sh """
                    aws ssm send-command \
                        --instance-ids "${BACKEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=["echo \\"${serverJsContent}\\" > /home/ubuntu/backend/server.js"]'
                    """

                    // Building and running the backend Docker container
                    sh """
                    aws ssm send-command \
                        --instance-ids "${BACKEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "cd /home/ubuntu/backend",
                            "docker build -t employee-backend .",
                            "docker stop backend-app || true",
                            "docker rm backend-app || true",
                            "docker run -d --name backend-app -p 5000:5000 employee-backend"
                        ]'
                    """
                }
            }
        }

        stage('Deploy Frontend') {
            steps {
                script {
                    echo "Deploying Frontend Container..."
                    sh """
                    aws ssm send-command \
                        --instance-ids "${FRONTEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=["mkdir -p /home/ubuntu/frontend"]'
                    """

                    // Reading frontend files and writing them to the target server via SSM
                    String indexHtml = readFile('frontend/index.html').replace('"', '\\"').replace('$', '\\$')
                    String frontendJs = readFile('frontend/frontend.js').replace('"', '\\"').replace('$', '\\$')
                    String nginxConf = readFile('frontend/nginx.conf').replace('"', '\\"').replace('$', '\\$')
                    
                    sh """
                    aws ssm send-command --instance-ids "${FRONTEND_INSTANCE_ID}" --document-name "AWS-RunShellScript" --parameters 'commands=["echo \\"${indexHtml}\\" > /home/ubuntu/frontend/index.html"]'
                    aws ssm send-command --instance-ids "${FRONTEND_INSTANCE_ID}" --document-name "AWS-RunShellScript" --parameters 'commands=["echo \\"${frontendJs}\\" > /home/ubuntu/frontend/frontend.js"]'
                    aws ssm send-command --instance-ids "${FRONTEND_INSTANCE_ID}" --document-name "AWS-RunShellScript" --parameters 'commands=["echo \\"${nginxConf}\\" > /home/ubuntu/frontend/nginx.conf"]'
                    """

                    // Building and running the frontend Nginx container
                    sh """
                    aws ssm send-command \
                        --instance-ids "${FRONTEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "echo \"FROM nginx:alpine\nCOPY index.html /usr/share/nginx/html/\nCOPY frontend.js /usr/share/nginx/html/\nCOPY nginx.conf /etc/nginx/conf.d/default.conf\nEXPOSE 80\nCMD [\\\"nginx\\\", \\\"-g\\\", \\\"daemon off;\\\"]\" > /home/ubuntu/frontend/Dockerfile",
                            "cd /home/ubuntu/frontend",
                            "docker build -t employee-frontend .",
                            "docker stop frontend-app || true",
                            "docker rm frontend-app || true",
                            "docker run -d --name frontend-app -p 80:80 employee-frontend"
                        ]'
                    """
                }
            }
        }
    }
}
