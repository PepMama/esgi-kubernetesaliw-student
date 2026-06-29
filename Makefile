SHELL := /bin/bash
CLUSTER ?= salleenfrance
SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
SERVICES := frontend auth-service sites-service rooms-service bookings-service

.PHONY: help compose-up compose-down seed kind-up kind-down images kind-load deploy test-e2e clean pdf

help:
	@echo "Cibles disponibles :"
	@echo "  compose-up    - Démarrer la stack docker-compose (point de départ)"
	@echo "  compose-down  - Arrêter la stack docker-compose"
	@echo "  seed          - Injecter les données de test"
	@echo "  kind-up       - Provisionner le cluster kind via Terraform"
	@echo "  kind-down     - Détruire le cluster"
	@echo "  images        - Construire les 5 images Docker (tag = SHA court)"
	@echo "  kind-load     - Charger les images dans les nœuds kind"
	@echo "  deploy        - kubectl apply -k k8s/overlays/dev"
	@echo "  test-e2e      - Lancer les tests d'intégration end-to-end"
	@echo "  pdf           - Régénérer le polycopié PDF"
	@echo "  clean         - Nettoyer les artefacts locaux"

compose-up:
	docker compose up -d --build

compose-down:
	docker compose down -v

seed:
	docker compose exec -T postgres psql -U salleenfrance -d salleenfrance < seed/init.sql

kind-up:
	cd terraform && terraform init && terraform apply -auto-approve
	@echo ">>> kubeconfig = $$(cd terraform && terraform output -raw kubeconfig_path)"

kind-down:
	cd terraform && terraform destroy -auto-approve

images:
	docker build -t salleenfrance/frontend:$(SHA) -f docker/Dockerfile.frontend apps/frontend
	@for svc in auth-service sites-service rooms-service bookings-service; do \
		echo ">>> build $$svc"; \
		docker build -t salleenfrance/$$svc:$(SHA) -f docker/Dockerfile.next --build-arg SERVICE=$$svc apps/$$svc; \
	done

kind-load:
	@for svc in $(SERVICES); do \
		echo ">>> kind load $$svc:$(SHA)"; \
		kind load docker-image salleenfrance/$$svc:$(SHA) --name $(CLUSTER); \
	done

deploy:
	IMAGE_TAG=$(SHA) envsubst < k8s/overlays/dev/kustomization.tmpl.yaml > k8s/overlays/dev/kustomization.yaml
	kubectl apply -k k8s/overlays/dev

test-e2e:
	bash scripts/test-e2e.sh

pdf:
	pandoc POLYCOPIE.md -o POLYCOPIE.pdf --pdf-engine=typst --toc --toc-depth=2 \
		-V mainfont="Helvetica" -V monofont="Menlo" -V fontsize=10pt -V geometry:margin=2cm

clean:
	docker compose down -v 2>/dev/null || true
	rm -f POLYCOPIE.pdf
	rm -rf terraform/.terraform terraform/terraform.tfstate*
