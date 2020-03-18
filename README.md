## Dockerized wordpress

This is a template that I use to create a dockerized wordpress website. The setup is not perfect, but it is great for local development and production deployments.

## Adjusting for concrete site

Some strings in this project are titled "boilerplate" or "mysite" for demonstration, namely in docker-compose files. You should change these names accordingly to your website actual name.

## Setting up local deployment

Run `docker-compose build`. Then run `docker-compose up -d`. Directory wp-content is mounted into the directory, so the site refreshes without rebuild and rerun of containers. Therefore, you don't have to call build again.

## Permission issues

The first problem with dockerized wordpress is that permissions of bind mounted directories are incorrect. This will cause wordpress to throw errors when writing to wp-content directory.

In order to solve this, we need to change owner of files on our machine to be the user id (UID) of user www-data in the container. We can get this user id by calling docker container. However, running this for the first time, docker container will not be running yet. Therefore, there are two options:

- guess that the user id is 33 (which it appears to be always) and change permissions
- if above point doesn't work, comment the line in docker-compose.yml to unbind the wp-content directory and then run the container, get the user id and change permissions

Script `fix_permissions_for_local_development.sh` will attempt to change permissions. If container isn't running, it will try to set owner to user 33. If this doesn't work (you still get permission denied errors in logs), then follow second point (comment bind mount), run the container and then call the script.

Once your permissions are set up, you are good to go and you can develop locally without restarting containers. Keep in mind that you have to rerun
`fix_permissions_for_local_development.sh` if you add a file that wordpress writes to.

## Building and publishing the image

Copy `build.example.env` to `build.env`. Fill out your docker hub image name and username. Then you can run `build.env` to build the image.

TODO: versioning - currently version 0.1 is hardcoded.

## Deploying the image

I made a sample script that deploys the image using ssh. You need to copy `deploy.example.env` to `deploy.env` and fill out your server credentials and directory, in which you want the data to reside. You also have to copy `.env.example` to `.env` and fill out database information. The script can then copy environments and production compose file, pull your image from registry and run it.

The script will also call `fix_permissions_for_production.sh`, which is neccessary to change permissions of wp-content directory in docker container.

Keep in mind that this deployment is not a completely safe approach as `.env` file will be exposed. In the future, I will try to integrate docker secrets instead.

TODO: docker secrets
