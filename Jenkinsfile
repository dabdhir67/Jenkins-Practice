pipeline {
  agent any

  environment {
    APP_NAME = "static-site"
    IMAGE_TAG = "${env.BUILD_NUMBER}"          // e.g., 15
    DOCKER_IMAGE = "local/${env.APP_NAME}:${env.IMAGE_TAG}"
    HOST_PORT = "8081"                          // change if you want a different port
    CONTAINER_NAME = "${env.APP_NAME}"
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${DOCKER_IMAGE} .
        '''
      }
    }

    stage('Stop & Remove Old Container (if exists)') {
      steps {
        sh '''
          if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
            docker rm -f ${CONTAINER_NAME} || true
          fi
        '''
      }
    }

    stage('Run New Container') {
      steps {
        sh '''
          docker run -d --name ${CONTAINER_NAME} \
            -p ${HOST_PORT}:80 \
            ${DOCKER_IMAGE}
        '''
      }
    }

    stage('Health Check') {
      steps {
        script {
          // Try curl a few times to allow container to start
          def tries = 10
          def ok = false
          for (int i = 0; i < tries; i++) {
            def code = sh(returnStatus: true, script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${HOST_PORT}")
            if (code == 200) { ok = true; break }
            sleep 2
          }
          if (!ok) {
            error "Health check failed: site not responding on http://localhost:${HOST_PORT}"
          }
        }
      }
    }
  }

  post {
    success {
      echo "Deployed: http://localhost:${HOST_PORT}"
    }
    always {
      sh 'docker images | head -n 15 || true'
      sh 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"'
    }
  }
}