package store

import "sort"

// Item is one row in the browser.
type Item struct {
	Name    string
	Service string
}

// Page is a window onto the store's items, ready to render.
type Page struct {
	Items []Item
	total int
	limit int
}

// Store holds the items in memory, in insertion order.
type Store struct {
	items []Item
}

func New(items []Item) *Store {
	return &Store{items: items}
}

// Page returns at most limit items, sorted by name. A limit of zero or less
// means no cap.
func (s *Store) Page(limit int) Page {
	out := make([]Item, len(s.items))
	copy(out, s.items)
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })

	if limit > 0 && len(out) > limit {
		out = out[:limit]
	}
	return Page{Items: out, total: len(s.items), limit: limit}
}

// Truncated reports whether the cap withheld any items from the page.
func (p Page) Truncated() bool {
	return len(p.Items) < p.total
}

// Limit is the cap this page was built with.
func (p Page) Limit() int {
	return p.limit
}
