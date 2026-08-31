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

type Statement struct {
	IsAvailable  bool
	BalanceGB    int64
	IsSettleable bool
}

func NewStatement(planCode string, isEligible bool, balanceMB int64) Statement {
	gb := balanceMB / 1024
	return Statement{
		IsAvailable:  isEligible,
		BalanceGB:    gb,
		IsSettleable: gb > 0,
	}
}

func (l *Ledger) Summarize(line *Line, isEligible bool, balanceMB int64) Statement {
	return NewStatement("basic", isEligible, balanceMB)
}
