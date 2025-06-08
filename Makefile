REPO ?= $(shell git config --get remote.origin.url | sed -E 's#.*/([^/]+/[^/.]+)(\.git)?$#\1#')
OWNER1 ?= 0xOWNER1
OWNER2 ?= 0xOWNER2
OWNER3 ?= 0xOWNER3

.PHONY: all safe monitoring agent

all: safe monitoring agent ## Everything in one go

safe: node_modules
@echo "🚀  Deploying Safe … (network sepolia)"
pnpm dlx @safe-global/cli deploy \
  --network sepolia \
  --owners $(OWNER1) $(OWNER2) $(OWNER3) \
  --threshold 2 \
  --json > safe.json
@export GB_TREASURY=$$(jq -r .address safe.json) && \
  echo "GB_TREASURY=$$GB_TREASURY" | gh secret set GB_TREASURY --repo $(REPO) --body - && \
  echo "GB_TREASURY=$$GB_TREASURY" >> .env && \
  echo "🏦  Safe deployed at $$GB_TREASURY"

monitoring:
@echo "📊  Starting Loki + Grafana stack …"
cd ops && docker compose up -d
@echo "🔎  Grafana on http://$(shell hostname -I | awk '{print $$1}'):3000  (admin / changeme)"

agent:
@echo "🤖  Building + pushing hello-loki agent …"
docker build -t ghcr.io/$(REPO)/ping-loki:latest agents/ping-loki
echo $$GITHUB_TOKEN | docker login ghcr.io -u $$GITHUB_ACTOR --password-stdin
docker push ghcr.io/$(REPO)/ping-loki:latest

node_modules: package.json
pnpm install
