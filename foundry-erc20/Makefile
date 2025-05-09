ifeq (,$(wildcard .env))
    $(error .env file not found! Please create one with your environment variables.)
endif
include .env
export

echo:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  deploy       Deploy the contract to the network"
	@echo "  local        Run a local script"

deploy:
	@forge create src/AuroraEngineToken.sol:AuroraEngineToken \
		--force \
		 --broadcast \
		--optimize \
		--legacy \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		 --chain $(AURORA_TESTNET_RPC_CHAIN_ID) \
		--private-key $(AURORA_PRIVATE_KEY)
		"Aurora Engine Token" "AET"

call-transfer:
	@cast send $(AURORA_CONTRACT1_ADDRESS) "transfer(address,uint256)" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE2_KEY) \
		$(AURORA_PUBLIC_KEY) 1000000000000000000

send-balanceOf:
	@cast call $(AURORA_CONTRACT1_ADDRESS) "balanceOf(address)" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY) \
		$(NEAR_ACCOUNT_EVM_ADDRESS)

near-call-transfer:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(NEAR_TESTNET_ACCOUNT_ID) \
		--input $(shell cast calldata "transfer(address,uint256)" $(AURORA_PUBLIC2_KEY) 1000000000000000000 | sed 's/^0x//')

near-view-balanceOf:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) view-call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/AuroraEngineToken.sol/AuroraEngineToken.abi.json \
		--function balanceOf \
		--args '{"account": "$(NEAR_ACCOUNT_EVM_ADDRESS)"}'

near-submit-transfer:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) submit \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/AuroraEngineToken.sol/AuroraEngineToken.abi.json \
		--function transfer \
		--args '{"to": "$(AURORA_PUBLIC2_KEY)", "value": "1000000000000000000"}' \

get-interface:
	@cast interface out/AuroraEngineToken.sol/AuroraEngineToken.abi.json:AuroraEngineToken

build-abi:
	@forge build --extra-output-files abi --extra-output-files bin

near-deploy:
	aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) deploy \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--code $(shell cat out/AuroraEngineToken.sol/AuroraEngineToken.bin)\
		--abi-path out/AuroraEngineToken.sol/AuroraEngineToken.abi.json \
		--args '{"name": "Aurora Engine Token", "symbol": "AET"}'

near-deploy2:
	@aurora-cli-adv -c aurora-config.json near write deploy-code \
		$(shell cat out/AuroraEngineToken.sol/AuroraEngineToken.bin | tr -d '\n\r')$(shell cast ae "constructor(string,string)" "Aurora Engine Token" "AET" | sed 's/^0x//')

near-call-balanceOf2:
	@aurora-cli-adv -c aurora-config.json near read engine-call \
		-t $(AURORA_CONTRACT1_ADDRESS) \
		-i $(shell cast calldata "balanceOf(address)" 0x0 | sed 's/^0x//')

