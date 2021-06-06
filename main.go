package main

import (
	"context"
	"encoding/base64"
	"io/ioutil"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func HandleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Load the Shared AWS Configuration (~/.aws/config)
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	// Create an Amazon S3 service client
	client := s3.NewFromConfig(cfg)

	imageObject, err := client.GetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String("dasless-images"),
		Key:    aws.String("assets/perm/22cdhdhxjui6pa7l76n7zfbonu"),
	})
	if err != nil {
		log.Fatal(err)
	}

	body, err := ioutil.ReadAll(imageObject.Body)

	if err != nil {
		log.Fatal(err)
	}

	stringBody := base64.StdEncoding.EncodeToString(body)

	return events.APIGatewayProxyResponse{
		Body:            stringBody,
		StatusCode:      200,
		IsBase64Encoded: true,
		Headers: map[string]string{
			"Content-Type": "image/jpeg",
		},
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
