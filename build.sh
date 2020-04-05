set -u

CONFIG_FILE=build.env

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE does not exist. Please create it."
    exit 1
fi

# read configuration from configuration file
source $CONFIG_FILE

if [ $DRY_RUN -ne 0 ]; then
    echo "DRY RUN ACTIVE: This run will not tag the image or push to registry"
fi

echo 
echo "### BUILD ####"

# try to build image first to detect any early errors
docker build -t $IMAGE_NAME:latest .

# ask about docker deployment, if user says yes, login to docker
read -p "Push image to registry $REGISTRY_URL (y/n)? [n] " PUSH_TO_DOCKER_REGISTRY_RESPONSE

if [[ $PUSH_TO_DOCKER_REGISTRY_RESPONSE == "y" || $PUSH_TO_DOCKER_REGISTRY_RESPONSE == "Y" ]]; then

    echo 
    echo "### LOGIN ####"

    # keep repeating loop until login is successful
    while :
    do
        echo "Logging in to $REGISTRY_URL as $DOCKER_USERNAME"
        docker login --username $DOCKER_USERNAME $REGISTRY_URL
        LOGIN_SUCCESS=$?

        if [ $LOGIN_SUCCESS -ne 0 ]; then
            echo "Login failed. Try again. (hold ctrl+c for exit)"
        else
            break
        fi
    done

    echo 
    echo "### VERSION ####"

    # attempt to get previous tag from git
    PREVIOUS_VERSION=$(git describe --tags --abbrev=0 2>/dev/null)
    PREVIOUS_VERSION_COMMAND_SUCCESS=$?

    # no version yet
    if [[ $PREVIOUS_VERSION_COMMAND_SUCCESS -ne 0 ]]; then
        PREVIOUS_VERSION="None"
    fi

    echo "Previous version: ${PREVIOUS_VERSION}"
    read -p "Enter new version (leave blank for no version increment and no tag): " NEXT_VERSION
    
    # check if version was set and decide if we will tag the image or not
    TAG_IMAGE=0
    if [ ! -z $NEXT_VERSION ]; then
        TAG_IMAGE=1
        echo "Docker image will be tagged with ${IMAGE_NAME}:${NEXT_VERSION}."
    else
        NEXT_VERSION="None"
        echo "Docker image will not be tagged or pushed with any version."
    fi

    # ask user to confirm
    echo "Docker image will be tagged or pushed with ${IMAGE_NAME}:latest."
    read -p "Confirm update (y/n) [n]: " CONFIRM_UPDATE

    if [[ $CONFIRM_UPDATE != "y" && $CONFIRM_UPDATE != "Y" ]]; then
        echo "Update canceled."
        exit 2
    fi

    echo 
    echo "### PUSH TO REGISTRY ####"

    # push and tag if configured
    if [ $TAG_IMAGE -eq 1 ]; then

        # create git tag
        echo "Tagging git with ${NEXT_VERSION}"
        if [ $DRY_RUN -eq 0 ]; then
            git tag $NEXT_VERSION
            git push --tags
        fi

        # tag image
        echo "Tagging image with version ${NEXT_VERSION}."
        if [ $DRY_RUN -eq 0 ]; then
            docker tag $IMAGE_NAME:latest $IMAGE_NAME:$NEXT_VERSION
        fi
    fi

    echo "Pushing ${IMAGE_NAME}:latest to registry."

    if [ $DRY_RUN -eq 0 ]; then
        docker push $IMAGE_NAME:latest
    fi

    if [ $TAG_IMAGE -eq 1 ]; then
        echo "Pushing ${IMAGE_NAME}:${NEXT_VERSION} to registry."
        
        if [ $DRY_RUN -eq 0 ]; then
            docker push $IMAGE_NAME:$NEXT_VERSION
        fi
    fi

    echo 
    echo "### SUMMARY ####"

    echo "Image ${IMAGE_NAME}:latest was pushed to registry."

    if [ $TAG_IMAGE -eq 1 ]; then
        echo "Git tag ${NEXT_VERSION} was created and pushed."
        echo "Image was tagged with ${IMAGE_NAME}:${NEXT_VERSION} and pushed to the registry."
    else
        echo "No version was tagged or pushed."
    fi
else
    echo 
    echo "### SUMMARY ####"
    echo "Built image was tagged ${IMAGE_NAME}:latest, no pushes or version changes were made."
fi