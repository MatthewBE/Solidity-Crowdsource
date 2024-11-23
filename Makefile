-include .env
.PHONY: all test clean deploy fund 

update:; forge update

build:; forge build

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

