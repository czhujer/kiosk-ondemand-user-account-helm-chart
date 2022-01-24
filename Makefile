# Set environment variables
export CLUSTER_NAME?=kind-kiosk
export CILIUM_VERSION?=1.11.1
export KIOSK_VERSION?=0.2.11
#export KIOSK_VERSION?=0.2.9
export NAMESPACE=patrik-majer
# for MacOS
CERT_EXPIRY := $(shell sh -c "date -v +3y -j '+%Y-%m-%dT%H:%M:%SZ'")
# for linux
# CERT_EXPIRY := $(shell sh -c "date -d '+8760 hour' +\"%Y-%m-%dT%H:%M:%SZ\"")

.PHONY: kind-all
#kind-all: kind-create kx-kind cilium-install deploy-cert-manager kiosk-install install-nginx-ingress deploy-prometheus-stack
kind-all: kind-create kx-kind cilium-install deploy-cert-manager kiosk-install

.PHONY: kind-create
kind-create:
	kind --version
	kind create cluster --name $(CLUSTER_NAME) --config="kind/kind-config.yaml" --wait 20s
	# for testing PSP
	#	kubectl apply -f https://github.com/appscodelabs/tasty-kube/raw/master/psp/privileged-psp.yaml
	#	kubectl apply -f https://github.com/appscodelabs/tasty-kube/raw/master/psp/baseline-psp.yaml
	#	kubectl apply -f https://github.com/appscodelabs/tasty-kube/raw/master/psp/restricted-psp.yaml
	#	kubectl apply -f https://github.com/appscodelabs/tasty-kube/raw/master/kind/psp/cluster-roles.yaml
	#	kubectl apply -f https://github.com/appscodelabs/tasty-kube/raw/master/kind/psp/role-bindings.yaml
	# for more control planes, but no workers
	# kubectl taint nodes --all node-role.kubernetes.io/master- || true
	# harmonize namespace with ondemand envs
	# kubectl create ns $(NAMESPACE)

.PHONY: kind-delete
kind-delete:
	kind delete cluster --name $(CLUSTER_NAME)

.PHONY: kx-kind
kx-kind:
	kind export kubeconfig --name $(CLUSTER_NAME)


#.PHONY: workload-purge
#workload-purge:
#	helm un one20 -n $(NAMESPACE)
##	devspace purge --all
#	kubectl -n $(NAMESPACE) delete pvc --all

.PHONY: cilium-install
cilium-install:
	# pull image locally
	docker pull quay.io/cilium/cilium:v$(CILIUM_VERSION)
	# Load the image onto the cluster
	kind load docker-image \
 		--name $(CLUSTER_NAME) \
 		quay.io/cilium/cilium:v$(CILIUM_VERSION)
	# Add the Cilium repo
	helm repo add cilium https://helm.cilium.io/
	# install/upgrade the chart
	helm upgrade --install cilium cilium/cilium --version $(CILIUM_VERSION) \
	   -f kind/kind-values-cilium-hubble.yaml \
   	   --wait \
	   --namespace kube-system \
	   --set operator.replicas=1 \
	   --set nodeinit.enabled=true \
	   --set kubeProxyReplacement=partial \
	   --set hostServices.enabled=false \
	   --set externalIPs.enabled=true \
	   --set nodePort.enabled=true \
	   --set hostPort.enabled=true \
	   --set bpf.masquerade=false \
	   --set image.pullPolicy=IfNotPresent \
	   --set ipam.mode=kubernetes

.PHONY: install-nginx-ingress
install-nginx-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
	kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io ingress-nginx-admission

.PHONY: deploy-cert-manager
deploy-cert-manager:
	kind/cert-manager_install.sh

.PHONY: deploy-prometheus-stack
deploy-prometheus-stack:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm upgrade --install \
	prometheus-stack \
	prometheus-community/kube-prometheus-stack \
	--namespace monitoring \
    --create-namespace \
    --set kubeStateMetrics.enabled=false \
    --set nodeExporter.enabled=false \
    --set alertmanager.enabled=false,kubeApiServer.enabled=false \
    --set kubelet.enabled=false \
    --set kubeControllerManager.enabled=false,coredns.enabled=false \
    --set prometheus.enabled=false \
    --set grafana.enabled=false \
    --set prometheusOperator.admissionWebhooks.enabled=false \
    --set prometheusOperator.tls.enabled=false

.PHONY: kiosk-install
kiosk-install:
	kubectl create namespace kiosk || true
	helm upgrade --install \
	kiosk \
	--version $(KIOSK_VERSION) \
	--namespace kiosk --atomic \
	--repo https://charts.devspace.sh/ \
	kiosk

.PHONY: chart-upgrade
chart-upgrade:
	EMAIL="Patrik.Majer1@ataccama.com"; \
	CHARTNAME=$$(echo $$EMAIL |sed 's/[@|_|.]/-/g' | tr '[:upper:]' '[:lower:]'); \
	helm upgrade --install \
	-n default \
	--set=email=$$EMAIL \
	--set=account.shareWith[0]=Pavel.First@ataccama.com \
	--set=account.shareWith[1]=Jan.Second@ataccama.com \
	--set=indexedSpace.count=3 \
	"ondemand-user-account-$${CHARTNAME}" \
	./ondemand-user-account

#.PHONY: k8s-apply
#k8s-apply:
#	kubectl get ns cilium-linkerd 1>/dev/null 2>/dev/null || kubectl create ns cilium-linkerd
#	kubectl apply -k k8s/podinfo -n cilium-linkerd
#	kubectl apply -f k8s/client
#	kubectl apply -f k8s/networkpolicy
#
#.PHONY: check-status
#check-status:
#	linkerd top deployment/podinfo --namespace cilium-linkerd
#	linkerd tap deployment/client --namespace cilium-linkerd
#	kubectl exec deploy/client -n cilium-linkerd -c client -- curl -s podinfo:9898

