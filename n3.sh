#!/bin/bash    
  
# Nama gambar Docker yang akan digunakan    
DOCKER_IMAGE="ubuntu:latest"    
  
# Jumlah kontainer yang akan dibuat    
NUM_CONTAINERS=10    
  
# Port awal    
START_PORT=8080    
  
# Fungsi untuk mengecek apakah port sudah digunakan    
is_port_in_use() {    
    local port=$1    
    netstat -tuln | grep ":$port " > /dev/null 2>&1    
    return $?    
}    
  
# Fungsi untuk mengecek apakah Docker berjalan    
is_docker_running() {    
    sudo systemctl is-active --quiet docker    
    return $?    
}    
  
# Periksa apakah Docker berjalan    
if ! is_docker_running; then    
    echo "Docker tidak berjalan. Memulai Docker..."    
    sudo systemctl start docker    
    if ! is_docker_running; then    
        echo "Gagal memulai Docker. Mohon periksa instalasi Docker."    
        exit 1    
    fi    
fi    
  
# Periksa apakah Docker Image tersedia lokal, jika tidak, tarik dari Docker Hub    
if ! sudo docker image inspect $DOCKER_IMAGE > /dev/null 2>&1; then    
    echo "Mengunduh gambar Docker $DOCKER_IMAGE..."    
    sudo docker pull $DOCKER_IMAGE    
    if [ $? -ne 0 ]; then    
        echo "Gagal mengunduh gambar Docker $DOCKER_IMAGE. Mohon periksa koneksi internet Anda."    
        exit 1    
    fi    
fi    
  
# Loop untuk membuat kontainer    
for ((i=0; i<NUM_CONTAINERS; i++)); do    
    PORT=$((START_PORT + i))    
        
    # Periksa apakah port sudah digunakan    
    if is_port_in_use $PORT; then    
        echo "Port $PORT sudah digunakan. Mengganti ke port berikutnya..."    
        continue    
    fi    
        
    # Buat nama kontainer unik    
    CONTAINER_NAME="network3_container_$PORT"    
        
    # Jalankan kontainer    
    echo "Membuat kontainer $CONTAINER_NAME dengan port $PORT..."    
    sudo docker run -d -p $PORT:80 --name $CONTAINER_NAME $DOCKER_IMAGE    
        
    if [ $? -ne 0 ]; then    
        echo "Gagal membuat kontainer $CONTAINER_NAME dengan port $PORT."    
        continue    
    fi    
        
    # Jalankan perintah instalasi di dalam kontainer    
    echo "Menjalankan instalasi di kontainer $CONTAINER_NAME..."    
    sudo docker exec -i $CONTAINER_NAME bash <<EOF    
apt update && apt upgrade -y && apt install -y wget net-tools iproute2 iptables && wget https://network3.io/ubuntu-node-v2.1.0.tar && tar -xvf ubuntu-node-v2.1.0.tar && cd ubuntu-node    
EOF    
        
    if [ $? -eq 0 ]; then    
        echo "Instalasi di kontainer $CONTAINER_NAME berhasil."    
    else    
        echo "Gagal menjalankan instalasi di kontainer $CONTAINER_NAME."    
    fi    
done    
  
echo "Proses pembuatan kontainer selesai."    
