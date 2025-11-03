pipeline {
  agent any

  environment {
    APP_NAME = 'static-site'
    HOST_PORT = '8081'
    // IMAGE_TAG and DOCKER_IMAGE are computed in the Init stage to avoid cross-ref issues in env{}
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Init') {
      steps {
        script {
          env.IMAGE_TAG     = "${env.BUILD_NUMBER}"
          env.CONTAINER_NAME = env.APP_NAME
          env.DOCKER_IMAGE   = "local/${env.APP_NAME}:${env.IMAGE_TAG}"
          echo "Image: ${env.DOCKER_IMAGE}  Container: ${env.CONTAINER_NAME}  Port: ${env.HOST_PORT}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        powershell 'docker build -t $env:DOCKER_IMAGE .'
      }
    }

    stage('Stop & Remove Old Container (if exists)') {
      steps {
        powershell '''
          $id = docker ps -aq -f "name=^$env:CONTAINER_NAME$"
          if ($id) { docker rm -f $env:CONTAINER_NAME | Out-Null }
          exit 0
        '''
      }
    }

    stage('Run New Container') {
      steps {
        powershell 'docker run -d --name $env:CONTAINER_NAME -p $env:HOST_PORT:80 $env:DOCKER_IMAGE'
      }
    }

    stage('Health Check') {
      steps {
        powershell '''
          $tries = 10
          for ($i=0; $i -lt $tries; $i++) {
            try {
              $r = Invoke-WebRequest -UseBasicParsing -Uri ("http://localhost:" + $env:HOST_PORT) -TimeoutSec 5
              if ($r.StatusCode -eq 200) { exit 0 }
            } catch { Start-Sleep -Seconds 2 }
          }
          docker logs $env:CONTAINER_NAME
          Write-Error "Health check failed: site not responding on http://localhost:$($env:HOST_PORT)"
        '''
      }
    }
  }

  post {
    success {
      echo "Deployed: http://localhost:${env.HOST_PORT}"
    }
    always {
      powershell 'docker images | Select-Object -First 15'
      powershell 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"'
      // Never fail the build because of post steps:
      powershell 'exit 0'
    }
  }
}
