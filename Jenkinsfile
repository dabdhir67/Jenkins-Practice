pipeline {
  agent any

  options { timestamps() }

  environment {
    APP_NAME = 'static-site'
    HOST_PORT = '8081'
    // IMAGE_TAG, DOCKER_IMAGE, CONTAINER_NAME are set in Init to avoid cross-ref issues
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Init') {
      steps {
        script {
          env.IMAGE_TAG       = "${env.BUILD_NUMBER}"
          env.CONTAINER_NAME  = env.APP_NAME
          env.DOCKER_IMAGE    = "local/${env.APP_NAME}:${env.IMAGE_TAG}"
        }
        powershell '''
          Write-Host "Image: $($env:DOCKER_IMAGE)"
          Write-Host "Container: $($env:CONTAINER_NAME)"
          Write-Host "Port: $($env:HOST_PORT)"
        '''
      }
    }

    stage('Verify Docker & Vars') {
      steps {
        powershell '''
          docker version
          docker info | Out-Null
          if (-not $env:DOCKER_IMAGE)   { throw "DOCKER_IMAGE not set" }
          if (-not $env:CONTAINER_NAME) { throw "CONTAINER_NAME not set" }
          if (-not $env:HOST_PORT)      { throw "HOST_PORT not set" }
        '''
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
          $name = $env:CONTAINER_NAME
          $cid = docker ps -aq -f "name=^$name$"
          if ($cid) {
            Write-Host "Removing old container $name ($cid)"
            docker rm -f $name | Out-Null
          } else {
            Write-Host "No existing container named $name"
          }
          exit 0
        '''
      }
    }

    stage('Run New Container') {
      steps {
        powershell '''
          $img  = $env:DOCKER_IMAGE
          $name = $env:CONTAINER_NAME
          $port = $env:HOST_PORT

          Write-Host "Will run: name=$name image=$img port=$port"
          if (-not $img) { Write-Error "DOCKER_IMAGE is empty"; exit 1 }

          docker run -d --name $name -p "$port:80" $img
        '''
      }
    }

    stage('Health Check') {
      steps {
        powershell '''
          $tries = 10
          for ($i=0; $i -lt $tries; $i++) {
            try {
              $r = Invoke-WebRequest -UseBasicParsing -Uri ("http://localhost:" + $env:HOST_PORT) -TimeoutSec 5
              if ($r.StatusCode -eq 200) {
                Write-Host "Health check OK"
                exit 0
              }
            } catch {
              Start-Sleep -Seconds 2
            }
          }
          Write-Host "----- Container logs -----"
          docker logs $env:CONTAINER_NAME | Out-Host
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
      // Don’t let post fail the build
      powershell '''
        Write-Host "---- docker images (top 15) ----"
        docker images | Select-Object -First 15 | Format-Table | Out-String | Write-Host
        Write-Host "---- docker ps ----"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | Write-Host
        exit 0
      '''
    }
  }
}
