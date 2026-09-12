package store

import "testing"

func fixture() *Store {
	return New([]Item{
		{Name: "alpha-queue", Service: "billing"},
		{Name: "beta-cache", Service: "billing"},
		{Name: "delta-worker", Service: "old-service"},
		{Name: "gamma-index", Service: "search"},
		{Name: "omega-ledger", Service: "billing"},
	})
}

func TestPageSortsByName(t *testing.T) {
	got := fixture().Page(0)
	if got.Items[0].Name != "alpha-queue" {
		t.Fatalf("first item = %q, want alpha-queue", got.Items[0].Name)
	}
	if got.Items[4].Name != "omega-ledger" {
		t.Fatalf("last item = %q, want omega-ledger", got.Items[4].Name)
	}
}

func TestPageCapsAtLimit(t *testing.T) {
	got := fixture().Page(2)
	if len(got.Items) != 2 {
		t.Fatalf("len(items) = %d, want 2", len(got.Items))
	}
	if !got.Truncated() {
		t.Fatal("Truncated() = false, want true when the cap withheld items")
	}
}

func TestPageNotTruncatedWithoutCap(t *testing.T) {
	got := fixture().Page(0)
	if got.Truncated() {
		t.Fatal("Truncated() = true, want false when nothing was withheld")
	}
}
