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

deploy-script:
	@forge script script/DeployCounter.s.sol:DeployCounterScript \
		--optimize \
		--legacy \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--chain-id $(AURORA_TESTNET_RPC_CHAIN_ID) \
		--broadcast \
		--sig "run()" \
		-vvvv

deploy:
	@forge create src/Counter.sol:Counter \
		--force \
		 --broadcast \
		--optimize \
		--legacy \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		 --chain $(AURORA_TESTNET_RPC_CHAIN_ID) \
		--private-key $(AURORA_PRIVATE_KEY)

local:
	@forge script script/Counter.s.sol:CounterScript --fork-url http://localhost:8545 --broadcast --interactives 1

get-interface:
	@cast interface src/Counter.sol:Counter

build-abi:
	@forge build	 \
		--extra-output-files abi \
		--extra-output-files bin

near-deploy:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) deploy \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--code $(shell cat out/Counter.sol/Counter.bin)\
		--abi-path out/Counter.sol/Counter.abi.json \
		--args '{"_nearAccountId": "counter-contract-001.testnet", "_wNEAR": "0x4861825E75ab14553E5aF711EbbE6873d369d146", "_number": "0"}'

#========================================================
# Set number
near-call-set-number:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(NEAR_TESTNET_ACCOUNT_ID) \
		--input "3fb5c1cb0A000000000000000000000000000000000000000000000000000000000001fc"

near-send-set-number:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) submit \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function setNumber \
		--args '{"newNumber": "128"}'

send-set-number:
	@cast send $(AURORA_CONTRACT1_ADDRESS) "setNumber(uint256)" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY) \
		0xF0FAF7

#========================================================
# Allowance and approval for wNEAR contract
send-approve:
	@cast send 0x4861825E75ab14553E5aF711EbbE6873d369d146 "approve(address,uint256)" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY) \
		$(AURORA_CONTRACT1_ADDRESS) 3000000000000000000000000

view-allowance:
	@cast call 0x4861825E75ab14553E5aF711EbbE6873d369d146 "allowance(address,address)" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY) \
		$(AURORA_PUBLIC_KEY) $(AURORA_CONTRACT1_ADDRESS)

#========================================================
# XCC increment
near-call-inc-aurora:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(NEAR_TESTNET_ACCOUNT_ID) \
		--input $(shell cast calldata "nearIncCall()" | sed 's/^0x//')

near-send-inc-aurora:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) submit \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function nearIncCall

send-inc-aurora:
	@cast send $(AURORA_CONTRACT1_ADDRESS) "nearIncCall()" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY)

#========================================================
# View the current number
near-view-number-adv:
	@aurora-cli-adv -c aurora-config.json near read engine-call \
		-t $(AURORA_CONTRACT1_ADDRESS) \
		-i $(shell cast calldata "number()" | sed 's/^0x//')

near-view-number:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) view-call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function number

view-number:
	@cast call $(AURORA_CONTRACT1_ADDRESS) "number()" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY)

#========================================================
# Incrementing the counter
near-call-inc-adv:
	@aurora-cli-adv -c aurora-config.json near read engine-call \
		-t $(AURORA_CONTRACT1_ADDRESS) \
		-i $(shell cast calldata "increment()" | sed 's/^0x//')

near-call-inc:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) call \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--from $(NEAR_TESTNET_ACCOUNT_ID) \
		--input $(shell cast calldata "increment()" | sed 's/^0x//')

near-send-inc:
	@aurora-cli --network testnet --near-key-path $(NEAR_TESTNET_CREDENTIALS) submit \
		--aurora-secret-key $(AURORA_FOR_NEAR_PRIVATE_KEY) \
		--address $(AURORA_CONTRACT1_ADDRESS) \
		--abi-path out/Counter.sol/Counter.abi.json \
		--function increment

send-inc:
	@cast send $(AURORA_CONTRACT1_ADDRESS) "increment()" \
		--rpc-url $(AURORA_TESTNET_RPC_URL) \
		--legacy \
		--private-key $(AURORA_PRIVATE_KEY)
