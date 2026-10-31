package cards

type Card struct {
	Kind string
	Data any
}

type kind struct {
	name        string
	hidesOthers bool
}

var kinds = []kind{
	{name: "choices", hidesOthers: true},
	{name: "status"},
	{name: "estimate"},
}

func toWrite(drawn []Card) []Card {
	type picked struct {
		kind kind
		card Card
	}
	var last []picked
	for _, k := range kinds {
		if card, ok := lastOf(drawn, k.name); ok {
			last = append(last, picked{kind: k, card: card})
		}
	}
	for _, p := range last {
		if p.kind.hidesOthers {
			return []Card{p.card}
		}
	}
	out := make([]Card, 0, len(last))
	for _, p := range last {
		out = append(out, p.card)
	}
	return out
}

func lastOf(drawn []Card, name string) (Card, bool) {
	for i := len(drawn) - 1; i >= 0; i-- {
		if drawn[i].Kind == name {
			return drawn[i], true
		}
	}
	return Card{}, false
}
