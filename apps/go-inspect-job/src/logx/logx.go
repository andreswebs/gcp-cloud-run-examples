// Package logx provides GCP-compatible structured logging to stderr.
// Log entries use GCP's expected JSON format with severity, message, timestamp,
// and optional labels for Cloud Run job context.
// Based on: https://dev.to/amammay/effective-go-on-cloud-run-structured-logging-56bd
package logx

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// Severity levels as expected by GCP Cloud Logging
const (
	SeverityDebug    = "DEBUG"
	SeverityInfo     = "INFO"
	SeverityNotice   = "NOTICE"
	SeverityWarning  = "WARNING"
	SeverityError    = "ERROR"
	SeverityCritical = "CRITICAL"
	SeverityAlert    = "ALERT"
)

// LogEntry represents a GCP Cloud Logging structured log entry.
// See: https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry
type LogEntry struct {
	Severity  string            `json:"severity"`
	Message   string            `json:"message"`
	Timestamp time.Time         `json:"timestamp"`
	Labels    map[string]string `json:"logging.googleapis.com/labels,omitempty"`
	Data      any               `json:"data,omitempty"`

	// Trace context (for services with HTTP requests)
	TraceID      string `json:"logging.googleapis.com/trace,omitempty"`
	SpanID       string `json:"logging.googleapis.com/spanId,omitempty"`
	TraceSampled bool   `json:"logging.googleapis.com/trace_sampled,omitempty"`
}

// Logger provides structured logging with Cloud Run context.
type Logger struct {
	labels map[string]string
}

// New creates a Logger with Cloud Run job context labels.
// Labels are automatically attached to every log entry.
func New() *Logger {
	labels := make(map[string]string)

	// Cloud Run Job context
	if job := os.Getenv("CLOUD_RUN_JOB"); job != "" {
		labels["cloud_run_job"] = job
	}
	if exec := os.Getenv("CLOUD_RUN_EXECUTION"); exec != "" {
		labels["cloud_run_execution"] = exec
	}
	if idx := os.Getenv("CLOUD_RUN_TASK_INDEX"); idx != "" {
		labels["cloud_run_task_index"] = idx
	}
	if cnt := os.Getenv("CLOUD_RUN_TASK_COUNT"); cnt != "" {
		labels["cloud_run_task_count"] = cnt
	}

	// Cloud Run Service context
	if svc := os.Getenv("K_SERVICE"); svc != "" {
		labels["k_service"] = svc
	}
	if rev := os.Getenv("K_REVISION"); rev != "" {
		labels["k_revision"] = rev
	}

	return &Logger{labels: labels}
}

func (l *Logger) log(severity, message string, data any) {
	entry := LogEntry{
		Severity:  severity,
		Message:   message,
		Timestamp: time.Now().UTC(),
		Data:      data,
	}

	if len(l.labels) > 0 {
		entry.Labels = l.labels
	}

	if err := json.NewEncoder(os.Stderr).Encode(&entry); err != nil {
		fmt.Fprintf(os.Stderr, "logx: failed to write log entry: %v\n", err)
	}
}

// Debug logs a DEBUG level message.
func (l *Logger) Debug(message string, data ...any) {
	l.log(SeverityDebug, message, l.toData(data))
}

// Info logs an INFO level message.
func (l *Logger) Info(message string, data ...any) {
	l.log(SeverityInfo, message, l.toData(data))
}

// Notice logs a NOTICE level message.
func (l *Logger) Notice(message string, data ...any) {
	l.log(SeverityNotice, message, l.toData(data))
}

// Warn logs a WARNING level message.
func (l *Logger) Warn(message string, data ...any) {
	l.log(SeverityWarning, message, l.toData(data))
}

// Error logs an ERROR level message.
func (l *Logger) Error(message string, data ...any) {
	l.log(SeverityError, message, l.toData(data))
}

// Critical logs a CRITICAL level message.
func (l *Logger) Critical(message string, data ...any) {
	l.log(SeverityCritical, message, l.toData(data))
}

// toData converts variadic key-value pairs to a map, or returns a single value directly.
func (l *Logger) toData(data []any) any {
	if len(data) == 0 {
		return nil
	}
	if len(data) == 1 {
		return data[0]
	}

	// Convert key-value pairs to map
	m := make(map[string]any)
	for i := 0; i < len(data)-1; i += 2 {
		key, ok := data[i].(string)
		if !ok {
			key = fmt.Sprintf("%v", data[i])
		}
		m[key] = data[i+1]
	}
	// Handle odd number of args
	if len(data)%2 != 0 {
		m["_extra"] = data[len(data)-1]
	}
	return m
}
