pipeline {
    agent any

    environment {
        // 1.  AWS Instance IDs
        DB_INSTANCE_ID       = 'i-05c0050be3334e158'
        BACKEND_INSTANCE_ID  = 'i-07768fb71153b6365'
        FRONTEND_INSTANCE_ID = 'i-0c5e9f6b1a4517f61'
        
        // 2. AWS Region
        AWS_DEFAULT_REGION   = 'ap-south-1'
        
        // 3.  GitHu URL
        GITHUB_REPO_URL      = 'https://github.com/dattaprasads-24/employee_management_portal.git'
    }

    stages {
        stage('Checkout Code') {
            steps {
                // pull latest code from github
                git branch: 'main', url: "${env.GITHUB_REPO_URL}"
            }
        }

        stage('Deploy Database') {
            steps {
                script {
                    echo "SSM Database Server MySQL"
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

        stage('Deploy Backend') {
            steps {
                script {
                    echo "SSM  Backend Serve  Node.js"
                    sh """
                    aws ssm send-command \
                        --instance-ids "${BACKEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "cd /home/ubuntu && rm -rf Employee-Portal || true",
                            "git clone ${env.GITHUB_REPO_URL}",
                            "cd Employee-Portal/backend",
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
                    echo "SSM Frontend Server Nginx"
                    // Frontend Nginx
                    sh """
                    aws ssm send-command \
                        --instance-ids "${FRONTEND_INSTANCE_ID}" \
                        --document-name "AWS-RunShellScript" \
                        --parameters 'commands=[
                            "cd /home/ubuntu && rm -rf Employee-Portal || true",
                            "git clone ${env.GITHUB_REPO_URL}",
                            "cd Employee-Portal/frontend",
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
