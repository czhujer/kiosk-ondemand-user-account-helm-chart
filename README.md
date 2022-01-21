# ondemand-user-account-helm-chart

- helm chart for creating user account (kiosk and cert-manager CRDs) in ["ondemand k8s envs"](https://www.notion.so/ataccama/Kubernetes-Replacement-for-Nomad-Deployments-for-Developer-efc7a69b9e3541b6a00bfe1b83aca18e)

## usage
helm upgrade --install ..

## features

### create single kiosk account, accountquota and space

### share space/namespace with another person(s)

#### final status
```shell
$ kubectl get accounts.config.kiosk.sh karel.kovarik -o yaml |yq eval '.spec' -
space:
  limit: 1
  spaceTemplate:
    metadata:
      annotations:
        email: Karel.Kovarik@ataccama.com
        workflowuid: 132041d7-1693-486a-a703-857e11db23e5
      creationTimestamp: null
      labels:
        personal: "true"
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: Jaroslav.Medek@ataccama.com
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: Karel.Kovarik@ataccama.com
```
```shell
$ kubectl -n patrik-majer get pods --as Karel.Kovarik@ataccama.com
Error from server (Forbidden): pods is forbidden: User "Karel.Kovarik@ataccama.com" cannot list resource "pods" in API group "" in the namespace "patrik-majer"

$ kubectl -n karel-kovarik get pods --as Jaroslav.Medek@ataccama.com |wc -l
      14
```

## authors
- Patrik Majer
- Lukas Mrtvy
