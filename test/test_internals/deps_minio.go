package test_internals

import (
	"context"
	"fmt"
	"io"
	"log"

	"github.com/docker/go-connections/nat"
	"github.com/testcontainers/testcontainers-go"
	tcexec "github.com/testcontainers/testcontainers-go/exec"
	"github.com/testcontainers/testcontainers-go/wait"
)

type MinioDep struct {
	ctx       context.Context
	container testcontainers.Container

	Endpoint         string
	ExternalEndpoint string
}

func MakeMinio(depNet *NetworkDep) (*MinioDep, error) {
	ctx := context.Background()

	s3Port, _ := nat.NewPort("tcp", "9000")
	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: testcontainers.ContainerRequest{
			FromDockerfile: testcontainers.FromDockerfile{
				Context:       "./test",
				Dockerfile:    "Dockerfile.minio",
				PrintBuildLog: true,
			},
			ExposedPorts: []string{"9000/tcp", "9090/tcp"},
			Env: map[string]string{
				"MINIO_ROOT_USER":     "admin",
				"MINIO_ROOT_PASSWORD": "test1234",
			},
			WaitingFor: wait.ForHTTP("/minio/health/ready").WithPort(s3Port),
			Networks:   []string{depNet.NetId},
			// No volumes are needed for disposable test data.
		},
		Started: true,
	})
	if err != nil {
		return nil, err
	}

	// Configure the bucket and service account with the client bundled in the image.
	exitCode, output, err := container.Exec(ctx, []string{"sh", "/usr/local/bin/configure-minio.sh"}, tcexec.Multiplexed())
	if err != nil {
		return nil, err
	}
	if exitCode != 0 {
		message, _ := io.ReadAll(output)
		return nil, fmt.Errorf("configure MinIO: exit code %d: %s", exitCode, message)
	}

	minioIp, err := container.ContainerIP(ctx)
	if err != nil {
		return nil, err
	}
	minioHost, err := container.Host(ctx)
	if err != nil {
		return nil, err
	}
	minioPort, err := container.MappedPort(ctx, s3Port)
	if err != nil {
		return nil, err
	}

	return &MinioDep{
		ctx:              ctx,
		container:        container,
		Endpoint:         fmt.Sprintf("%s:%d", minioIp, 9000),
		ExternalEndpoint: fmt.Sprintf("%s:%d", minioHost, minioPort.Int()),
	}, nil
}

func (c *MinioDep) Teardown() {
	if err := c.container.Terminate(c.ctx); err != nil {
		log.Fatalf("Error shutting down minio: %s", err.Error())
	}
}
