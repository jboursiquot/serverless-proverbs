PROJECT = $(shell basename $(CURDIR))
CF_TEMPLATE ?= template.yaml
PACKAGE_TEMPLATE = package.yaml
BUCKET ?= unspecified
STACK_NAME ?= $(PROJECT)

.PHONY: deps clean build

deps:
	go get -u ./...

clean:
	-rm -rf build/*
	-rm package.yaml

test:
	go test -race -v ./...

bucket:
	aws s3 mb s3://$(BUCKET)

build:
	GOOS=linux GOARCH=amd64 go build -v -o ./build/proverbial ./cmd/proverbial

zip:
	@cd ./build && zip proverbial.zip proverbial

package: test build zip
	sam validate --template $(CF_TEMPLATE)
	sam package \
		--debug \
		--template-file $(CF_TEMPLATE) \
		--output-template-file $(PACKAGE_TEMPLATE) \
		--s3-bucket $(BUCKET)

deploy: clean package
	sam deploy \
		--template-file $(PACKAGE_TEMPLATE) \
		--stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

destroy:
	aws cloudformation delete-stack \
		--stack-name $(STACK_NAME)

outputs:
	aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[].Outputs' \
		--output json

describe:
	aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--output json