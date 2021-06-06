package main

import (
	"reflect"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func Test_parseRequest(t *testing.T) {
	type args struct {
		event events.APIGatewayProxyRequest
	}
	tests := []struct {
		name string
		args args
		want RequestMatrix
	}{
		{name: "should parse request",
			args: args{
				events.APIGatewayProxyRequest{
					PathParameters: map[string]string{
						"proxy": "22cdhdhxjui6pa7l76n7zfbonu/resize;h=80;w=120;m=exact",
					},
				}},
			want: RequestMatrix{
				H:       80,
				W:       120,
				AssetId: "22cdhdhxjui6pa7l76n7zfbonu",
			}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := parseRequest(tt.args.event); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("parseRequest() = %v, want %v", got, tt.want)
			}
		})
	}
}
