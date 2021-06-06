package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"image/jpeg"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/nfnt/resize"
)

type RequestMatrix struct {
	AssetId string
	H       uint
	W       uint
}

func parseRequest(event events.APIGatewayProxyRequest) RequestMatrix {
	proxy := event.PathParameters["proxy"]

	parts := strings.Split(proxy, "/")
	matrixStr := strings.Replace(parts[1], "resize;", "", 1)
	matrixParams := strings.Split(matrixStr, ";")

	m := make(map[string]string, len(matrixParams))
	for _, param := range matrixParams {
		p := strings.Split(param, "=")
		m[p[0]] = p[1]
	}
	h, _ := strconv.Atoi(m["h"])
	w, _ := strconv.Atoi(m["w"])

	return RequestMatrix{
		AssetId: parts[0],
		H:       uint(h),
		W:       uint(w),
	}
}

func HandleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Load the Shared AWS Configuration (~/.aws/config)
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	request := parseRequest(event)

	// Create an Amazon S3 service client
	client := s3.NewFromConfig(cfg)

	imageObject, err := client.GetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(os.Getenv("SOURCE_BUCKET")),
		Key:    aws.String(os.Getenv("SOURCE_ROOT_PATH") + "perm/" + request.AssetId),
	})
	if err != nil {
		log.Fatal(err)
	}

	image, err := jpeg.Decode(imageObject.Body)
	if err != nil {
		panic(err)
	}

	m := resize.Resize(request.W, request.H, image, resize.Lanczos3)

	if err != nil {
		log.Fatal(err)
	}
	b := new(bytes.Buffer)
	err = jpeg.Encode(b, m, nil)

	stringBody := base64.StdEncoding.EncodeToString(b.Bytes())

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
