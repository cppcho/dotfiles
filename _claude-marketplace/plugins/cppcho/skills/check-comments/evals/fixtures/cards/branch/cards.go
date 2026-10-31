package cards

// Card is one block the screen draws under an answer.
type Card struct {
	Kind string
	Data any
}

type kind struct {
	name string
	// When the turn drew a card of this kind, only that card is written and every other kind is
	// dropped, wherever it sits in kinds.
	hidesOthers bool
}

// kinds is every card kind, in the order cards are written. When two kinds hide others, the one
// listed first wins.
var kinds = []kind{
	{name: "choices", hidesOthers: true},
	{name: "status"},
	{name: "estimate"},
}

// toWrite picks the cards a turn writes, in two passes:
//  1. for each kind in kinds order, the last card of that kind the turn drew;
//  2. if any of those is of a kind that hides others, the first such card alone; otherwise all
//     of them, in that order.
func toWrite(drawn []Card) []Card {
	type picked struct {
		kind kind
		card Card
	}
	var last []picked
	// Loop over every kind.
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
	// Return the cards.
	return out
}

// lastOf returns the last card of the named kind the turn drew. It walks drawn from the end and
// returns the first card whose kind matches, or false when there is none.
func lastOf(drawn []Card, name string) (Card, bool) {
	for i := len(drawn) - 1; i >= 0; i-- {
		if drawn[i].Kind == name {
			return drawn[i], true
		}
	}
	return Card{}, false
}
