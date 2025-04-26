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
	@forge create src/Counter.sol:Counter \
		--force \
		 --broadcast \
		--optimize \
		--legacy \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		 --chain $(AURORA_TESTNET_RPC_CHAIN_ID) \
		--private-key $(AURORA_PRIVATE_KEY)

call-number:
	@cast call $(AURORA_CONTRACT1_ADDRESS) "number()" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY)

send-inc:
	@cast send $(AURORA_CONTRACT1_ADDRESS) "increment()" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY)

send-set-number:
	@cast send $(AURORA_CONTRACT1_ADDRESS) "setNumber(uint256)" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY) \
		0xF0FAF7

local:
	@forge script script/Counter.s.sol:CounterScript --fork-url http://localhost:8545 --broadcast --interactives 1

near-call-set-number:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(NEAR_TESTNET_ACCOUNT_ID) \
		--input "3fb5c1cb0A000000000000000000000000000000000000000000000000000000000001fc"


near-view-number:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) view-call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function number

near-submit-number:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) submit \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function setNumber \
		--args '{"newNumber": "128"}'

near-submit-increment:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) submit \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function increment

get-interface:
	@cast interface src/Counter.sol:Counter

build-abi:
	@forge build --extra-output-files abi --extra-output-files bin
