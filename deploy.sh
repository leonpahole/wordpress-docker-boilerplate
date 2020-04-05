set -u

CONFIG_FILE=deploy.env

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE does not exist. Please create it."
    exit 1
fi

# read configuration from configuration file
source $CONFIG_FILE

echo 
echo "### CREATING DIRECTORY ####"


ssh $SERVER_USERNAME@$SERVER_IP "mkdir -p $PROJECT_DIRECTORY"


echo 
echo "### COPY COMPOSE FILE ####"

read -p 'Copy docker-compose.prod.yml? (y/n) [n]:' COPY_COMPOSE

if [[ $COPY_COMPOSE == "y" || $COPY_COMPOSE == "Y" ]]; then
    scp docker-compose.prod.yml $SERVER_USERNAME@$SERVER_IP:$PROJECT_DIRECTORY
fi

echo 
echo "### COPY ENV FILE ####"

read -p 'Copy docker .env? (y/n) [n]:' COPY_ENV

if [[ $COPY_ENV == "y" || $COPY_ENV == "Y" ]]; then
    scp .env $SERVER_USERNAME@$SERVER_IP:$PROJECT_DIRECTORY
fi

echo 
echo "### COPY PERMISSION SCRIPT ####"

scp fix_permissions_for_production.sh $SERVER_USERNAME@$SERVER_IP:$PROJECT_DIRECTORY

echo
echo "### RUNNING DEPLOYMENT ###"

ssh $SERVER_USERNAME@$SERVER_IP << EOF
    cd ${PROJECT_DIRECTORY}
    docker-compose -f docker-compose.prod.yml pull
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml up -d
    bash fix_permissions_for_production.sh
EOF

echo "### DONE ###"