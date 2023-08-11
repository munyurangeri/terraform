terraform {
  required_providers {
    # aws, ... 
  }
}

# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

# Pulls the image
resource "docker_image" "traefik" {
  name = "traefik:v2.10"
}

resource "docker_image" "whoami" {
  name = "traefik/whoami"
}

resource "docker_image" "mss-server" {
  name = "mcr.microsoft.com/mssql/server"
}

# Create a container
resource "docker_container" "traefik" {
  image = docker_image.traefik.image_id
  name  = "traefik"

  command = [
    "--api.insecure=true",
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--entrypoints.web.address=:80"
  ]

  ports {
    internal = 80
    external = 80
    ip       = "0.0.0.0"
  }

  ports {
    internal = 8080
    external = 8080
    ip       = "0.0.0.0"
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
}

resource "docker_container" "whoami" {
  image = docker_image.whoami.name
  name  = "whoami"

  labels {
    label = "traefik.enable"
    value = true
  }

  labels {
    label = "traefik.http.routers.whoami.rule"
    value = "PathPrefix(`/whoami`)"
  }

  labels {
    label = "traefik.http.routers.whoami.entrypoints"
    value = "web"
  }

}

resource "docker_container" "mss-server" {
  image = docker_image.mss-server.name
  name  = "mss-server"
  env = [
    "SA_PASSWORD=change_this_password",
    "ACCEPT_EULA=Y"
  ]

  ports {
    internal = 1433
    external = 1433
    ip       = "127.0.0.1"
  }
}
