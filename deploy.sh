source deploy.env

ssh $SERVER_USERNAME@$SERVER_IP "mkdir -p $PROJECT_DIRECTORY"

read -p 'Copy docker-compose.prod.yml?: ' copyDockerCompose

if [[ $copyDockerCompose == "y" || $copyDockerCompose == "Y" ]]; then
    scp docker-compose.prod.yml $SERVER_USERNAME@$SERVER_IP:$PROJECT_DIRECTORY
fi

read -p 'Copy docker .env?: ' copyDockerEnv

if [[ $copyDockerEnv == "y" || $copyDockerEnv == "Y" ]]; then
    scp .env $SERVER_USERNAME@$SERVER_IP:$PROJECT_DIRECTORY
fi

ssh $SERVER_USERNAME@$SERVER_IP << EOF
    cd ${PROJECT_DIRECTORY}
    docker-compose -f docker-compose.prod.yml pull
    docker-compose -f docker-compose.prod.yml up -d
EOF