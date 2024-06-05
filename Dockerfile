# Utiliza la imagen de Jenkins con la versión 2.452.1 y JDK 17
FROM jenkins/jenkins:2.452.1-jdk17

# Cambia al usuario root para tener permisos de administrador
USER root

# Actualiza los paquetes existentes e instala lsb-release
RUN apt-get update && apt-get install -y lsb-release

# Descarga la clave GPG de Docker para verificar las descargas posteriores
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg

# Agrega el repositorio de Docker a la lista de fuentes de APT
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Actualiza los paquetes nuevamente e instala el cliente de Docker
RUN apt-get update && apt-get install -y docker-ce-cli

# Cambia de nuevo al usuario Jenkins
USER jenkins

# Instala los plugins de Jenkins "blueocean" y "docker-workflow"
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"