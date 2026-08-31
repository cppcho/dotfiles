package quota

import (
	"errors"
	"fmt"
	"time"
)

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

func (t *Tracker) Reserve(amountMB int64) (int64, error) {
	if t.limits.UsedMB >= t.limits.MonthlyCapMB {
		return 0, fmt.Errorf("%w: used=%d cap=%d", ErrCapExhausted, t.limits.UsedMB, t.limits.MonthlyCapMB)
	}

	remaining := t.limits.MonthlyCapMB - t.limits.UsedMB
	if amountMB > remaining {
		amountMB = remaining
	}
	t.limits.UsedMB += amountMB

	return amountMB, nil
}

func (t *Tracker) Balance() int64 {
	if t.limits.UsedMB > t.limits.MonthlyCapMB {
		return 0
	}
	return t.limits.MonthlyCapMB - t.limits.UsedMB
}

func (t *Tracker) Sync() {
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
