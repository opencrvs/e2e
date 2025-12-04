#!/bin/bash

# Reading Names parameters
for i in "$@"; do
    case $i in
    --ssh_host=*)
        SSH_HOST="${i#*=}"
        shift
        ;;
    --ssh_user=*)
        SSH_USER="${i#*=}"
        shift
        ;;
    --ssh_port=*)
        SSH_PORT="${i#*=}"
        shift
        
        ;;
    --stack=*)
        export STACK="${i#*=}"
        shift
        ;;
    esac
done


print_usage_and_exit () {
  echo "Usage: $0 --ssh_host --ssh_port --ssh_user --stack"
  exit 1
}

validate_options() {
  if [ -z "$STACK" ] ; then
    echo 'Error: Argument --stack is required.'
    print_usage_and_exit
  fi

  if [ -z "$SSH_HOST" ] ; then
    echo 'Error: Argument --ssh_host is required.'
    print_usage_and_exit
  fi

  if [ -z "$SSH_PORT" ] ; then
    echo 'Error: Argument --ssh_port is required.'
    print_usage_and_exit
  fi

  if [ -z "$SSH_USER" ] ; then
    echo 'Error: Argument --ssh_user is required.'
    print_usage_and_exit
  fi

}

configured_ssh() {
  # TODO: Remove ~/.ssh/vmudryi-opencrvs
  ssh $SSH_USER@$SSH_HOST -p $SSH_PORT $SSH_ARGS "$@"
}

docker_stack_cleanup() {
  echo "Cleanup docker swarm stack $STACK"

  EXISTING_STACKS=$(configured_ssh 'sudo docker stack ls --format "{{ .Name }}" | grep -v "dependencies" | paste -sd "," -')
  echo "Existing stacks: $EXISTING_STACKS"
  if echo $EXISTING_STACKS | grep -w $STACK > /dev/null; then
    echo "Stack $STACK exists"
    EXISTING_IMAGES=`mktemp`
    EXISTING_IMAGES=$(configured_ssh "sudo docker stack services --format '{{.Image}}' '$STACK'" | grep -E '(ghcr.io/opencrvs|opencrvs/ocrvs-farajaland)' | sort)
    
    echo "⬤⬤⬤⬤⬤ Deleting stack $STACK ⬤⬤⬤⬤⬤"
    configured_ssh "sudo docker stack rm $STACK"

    echo "⬤⬤⬤⬤⬤ Deleting images ⬤⬤⬤⬤⬤:"
    for image in $EXISTING_IMAGES
    do
      configured_ssh "sudo docker rmi --force $image && echo ' - [✅ Deleted] $image' || echo ' - [❌ Failed] $image'"
    done
  else
    echo "Stack $STACK doesn't exist. Exiting"
  fi

  

}

SSH_ARGS=${SSH_ARGS:-}

validate_options
docker_stack_cleanup