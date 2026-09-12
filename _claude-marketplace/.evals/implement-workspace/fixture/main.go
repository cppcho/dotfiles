package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"itemsbrowser/internal/store"
)

const defaultLimit = 20

func main() {
	addr := flag.String("addr", ":8099", "listen address")
	flag.Parse()

	s := store.New([]store.Item{
		{Name: "alpha-queue", Service: "billing"},
		{Name: "beta-cache", Service: "billing"},
		{Name: "delta-worker", Service: "old-service"},
		{Name: "gamma-index", Service: "search"},
		{Name: "omega-ledger", Service: "billing"},
	})

	http.HandleFunc("/items", func(w http.ResponseWriter, r *http.Request) {
		limit := defaultLimit
		if raw := r.URL.Query().Get("limit"); raw != "" {
			n, err := strconv.Atoi(raw)
			if err != nil {
				http.Error(w, "limit must be a number", http.StatusBadRequest)
				return
			}
			limit = n
		}

		page := s.Page(limit)
		for _, it := range page.Items {
			fmt.Fprintf(w, "%s\t%s\n", it.Name, it.Service)
		}
		if page.Truncated() {
			fmt.Fprintf(w, "-- capped at %d --\n", page.Limit())
		}
	})

	log.Printf("listening on %s", *addr)
	log.Fatal(http.ListenAndServe(*addr, nil))
}
