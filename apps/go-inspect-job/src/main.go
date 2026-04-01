package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/andreswebs/inspect-cloud-run-job/logx"
)

var log *logx.Logger

func init() {
	log = logx.New()
}

const (
	metadataURL    = "http://169.254.169.254/computeMetadata/v1"
	metadataFlavor = "Google"
	exitNotOnGCP   = 2
)

type Inspector struct {
	client *http.Client
}

func NewInspector() *Inspector {
	return &Inspector{
		client: &http.Client{Timeout: 3 * time.Second},
	}
}

func (i *Inspector) fetch(path string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", metadataURL+path, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Metadata-Flavor", metadataFlavor)

	resp, err := i.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("metadata server returned %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(body)), nil
}

func (i *Inspector) fetchOrEmpty(path string) string {
	val, _ := i.fetch(path)
	return val
}

func (i *Inspector) IsOnGCP() bool {
	_, err := i.fetch("/project/project-id")
	return err == nil
}

type IdentityCard struct {
	// Project info
	ProjectID     string `json:"project_id"`
	ProjectNumber string `json:"project_number"`
	Zone          string `json:"zone"`
	Region        string `json:"region"`

	// Service account
	ServiceAccountEmail  string   `json:"service_account_email"`
	ServiceAccountScopes []string `json:"service_account_scopes"`

	// Instance
	InstanceID string `json:"instance_id"`
	Hostname   string `json:"hostname"`

	// Cloud Run Job specifics (from env vars)
	CloudRunJob       string `json:"cloud_run_job,omitempty"`
	CloudRunExecution string `json:"cloud_run_execution,omitempty"`
	CloudRunTaskIndex string `json:"cloud_run_task_index,omitempty"`
	CloudRunTaskCount string `json:"cloud_run_task_count,omitempty"`

	// Cloud Run Service specifics (in case run as service)
	KService       string `json:"k_service,omitempty"`
	KRevision      string `json:"k_revision,omitempty"`
	KConfiguration string `json:"k_configuration,omitempty"`
}

func (i *Inspector) GatherIdentity() IdentityCard {
	card := IdentityCard{}

	// Project info
	card.ProjectID = i.fetchOrEmpty("/project/project-id")
	card.ProjectNumber = i.fetchOrEmpty("/project/numeric-project-id")
	card.Zone = i.fetchOrEmpty("/instance/zone")
	if parts := strings.Split(card.Zone, "/"); len(parts) > 0 {
		card.Zone = parts[len(parts)-1]
	}
	if card.Zone != "" && len(card.Zone) > 2 {
		card.Region = card.Zone[:len(card.Zone)-2]
	}

	// Service account
	card.ServiceAccountEmail = i.fetchOrEmpty("/instance/service-accounts/default/email")
	scopesStr := i.fetchOrEmpty("/instance/service-accounts/default/scopes")
	if scopesStr != "" {
		card.ServiceAccountScopes = strings.Split(scopesStr, "\n")
	}

	// Instance
	card.InstanceID = i.fetchOrEmpty("/instance/id")
	card.Hostname = i.fetchOrEmpty("/instance/hostname")

	// Cloud Run Job env vars
	card.CloudRunJob = os.Getenv("CLOUD_RUN_JOB")
	card.CloudRunExecution = os.Getenv("CLOUD_RUN_EXECUTION")
	card.CloudRunTaskIndex = os.Getenv("CLOUD_RUN_TASK_INDEX")
	card.CloudRunTaskCount = os.Getenv("CLOUD_RUN_TASK_COUNT")

	// Cloud Run Service env vars
	card.KService = os.Getenv("K_SERVICE")
	card.KRevision = os.Getenv("K_REVISION")
	card.KConfiguration = os.Getenv("K_CONFIGURATION")

	return card
}

func main() {
	inspector := NewInspector()

	if !inspector.IsOnGCP() {
		log.Error("not running on GCP", "reason", "metadata server unreachable")
		os.Exit(exitNotOnGCP)
	}

	card := inspector.GatherIdentity()

	log.Info("identity", card)
}
