command=$(cat <<'COMMAND'
  echo -n '# ' && date &&
  kubectl get po -o go-template='
    {{range .items}}
      {{$p := . }}
      {{range .spec.containers }}
        {{$p.status.hostIP}} {{$p.spec.nodeName}} {{$p.status.podIP}} {{$p.metadata.name}} {{.name}} {{.image}} {{ print "\n" }}
      {{end}}
    {{end}}
  ' | sed '/^\s*$/d' | sed 's/^ *//;s/ *$//' | column -t -s ' '
COMMAND
)
alias kubectl-map="$command"
