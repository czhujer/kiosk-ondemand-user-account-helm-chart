# ondemand-user-account-helm-chart
- helm chart for creating user account (kiosk and cert-manager CRDs) in "ondemand k8s envs"

[[_TOC_]]

## usage
helm upgrade --install ..

## features

### create single kiosk account, accountquota and space + certificate

### create more kiosk spaces for kiosk account + certificate

### share space/namespace with another person(s)

#### final status
```shell
$ kubectl get accounts.config.kiosk.sh karel.second -o yaml |yq eval '.spec' -
space:
  limit: 1
  spaceTemplate:
    metadata:
      annotations:
        email: Karel.Second@company.com
        workflowuid: 132041d7-1693-486a-a703-857e11db23e5
      creationTimestamp: null
      labels:
        personal: "true"
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: Pavel.First@company.com
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: Karel.Second@company.com
```
```shell
$ kubectl -n patrik-majer get pods --as karel.second@company.com
Error from server (Forbidden): pods is forbidden: User "Karel.Second@company.com" cannot list resource "pods" in API group "" in the namespace "patrik-majer"

$ kubectl -n karel.second get pods --as Pavel.First@company.com |wc -l
      14
```
