FROM alpine:3.10

LABEL "com.github.actions.name"="Auto create PR from head branch against base branch"
LABEL "com.github.actions.description"="Auto Creates PR for commits pushed to head branch against base branch (if base branch is behind)."
LABEL "com.github.actions.icon"="activity"
LABEL "com.github.actions.color"="green"

LABEL version="1.0.0"
LABEL repository="http://github.com/poorva17/create-pr-action"
LABEL homepage="http://github.com/poorva17/create-pr-action"
LABEL maintainer="Poorva Gokhale"

RUN apk update && apk add bash git curl jq

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
