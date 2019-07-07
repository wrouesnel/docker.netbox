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
	"encoding/json"
	"os"
	"strings"
	"fmt"
)

var (
	frequency = kingpin.Flag("frequency", "Rate at which to refresh the file config").Default("30s").Duration()
	outputPaths = kingpin.Arg("output-file-def", "Path to the file to output Prometheus configurations to and an optional suffix for node names in the file").Strings()
	connectionString = kingpin.Flag("dsn", "DSN string for connecting to postgres").Default("user=postgres host=/var/run/postgresql/ sslmode=disable database=pdns").String()
)

type TargetGroup struct {
	Targets []string          `json:"targets"`
	Labels  map[string]string `json:"labels"`
}

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

	log.Debugln("Number of found peers:", len(nodes))

	for _, outputPathDef := range outputPaths {

		defParts := strings.SplitN(outputPathDef,"=", 2)
		outputPath := defParts[0]
		suffix := ""
		if len(defParts) > 1 {
			suffix = defParts[1]
		}

		tg := TargetGroup{
			Targets: []string{},
			Labels:  make(map[string]string, 0),
		}

		for _, nodeName := range nodes {
			tg.Targets = append(tg.Targets, fmt.Sprintf("%s%s", nodeName,suffix))
		}

		// Write the output file
		outputData, err := json.MarshalIndent([]TargetGroup{tg}, "", "  ")
		if err != nil {
			log.Errorln("Failed to marshal JSON for output")
			return
		}

		if err := ioutil.WriteAndSyncFile(outputPath, outputData, os.FileMode(0644)); err != nil {
			log.Errorln("Failed to write and sync output file:", outputPath, err)
			continue
		}
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


	log.Infoln("Starting promtargets poller")

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