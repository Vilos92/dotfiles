#!/bin/sh

# Frontapp

export CANARY_USER='glinscheid'

# Directories.
export FRONTAPP_DIR=~/frontapp
export FRONTAPP_INFRA_DIR=${FRONTAPP_DIR}/front-infra
export FRONTAPP_FRONT_DIR=${FRONTAPP_DIR}/front
export FRONTAPP_CLIENT_DIR=${FRONTAPP_DIR}/front-client
export FRONTAPP_CHAT_DIR=${FRONTAPP_DIR}/front-chat
export FRONTAPP_CHAT_SDK_DIR=${FRONTAPP_DIR}/front-chat-sdk

# Change directory aliases.
alias cdf='cd ${FRONTAPP_DIR}'
alias cdfinfra='cd ${FRONTAPP_INFRA_DIR}'
alias cdffront='cd ${FRONTAPP_FRONT_DIR}'
alias cdfclient='cd ${FRONTAPP_CLIENT_DIR}'
alias cdfchat='cd ${FRONTAPP_CHAT_DIR}'
alias cdfchatsdk='cd ${FRONTAPP_CHAT_SDK_DIR}'

## tmux sessions
alias tmux-finfra='tmux-attach finfra $FRONTAPP_INFRA_DIR'
alias tmux-ffront='tmux-attach front ${FRONTAPP_FRONT_DIR}'
alias tmux-fclient='tmux-attach fclient $FRONTAPP_CLIENT_DIR'
alias tmux-fchat='tmux-attach fchat $FRONTAPP_CHAT_DIR'
alias tmux-fchatsdk='tmux-attach fchatsdk $FRONTAPP_CHAT_SDK_DIR'

alias front-sso='aws sso login'

alias ssh-front-us-preprod='ssh aws-us-api-preprod'

# Logs
alias staging-tail-exposed="stern -n glinscheid -l \"app.kubernetes.io/name=front-exposed-components\" --tail=0"
alias staging-tail-worker="stern -n glinscheid -l \"app.kubernetes.io/name=front-worker-components\" --tail=0"

# Kubernetes contexts.
alias kubectl-ctx='kubectl config use-context'

alias kctx-stg='kubectl-ctx usw2.staging'
alias kctx-us1='kubectl-ctx usw1.prod'
alias kctx-us2='kubectl-ctx usw2.prod'
alias kctx-eu='kubectl-ctx euw1.prod'

# Analytics clusters.
alias stg-kibana-docker='docker run -d -p 5601:5601  -e "ELASTICSEARCH_HOSTS=http://host.docker.internal:9200" docker.elastic.co/kibana/kibana:6.8.5'
alias stg-analytics-cluster='kubectl port-forward -n search statefulset/es-analytics-cluster 9200'
alias stg-search-full-cluster='kubectl-ctx usw2.staging && kubectl port-forward -n search sts/es-full-cluster 9200'

# Staging clusters.
alias glinscheid-exposed-tail='stern -n glinscheid -l "app.kubernetes.io/name=front-exposed-components" --tail=0'
alias glinscheid-exposed-exec="kubectl exec -it \$(kubectl get pod -l \"app.kubernetes.io/name=front-exposed-components\" -o jsonpath='{.items[0].metadata.name}') bash"
alias glinscheid-workers-tail='stern -n glinscheid -l "app.kubernetes.io/name=front-worker-components" --tail=0'
alias glinscheid-workers-exec="kubectl exec -it \$(kubectl get pod -l \"app.kubernetes.io/name=front-worker-components\" -o jsonpath='{.items[0].metadata.name}') bash"
alias glinscheid-workers-reload="kubectl exec -it \$(kubectl get pod -l \"app.kubernetes.io/name=front-worker-components\" -o jsonpath='{.items[0].metadata.name}') front-reload"

# Push front to staging.
function my-staging-push() {
  ## Check if repo is  git@github.com:frontapp/front-client.git
  if [ "$(git remote get-url origin)" != "git@github.com:frontapp/front.git" ]; then
    echo "Only the front repo can be pushed to staging."
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD)

  read "answer?Do you want to push $branch to HEAD:glinscheid/staging? (y/n): "
  case "$answer" in
    [Yy]* )
      echo "Pushing to staging: $branch"
      local cmd="git push origin HEAD:glinscheid/staging"
      echo $cmd
      eval $cmd
      ;;
    * )
      echo "Aborted staging push."
      return 1;
      ;;
  esac
}

alias mystaging-push='my-staging-push'

# front-client personal staging.
alias mystaging-client='export STAGING_NAMESPACE=glinscheid; npm run start:mystaging'

# Primary on call.
alias boga='${FRONTAPP_INFRA_DIR}/scripts/boga.sh'

