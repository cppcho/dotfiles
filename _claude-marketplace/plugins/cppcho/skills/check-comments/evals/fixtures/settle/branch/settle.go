package settle

import "time"

type Status int

const (
	StatusActive Status = iota
	StatusSuspended
	StatusClosed
)

type CancellationKind int

const (
	CancellationNone CancellationKind = iota
	CancellationCompleted
	CancellationPortOut
)

type Cancellation struct {
	Kind CancellationKind
}

type Line struct {
	ID           string
	Status       Status
	CancelAt     time.Time
	Cancellation *Cancellation
}

type Entry struct {
	LineID   string
	AmountMB int64
}

type Ledger struct {
	buf []Entry
}

func (l *Ledger) Post(e Entry) {
	l.buf = append(l.buf, e)
}

// PendingEntries returns the entries posted since the last flush. The slice aliases the
// ledger's own buffer, so copy it before the next Post.
func (l *Ledger) PendingEntries() []Entry {
	return l.buf
}

// IsSettleable reports whether the line passes the same gate the settle RPCs apply through
// resolveActiveNonCancelledLine. A read path that has to render the state of a settle control
// calls this rather than that resolver, whose refusal is an error.
func IsSettleable(line *Line, now time.Time) bool {
	if line.Status != StatusActive {
		return false
	}
	if !line.CancelAt.IsZero() && now.After(line.CancelAt) {
		return false
	}
	if line.Cancellation != nil && line.Cancellation.Kind != CancellationNone {
		return false
	}
	return true
}

// withinGracePeriod reports whether now falls in the seven days after the cancel time, the
// window in which a closed line still accepts a settlement.
func withinGracePeriod(line *Line, now time.Time) bool {
	if line.CancelAt.IsZero() {
		return false
	}
	return now.Before(line.CancelAt.AddDate(0, 0, 7))
}

type Statement struct {
	IsAvailable  bool
	BalanceGB    int64
	IsSettleable bool
}

// NewStatement builds the statement rendered for one line.
//
// canSettle is whether a settlement would be accepted on the line at all; false leaves
// IsSettleable false whatever the line holds. A line out of service or on its way out still
// shows its balance on the home screen, with nothing to settle, rather than offering the user
// a settle button that fails when they tap it.
func NewStatement(planCode string, isEligible, canSettle bool, balanceMB int64) Statement {
	gb := balanceMB / 1024
	return Statement{
		IsAvailable:  isEligible,
		BalanceGB:    gb,
		IsSettleable: canSettle && gb > 0,
	}
}

func (l *Ledger) Summarize(line *Line, isEligible bool, balanceMB int64, now time.Time) Statement {
	// The grace period is read here rather than inside IsSettleable so a line closed hours ago
	// still settles; IsSettleable answers the steady state and knows nothing about the window.
	canSettle := IsSettleable(line, now) || withinGracePeriod(line, now)
	return NewStatement("basic", isEligible, canSettle, balanceMB)
}
