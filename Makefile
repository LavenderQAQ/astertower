PROJECT=github.com/kasterism/astertower
VERSION=v1alpha1
PROJECT_APIS=${PROJECT}/pkg/apis/${VERSION}
CLIENTSET=${PROJECT}/pkg/clients/clientset
INFORMER=${PROJECT}/pkg/clients/informer
LISTER=${PROJECT}/pkg/clients/lister
HEADER=hack/boilerplate.go.txt

ifndef $(GOPATH)
	GOPATH=$(shell go env GOPATH)
	export GOPATH
endif
GOPATH_SRC=${GOPATH}/src

all: register-gen deepcopy-gen defaulter-gen openapi-gen client-gen lister-gen informer-gen

install-tools:
	go install k8s.io/code-generator/cmd/client-gen@v0.25.5
	go install k8s.io/code-generator/cmd/informer-gen@v0.25.5
	go install k8s.io/code-generator/cmd/deepcopy-gen@v0.25.5
	go install k8s.io/code-generator/cmd/lister-gen@v0.25.5
	go install k8s.io/code-generator/cmd/register-gen@v0.25.5
	go install k8s.io/code-generator/cmd/openapi-gen@v0.25.5
	go install k8s.io/code-generator/cmd/defaulter-gen@v0.25.5
	go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.11.1
	go install github.com/gogo/protobuf/protoc-gen-gogo@v1.3.2

deepcopy-gen:
	@echo ">> generating pkg/apis/${VERSION}/deepcopy_generated.go"
	deepcopy-gen --input-dirs ${PROJECT_APIS} \
		--output-package ${PROJECT_APIS} -h ${HEADER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${PROJECT_APIS}/deepcopy_generated.go pkg/apis/${VERSION}

register-gen:
	@echo ">> generating pkg/apis/${VERSION}/zz_generated.register.go"
	register-gen --input-dirs ${PROJECT_APIS} \
		--output-package ${PROJECT_APIS} -h ${HEADER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${PROJECT_APIS}/zz_generated.register.go pkg/apis/${VERSION}

defaulter-gen:
	@echo ">> generating pkg/apis/${VERSION}/zz_generated.defaults.go"
	defaulter-gen --input-dirs ${PROJECT_APIS} \
		--output-package ${PROJECT_APIS} -h ${HEADER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${PROJECT_APIS}/zz_generated.defaults.go pkg/apis/${VERSION}

openapi-gen:
	@echo ">> generating pkg/apis/${VERSION}/openapi_generated.go"
	openapi-gen --input-dirs ${PROJECT_APIS} \
		--output-package ${PROJECT_APIS} -h ${HEADER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${PROJECT_APIS}/openapi_generated.go pkg/apis/${VERSION}

client-gen:
	@echo ">> generating pkg/clients/clientset..."
	rm -rf pkg/clients/clientset
	client-gen --input-dirs ${PROJECT_APIS} \
		--clientset-name='astertower' \
		--fake-clientset=false \
		--input-base=${PROJECT} \
		--input='pkg/apis/${VERSION}' \
		--output-package ${CLIENTSET} -h ${HEADER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${CLIENTSET} pkg/clients

lister-gen:
	@echo ">> generating pkg/clients/lister..."
	rm -rf pkg/clients/lister
	lister-gen --input-dirs ${PROJECT_APIS} \
		--output-package ${LISTER} -h ${HEADER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${LISTER} pkg/clients

informer-gen:
	@echo ">> generating pkg/clients/informer..."
	rm -rf pkg/clients/informer
	informer-gen --input-dirs ${PROJECT_APIS} --versioned-clientset-package ${CLIENTSET}/astertower \
		--output-package ${INFORMER} -h ${HEADER} \
		--listers-package ${LISTER} \
	--alsologtostderr
	mv ${GOPATH_SRC}/${INFORMER} pkg/clients

go-to-protobuf:
	@echo ">> generating pkg/apis/${VERSION}/generated.proto"
	go-to-protobuf --output-base="${GOPATH_SRC}" \
	--packages="${PROJECT_APIS}" \
	--proto-import "${GOPATH_SRC}/github.com/gogo/protobuf/protobuf" \
	-h ${HEADER}
	mv ${GOPATH_SRC}/${PROJECT_APIS}/generated.proto pkg/apis/${VERSION}

crd:
	controller-gen crd:crdVersions=v1,allowDangerousTypes=true rbac:roleName=astertower-role webhook paths="./pkg/apis/..." output:crd:artifacts:config=crds output:crd:artifacts:config=charts/astertower/crds

goimports:
	go install golang.org/x/tools/cmd/goimports@latest

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

build: fmt vet ## Build manager binary.
	go build -o bin/astertower main.go

run: fmt vet ## Run code from your host.
	go run ./main.go

test:
	go test ./... -coverprofile cover.out

install:
	kubectl apply -f crds

uninstall:
	kubectl delete -f crds

STAGING_REGISTRY ?= kasterism
IMAGE_NAME ?= astertower
TAG ?= latest

IMG ?= ${STAGING_REGISTRY}/${IMAGE_NAME}:${TAG}
docker-build:
	docker buildx build -t ${IMG} . --load

docker-push:
	docker buildx build --platform linux/amd64,linux/arm64 -t ${IMG} . --push