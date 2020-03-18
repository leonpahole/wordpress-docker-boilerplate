source build.env

docker build -t $IMAGE_NAME:latest -t $IMAGE_NAME:0.1 .

docker login --username $DOCKER_USERNAME

docker push $IMAGE_NAME:latest
docker push $IMAGE_NAME:0.1