#!/bin/zsh

# Frontapp

export CANARY_USER='glinscheid'

alias cdf='cd ~/frontapp'
alias cdfinfra='cd ~/frontapp/front-infra'
alias cdffront='cd ~/frontapp/front'
alias cdfclient='cd ~/frontapp/front-client'
alias cdfchat='cd ~/frontapp/front-chat'
alias cdfchatsdk='cd ~/frontapp/front-chat-sdk'

alias front-sso='aws sso login'

alias ssh-front-us-preprod='ssh aws-us-api-preprod'

alias staging-tail-exposed="stern -n glinscheid -l \"app.kubernetes.io/name=front-exposed-components\" --tail=0"
alias staging-tail-worker="stern -n glinscheid -l \"app.kubernetes.io/name=front-worker-components\" --tail=0"

alias kubectl-ctx='kubectl config use-context'

alias kctx-stg='kubectl-ctx usw2.staging'
alias kctx-us1='kubectl-ctx usw1.prod'
alias kctx-us2='kubectl-ctx usw2.prod'
alias kctx-eu='kubectl-ctx euw1.prod'

alias stg-kibana-docker='docker run -d -p 5601:5601  -e "ELASTICSEARCH_HOSTS=http://host.docker.internal:9200" docker.elastic.co/kibana/kibana:6.8.5'
alias stg-analytics-cluster='kubectl port-forward -n search statefulset/es-analytics-cluster 9200'
alias stg-search-full-cluster='kubectl-ctx usw2.staging && kubectl port-forward -n search sts/es-full-cluster 9200'

alias glinscheid-exposed-tail='stern -n glinscheid -l "app.kubernetes.io/name=front-exposed-components" --tail=0'
alias glinscheid-exposed-exec="kubectl exec -it \$(kubectl get pod -l \"app.kubernetes.io/name=front-exposed-components\" -o jsonpath='{.items[0].metadata.name}') bash"
alias glinscheid-workers-tail='stern -n glinscheid -l "app.kubernetes.io/name=front-worker-components" --tail=0'
alias glinscheid-workers-exec="kubectl exec -it \$(kubectl get pod -l \"app.kubernetes.io/name=front-worker-components\" -o jsonpath='{.items[0].metadata.name}') bash"
alias glinscheid-workers-reload="kubectl exec -it \$(kubectl get pod -l \"app.kubernetes.io/name=front-worker-components\" -o jsonpath='{.items[0].metadata.name}') front-reload"

alias mystaging='export STAGING_NAMESPACE=glinscheid; npm run start:mystaging'

alias boga='~/frontapp/front-infra/scripts/boga.sh'

## tmux sessions
alias tmux-fchat='cdfchat && tmux-attach fchat'
alias tmux-fclient='cdfclient && tmux-attach fclient'
alias tmux-ffront='cdffront && tmux-attach front'
