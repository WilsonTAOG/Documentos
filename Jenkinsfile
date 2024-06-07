pipeline {
    agent any // Selecciona cualquier agente disponible para ejecutar el pipeline
    parameters { // Define los parámetros que se pueden pasar al pipeline
        choice choices: ['Baseline', 'APIS', 'Full'], // Permite seleccionar el tipo de escaneo
                description: 'Type of scan that is going to perform inside the container',
                name: 'SCAN_TYPE'

        string defaultValue: 'http://localhost:3000', // Define la URL objetivo por defecto para el escaneo
                description: 'Target URL to scan',
                name: 'TARGET'

        booleanParam defaultValue: true, // Define si se generará un informe o no
                description: 'Parameter to know if wanna generate report.',
                name: 'GENERATE_REPORT'
    }
    environment {
        HOME = '.' // Define la variable de entorno HOME
    }
    stages { // Define las etapas del pipeline
        stage('Pipeline Info') { // Etapa para imprimir la información del pipeline
            steps {
                script {
                    echo '<--Parameter Initialization-->'
                    echo """
                         The current parameters are:
                             Scan Type: ${params.SCAN_TYPE}
                             Target: ${params.TARGET}
                             Generate report: ${params.GENERATE_REPORT}
                         """
                }
            }
        }

        stage('Cleanup Workspace') { // Etapa para limpiar el espacio de trabajo
            steps {
                echo 'Cleaning up workspace...'
                cleanWs() // Limpia el espacio de trabajo
            }
        }

        stage('Clone Repository') { // Etapa para clonar el repositorio
            steps {
                echo 'Cloning repository..... Hasta aqui'
                git branch: 'main', url: 'https://github.com/WilsonTAOG/FastyCars.git' // Clona el repositorio de GitHub
            }
        }

        stage('List Directory Contents') { // Etapa para listar el contenido del directorio
            steps {
                script {
                    sh 'ls -l /var/jenkins_home/workspace/prueba' // Lista el contenido del directorio
                }
            }
        }

        stage('Install Dependencies') { // Etapa para instalar las dependencias
            steps {
                script {
                    sh 'docker run --rm -v /var/jenkins_home/workspace/prueba:/app -w /app node:16-buster npm install' // Instala las dependencias usando Docker
                }
            }
        }

        stage('Start Server') { // Etapa para iniciar el servidor
            steps {
                script {
                    sh 'docker rm -f fastycars_backend || true' // Elimina el contenedor si existe
                    sh 'docker run -d --name fastycars_backend -v /var/jenkins_home/workspace/prueba:/app -w /app -p 3000:3000 node:16-buster npm run dev' // Inicia el servidor usando Docker
                }
            }
        }


        stage('Setting up OWASP ZAP docker container') { // Etapa para configurar el contenedor de Docker de OWASP ZAP
            steps {
                echo 'Pulling up last OWASP ZAP container --> Start'
                sh 'docker pull ghcr.io/zaproxy/zaproxy:stable' // Descarga la última imagen de OWASP ZAP
                echo 'Pulling up last VMS container --> End'
                echo 'Starting container --> Start'
                sh 'docker run -dt --network="host" --name owasp ghcr.io/zaproxy/zaproxy:stable /bin/bash' // Inicia el contenedor de OWASP ZAP
            }
        }



        stage('Prepare wrk directory') { // Etapa para preparar el directorio de trabajo
            when {
                expression { params.GENERATE_REPORT } // Solo se ejecuta si se ha solicitado generar un informe
            }
            steps {
                script {
                    sh 'docker exec owasp mkdir /zap/wrk' // Crea el directorio de trabajo en el contenedor de OWASP ZAP
                }
            }
        }

        stage('Scanning target on owasp container') { // Etapa para escanear el objetivo en el contenedor de OWASP ZAP
            steps {
                script {
                    def scan_type = "${params.SCAN_TYPE}" // Obtiene el tipo de escaneo
                    def target = "${params.TARGET}" // Obtiene el objetivo del escaneo
                    echo "----> scan_type: $scan_type"
                    if (scan_type == 'Baseline') { // Si el tipo de escaneo es 'Baseline'
                        sh """
                             docker exec owasp \
                             zap-baseline.py \
                             -t $target \
                             -r report.html \
                             -I
                         """
                    } else if (scan_type == 'APIS') { // Si el tipo de escaneo es 'APIS'
                        sh """
                             docker exec owasp \
                             zap-api-scan.py \
                             -t $target \
                             -f openapi \
                             -r report.html \
                             -I
                         """
                    } else if (scan_type == 'Full') { // Si el tipo de escaneo es 'Full'
                        sh """
                             docker exec owasp \
                             zap-full-scan.py \
                             -t $target \
                             -r report.html \
                             -I
                         """
                    } else {
                        echo 'Something went wrong...' // Si algo salió mal
                    }
                }
            }
        }

        stage('Copy Report to Workspace') { // Etapa para copiar el informe al espacio de trabajo
            steps {
                script {
                    sh 'docker cp owasp:/zap/wrk/report.html ${WORKSPACE}/report.html' // Copia el informe al espacio de trabajo
                }
            }
        }

        stage('Email Report') { // Etapa para enviar el informe por correo electrónico
            steps {
                emailext (
                    attachLog: true,
                    attachmentsPattern: 'report.html',
                    body: "Please find the attached report for the latest OWASP ZAP Scan.",
                    recipientProviders: [buildUser()],
                    subject: "OWASP ZAP Report",
                    to: 'alexis.villavicencio@taotechideas.com' // Envia el informe al correo electrónico especificado
                )
            }
        }
    }
    post {
        always {
            echo 'Removing container'
            sh 'docker stop owasp' // Detiene el contenedor de OWASP ZAP
            sh 'docker rm owasp' // Elimina el contenedor de OWASP ZAP
            sh 'docker stop fastycars_backend' // Detiene el servidor
            sh 'docker rm fastycars_backend' // Elimina el servidor
        }
    }
}
