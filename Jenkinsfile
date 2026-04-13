pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME  = "vaibhav7616/odoo"
        APP_VERSION        = "v${BUILD_NUMBER}"
        IMAGE_TAG          = "vaibhav7616/odoo:v${BUILD_NUMBER}"
        IMAGE_TAG_LATEST   = "vaibhav7616/odoo:latest"
        K8S_NAMESPACE      = "odoo"
        K8S_DEPLOYMENT     = "odoo-deployment"
        GIT_REPO           = "https://github.com/vaibhav7616/demoo.git"
        GIT_BRANCH         = "main"
        GIT_CREDENTIALS    = "git-credentials"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 45, unit: 'MINUTES')
    }

    stages {

        stage('Pull Code') {
            steps {
                echo "==> Pulling code for build ${env.APP_VERSION}"
                git branch: "${env.GIT_BRANCH}",
                    credentialsId: "${env.GIT_CREDENTIALS}",
                    url: "${env.GIT_REPO}"
                sh '''
                    echo "Commit: $(git log -1 --oneline)"
                    ls -la
                '''
            }
        }

        stage('Validate Files') {
            steps {
                sh '''
                    [ ! -f docker/Dockerfile ] && echo "ERROR: Dockerfile missing" && exit 1
                    echo "✅ Dockerfile exists"
                    [ ! -f k8s/deployment.yaml ] && echo "ERROR: deployment.yaml missing" && exit 1
                    echo "✅ deployment.yaml exists"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                echo "==> Building ${env.IMAGE_TAG}"
                sh """
                    export PATH=\$PATH:/usr/bin:/usr/local/bin
                    GIT_SHORT=\$(git rev-parse --short HEAD)
                    docker build \\
                        --build-arg APP_VERSION=${env.APP_VERSION} \\
                        --build-arg BUILD_NUMBER=${BUILD_NUMBER} \\
                        --build-arg GIT_COMMIT=\${GIT_SHORT} \\
                        --label app.version=${env.APP_VERSION} \\
                        -t ${env.IMAGE_TAG} \\
                        -t ${env.IMAGE_TAG_LATEST} \\
                        -f docker/Dockerfile .
                """
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        export PATH=\$PATH:/usr/bin:/usr/local/bin
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                        docker push ${env.IMAGE_TAG}
                        docker push ${env.IMAGE_TAG_LATEST}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                        export PATH=\$PATH:/usr/bin:/usr/local/bin
                        export KUBECONFIG=\$KUBECONFIG

                        echo "==> Checking cluster access"
                        kubectl get nodes --insecure-skip-tls-verify

                        echo "==> Creating namespace if not exists"
                        kubectl get ns ${env.K8S_NAMESPACE} --insecure-skip-tls-verify 2>/dev/null || kubectl create ns ${env.K8S_NAMESPACE} --insecure-skip-tls-verify

                        echo "==> Applying K8s manifests with version injection"
                        # We use sed to replace placeholders in deployment.yaml
                        sed -e "s|PLACEHOLDER_IMAGE|${env.IMAGE_TAG}|g" \
                            -e "s|PLACEHOLDER_VERSION|${env.APP_VERSION}|g" \
                            -e "s|PLACEHOLDER_BUILD|${BUILD_NUMBER}|g" \
                            k8s/deployment.yaml | kubectl apply -f - -n ${env.K8S_NAMESPACE} --insecure-skip-tls-verify

                        kubectl apply -f k8s/service.yaml -n ${env.K8S_NAMESPACE} --insecure-skip-tls-verify

                        # Force rollout to ensure the new image is pulled even if the tag is 'latest'
                        kubectl rollout restart deployment/${env.K8S_DEPLOYMENT} -n ${env.K8S_NAMESPACE} --insecure-skip-tls-verify
                    """
                }
            }
        }

        stage('Rollout Status') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                        export PATH=\$PATH:/usr/bin:/usr/local/bin
                        export KUBECONFIG=\$KUBECONFIG

                        echo "==> Waiting for rollout to complete..."
                        kubectl rollout status deployment/${env.K8S_DEPLOYMENT} -n ${env.K8S_NAMESPACE} --timeout=300s --insecure-skip-tls-verify

                        echo "────────────────────────────────────────────"
                        echo "  Version  : ${env.APP_VERSION}"
                        echo "  Image    : ${env.IMAGE_TAG}"
                        echo "────────────────────────────────────────────"

                        kubectl get pods -n ${env.K8S_NAMESPACE} -l app=odoo -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready' --insecure-skip-tls-verify
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS — ${env.APP_VERSION ?: 'unknown'} deployed | Image: ${env.IMAGE_TAG ?: 'unknown'}"
        }
        failure {
            echo "❌ FAILED — ${env.APP_VERSION ?: 'unknown'}"
            withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                sh """
                    export PATH=\$PATH:/usr/bin:/usr/local/bin
                    export KUBECONFIG=\$KUBECONFIG
                    kubectl rollout undo deployment/${env.K8S_DEPLOYMENT} -n ${env.K8S_NAMESPACE} --insecure-skip-tls-verify || true
                """
            }
        }
        always {
            sh "docker rmi ${env.IMAGE_TAG ?: ''} ${env.IMAGE_TAG_LATEST ?: ''} 2>/dev/null || true"
            // deleteDir() // Optional: keep for debugging if needed, but usually good to delete
        }
    }
}
