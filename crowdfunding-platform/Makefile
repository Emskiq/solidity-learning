-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil coverage

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
    @echo "Usage:"
    @echo "  make deploy [ARGS=...]"
    @echo "    example: make deploy ARGS=\"--network sepolia\""
    @echo ""
    @echo "  make test"
    @echo "  make coverage"
    @echo "  make anvil"
    @echo "  etc."

all: clean install update build

clean:
    forge clean

install:
    forge install foundry-rs/forge-std@v1.5.3 --no-commit
    forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit
    # Add other dependencies as needed

update:
    forge update

build:
    forge build

test:
    forge test

coverage:
    forge coverage --report debug > coverage-report.txt

snapshot:
    forge snapshot

format:
    forge fmt

anvil:
    anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

########################
# Network Configuration
########################
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
    NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

########################
# Deployment Commands
########################
deploy:
    forge script script/DeployPlatform.s.sol:DeployPlatform $(NETWORK_ARGS)

