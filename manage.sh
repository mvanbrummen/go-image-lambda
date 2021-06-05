#!/bin/bash
set -eo pipefail

create() {
	echo "Creating function..."
	aws lambda create-function \
			--function-name go-image-lambda \
			--handler main \
			--runtime go1.x \
			--role arn:aws:iam::492141138759:role/lambda-role \
			--package-type Zip \
			--zip-file fileb://function.zip
}

delete() {
	echo "Deleting function..."
	aws lambda delete-function --function-name go-image-lambda
}

build() {
	echo "Building..."
	GOARCH=amd64 GOOS=linux go build main.go
	echo "Remove function.zip..."
	rm function.zip
	echo "Creating zip.."
	zip function.zip main
}

invoke() {
	echo "Invoking..."
	aws lambda invoke --function-name go-image-lambda --payload file://payload.json --cli-binary-format raw-in-base64-out response.json
	cat response.json
}

if [ "$1" = "create" ]; then
	create
elif [ "$1" = "delete" ]; then
	delete
elif [ "$1" = "build" ]; then
	build
elif [ "$1" = "invoke" ]; then
	invoke	
fi
