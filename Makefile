include .env

# deps
update:; forge update
build  :; forge build
size  :; forge build --sizes

# storage inspection
inspect :; forge inspect ${contract} storage-layout --pretty
# Get the list of function selectors
selectors  :; forge inspect ${contract} methods --pretty

# local tests without fork
test  :; forge test -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} -vv
trace  :; forge test  -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} --evm-version cancun -vvv
gas  :; forge -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} test --gas-report
test-contract  :; forge test -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} -vv --match-contract $(contract)
test-contract-gas  :; forge test -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} --gas-report --match-contract ${contract}
trace-contract  :; forge test -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} -vvv --match-contract $(contract)
test-test  :; forge test -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} -vv --match-test $(test)
trace-test  :; forge test -f https://eth-mainnet.g.alchemy.com/v2/${API_KEY_ALCHEMY} -vvv --match-test $(test)

clean  :; forge clean
snapshot :; forge snapshot