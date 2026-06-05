#!/bin/bash

apt update -y

apt install -y docker.io curl

systemctl start docker
systemctl enable docker

curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"

install minikube-linux-amd64 /usr/local/bin/minikube

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl