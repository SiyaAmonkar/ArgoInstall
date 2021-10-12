#!/bin/bash
SA=default
PROJECT=$(oc project -q)
oc get secret quaylogin -n argo -oyaml | sed '/namespace/d' | oc apply -n ${PROJECT} -f -
oc patch serviceaccount default -p '{"imagePullSecrets": [{"name": "quaylogin"}]}'

#Add serviceaccounts to privileged securitycontextconstraint
oc adm policy add-scc-to-user privileged system:serviceaccount:${PROJECT}:${SA}
#oc adm policy add-scc-to-user privileged system:serviceaccount:${PROJECT}:argo

#Add to ARGO image pull and push
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROJECT}:${SA} -n argo
oc policy add-role-to-user system:image-builder system:serviceaccount:${PROJECT}:${SA} -n argo

#Add to local project image pull and push
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROJECT}:${SA} -n ${PROJECT}

oc policy add-role-to-user system:image-builder system:serviceaccount:${PROJECT}:${SA} -n ${PROJECT}
#oc policy add-role-to-user system:image-pusher system:serviceaccount:${PROJECT}:${SA} -n ${PROJECT}

#Add ability to monitor pod status
oc policy add-role-to-user argo-cluster-role system:serviceaccount:${PROJECT}:${SA}

#Create secret from service account
SECRET=$(oc get sa ${SA} -o jsonpath='{.secrets[0].name}')
echo "My scret $SECRET"

KEY=$(oc sa get-token  ${SA})
oc delete secret oc-registry-cred
oc create secret docker-registry oc-registry-cred --namespace ${PROJECT} --docker-server image-registry.openshift-image-registry.svc:5000 --docker-username serviceaccount --docker-password ${KEY}
