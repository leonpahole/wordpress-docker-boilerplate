source build.env

BUMP_LEVEL=$1 # minor or major, default: none

# attempt to get previous tag from git
PREVIOUS_TAG=$(git describe --tags --abbrev=0)
PREVIOUS_TAG_COMMAND_SUCCESS=$?

NEXT_TAG="-1"

if [[ $PREVIOUS_TAG_COMMAND_SUCCESS -ne 0 ]]; then
    # first version
    PREVIOUS_TAG="None"
    NEXT_TAG=0.1
else
    # bump previous version
    if [[ $BUMP_LEVEL == "minor" ]]; then
        NEXT_TAG=$(echo $PREVIOUS_TAG | awk '{split($0,a,"."); print a[1]"."a[2]+1}')
    elif [[ $BUMP_LEVEL == "major" ]]; then
        NEXT_TAG=$(echo $PREVIOUS_TAG | awk '{split($0,a,"."); print a[1]+1"."a[2]}')
    fi
fi

if [ $NEXT_TAG != "-1" ]; then
    echo $PREVIOUS_TAG " -> " $NEXT_TAG
    git tag $NEXT_TAG
    git push --tags
fi

CURRENT_VERSION=$(git describe --tags --abbrev=0)

docker build -t $IMAGE_NAME:latest -t $IMAGE_NAME:$CURRENT_VERSION .

docker login --username $DOCKER_USERNAME

docker push $IMAGE_NAME:latest
docker push $IMAGE_NAME:$CURRENT_VERSION