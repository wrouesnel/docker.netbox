package main


import (
	"database/sql"

	"gopkg.in/alecthomas/kingpin.v2"

	_ "github.com/lib/pq"
	"github.com/prometheus/common/log"
	"time"
	"syscall"
	"os/signal"
	"github.com/coreos/etcd/pkg/ioutil"
	"os"
	"strings"
	"fmt"
	"sort"
	"os/exec"
)

var (
	frequency = kingpin.Flag("frequency", "Rate at which to refresh the file config").Default("30s").Duration()
	outputPaths = kingpin.Arg("output-file-def", "Path to the file to output AlertManager configuration environment").Strings()
	connectionString = kingpin.Flag("dsn", "DSN string for connecting to postgres").Default("user=postgres host=/var/run/postgresql/ sslmode=disable database=pdns").String()
	restartCommand = kingpin.Flag("restart-cmd", "Command to run when the list of peers changes").Default("sv restart alertmanager").String()
)

var (
	lastNodes []string
)

func scrapeTargets(dsn string, outputPaths []string) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Errorln("Failed to connect to local database:", err)
		return
	}
	defer db.Close()

	rows, err := db.Query("SELECT node_name, node_local_dsn FROM bdr.bdr_nodes;")
	if err != nil {
		log.Errorln("Failed to execute query:", err)
		return
	}

	nodes := []string{}

	for rows.Next() {
		var nodeName, nodeDsn string
		err := rows.Scan(&nodeName, &nodeDsn)
		if err != nil {
			log.Errorln("Failed to retrieve row:", err)
		}

		nodes = append(nodes, nodeName)
	}

	// Sort the output
	sort.Strings(nodes)

	// Check for any changes
	if len(lastNodes) == len(nodes) {
		matches := true
		for idx, _ := range lastNodes {
			if lastNodes[idx] != nodes[idx] {
				matches = false
			}
		}
		if matches {
			log.Debugln("No change in node peer lists. Taking no action.")
			return
		}
	}

	lastNodes = nodes

	log.Debugln("Number of found peers:", len(nodes))

	for _, outputPathDef := range outputPaths {
		defParts := strings.SplitN(outputPathDef,"=", 2)
		outputPath := defParts[0]
		suffix := ""
		if len(defParts) > 1 {
			suffix = defParts[1]
		}

		// Format the peer args
		peerArgs := []string{}
		for _, n := range nodes {
			peerArgs = append(peerArgs, fmt.Sprintf("--cluster.peer=%s%s", n, suffix))
		}

		fileContent := fmt.Sprintf("export CLUSTER_PEERS=\"%s\"\n", strings.Join(peerArgs, " "))

		if err := ioutil.WriteAndSyncFile(outputPath, []byte(fileContent), os.FileMode(0644)); err != nil {
			log.Errorln("Failed to write and sync output file:", outputPath, err)
			continue
		}
	}

	log.Debugln("Executing restart command")
	cmd := exec.Command("sh", "-c", *restartCommand)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		log.Errorln("Failed to execute restart command.")
	} else {
		log.Debugln("Executed command, got output:", stdoutStderr)
	}
}

func main() {
	log.AddFlags(kingpin.CommandLine)

	kingpin.Parse()

	done := make(chan struct{})
	sch := make(chan os.Signal,1)
	go func(){
		<- sch
		log.Infoln("Caught signal: shutting down.")
		close(done)
	}()
	signal.Notify(sch, syscall.SIGTERM)


	log.Infoln("Starting amquroum poller")

mainloop: for {
	log.Debugln("Scraping targets from database.")
	scrapeTargets(*connectionString,*outputPaths)
	log.Debugln("Scrape finished, waiting for next cycle.")

	select {
	case <- time.After(*frequency):
		log.Debugln("Timeout done, polling database again.")
	case <- done:
		log.Infoln("Shutting down by request.")
		break mainloop
	}
}

	log.Infoln("Exiting normally.")
	os.Exit(0)
}