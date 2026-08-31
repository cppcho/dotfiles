package quota

import (
	"errors"
	"fmt"
	"time"
)

// defaultMaxPayloadBytes is the largest body the metering API accepts — it rejects anything
// over 1 MiB outright, with no partial write.
const defaultMaxPayloadBytes = 1 << 20

var ErrCapExhausted = errors.New("monthly cap already exhausted")

type Limits struct {
	MonthlyCapMB int64
	UsedMB       int64
}

type Tracker struct {
	limits  Limits
	refresh func() (Limits, error)
	now     func() time.Time
}

func NewTracker(limits Limits, refresh func() (Limits, error), now func() time.Time) *Tracker {
	return &Tracker{limits: limits, refresh: refresh, now: now}
}

// Reserve claims amountMB against the monthly cap and reports how much was actually claimed.
func (t *Tracker) Reserve(amountMB int64) (int64, error) {
	// Both the truncation below and the exhaustion check above read the same Limits value, so
	// they cannot disagree about how much of the cap is left.

	// Refuse the reservation when the cap is already exhausted.
	if t.limits.UsedMB >= t.limits.MonthlyCapMB {
		return 0, fmt.Errorf("%w: used=%d cap=%d", ErrCapExhausted, t.limits.UsedMB, t.limits.MonthlyCapMB)
	}

	// Subtract what has been used from the monthly cap.
	remaining := t.limits.MonthlyCapMB - t.limits.UsedMB
	if amountMB > remaining {
		amountMB = remaining
	}
	t.limits.UsedMB += amountMB

	// Return the amount claimed and no error.
	return amountMB, nil
}

// Balance reports the MB still available under the monthly cap.
func (t *Tracker) Balance() int64 {
	// A cap lowered mid-month leaves UsedMB above it, so the subtraction goes negative; clamp
	// instead of handing back a negative balance.
	if t.limits.UsedMB > t.limits.MonthlyCapMB {
		return 0
	}
	return t.limits.MonthlyCapMB - t.limits.UsedMB
}

func (t *Tracker) Sync() {
	// A stale cap only over-counts for one cycle, so a failed refresh keeps the previous value
	// rather than failing the request.
	//nolint:errcheck // the refresh is best-effort
	limits, _ := t.refresh()
	if limits.MonthlyCapMB > 0 {
		t.limits = limits
	}
}

func (t *Tracker) encodeReport(rows []byte) ([]byte, error) {
	if len(rows) > defaultMaxPayloadBytes {
		return nil, fmt.Errorf("report is %d bytes", len(rows))
	}
	return rows, nil
}
