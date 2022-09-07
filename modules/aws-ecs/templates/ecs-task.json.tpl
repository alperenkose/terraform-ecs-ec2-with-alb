[
  {
    "name": "${container_name}",
    "image": "${container_image}",
    "cpu": ${container_cpu},
    "memoryReservation": ${container_mem},
    "portMappings": [
      {
        "containerPort": ${container_port},
        "protocol": "tcp"
      }
    ],
    "essential": true
  }
]
