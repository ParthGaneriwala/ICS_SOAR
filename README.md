# ICS_SOAR — Cybersickness Monitoring Agent

A Soar agent that models an operator running a scan-and-select mission in VR while
cybersickness accumulates. The agent alternates between two jobs: stepping through
the mission task cycle, and — on a fixed cadence — stopping to check whether it has
become sick.

The agent does not run standalone. It is sourced by a JSoar host,
[`CheckCybersicknessAgent.java`](git: ICS_MATRICS-version-2) ,
which owns all the numbers: it reads the empirical probability tables, samples the
task durations, keeps the mission clock, and pushes everything onto the input-link.
Soar contributes the control flow and the decisions; it computes no probabilities of
its own.

<!-- > **Note on history.** Earlier versions of this agent translated a PRISM DTMC of SSQ
> state transitions into competing operators with log-probability numeric preferences,
> resolved by Soar's indifference selection. None of that remains. Sickness is now a
> single threshold test against measured study data, and no rule in this directory
> uses a numeric preference. The `^ssq`, `^gender`, and `^headset` structures the old
> README described do not exist. -->

---

## The two monitors

The agent is one state whose `^name` alternates. There is no substate; switching is
just a retract-and-assert of `^name`.

```
  mission-monitor                          sickness-monitor
  ---------------                          ----------------
  Scan-and-Select
        |  + pdf2      IL ^check-sickness yes
        v            ------------------------->   pdf1 >= sick-thres  -> sick
     Deciding                                     pdf1 <  sick-thres  -> not-sick
        |  + pdf3                                         |
        v            <-------------------------           v
     Decided           IL ^check-done yes         sets ^sick and ^sickness-checked,
        |                                         latches OL ^check-done yes
        `--> Scan-and-Select   (no time added)
```

### mission-monitor — the task cycle

Defined in [`mission/task-propose.soar`](mission/task-propose.soar) and
[`mission/operators/task-apply.soar`](mission/operators/task-apply.soar).

`^action` encodes the task phase: `0`/`3` = Scan-and-Select, `1` = Deciding,
`2` = Decided. Each transition advances the phase and, for the two that consume
time, adds a sampled duration to `^time-counter`:

| operator | from → to | time added | output-link `^event` |
|---|---|---|---|
| `apply-SS-transition` | Scan-and-Select → Deciding | `+ pdf2` | `Deciding` |
| `apply-D-transition` | Deciding → Decided | `+ pdf3` | `Decided` |
| `apply-DD-transition` | Decided → Scan-and-Select | none | `Scan-and-Select` |

`^time-counter` is the mission clock. It is echoed to the output-link as
`^current-time`, which the host parses back out to drive its own scheduling — so the
clock advances at the pace of the sampled durations, not wall-clock time. The cycle
runs while `^time-counter < ^total-time`, and mission progress is the ratio of the
two.

**The two are not obviously in the same units.** `^total-time` is `1200`, while
`pdf2`/`pdf3` are fitted to the study's per-event durations in minutes and add roughly
4 per full task cycle — so a mission runs about 300 cycles, and reads as 1200 minutes
rather than the 20 minutes 1200 seconds would suggest. Nothing downstream breaks,
because every consumer uses the ratio rather than the absolute value, but it is worth
settling which unit was intended before anyone reads a wall-clock number off
`^current-time`.

Two elaborations gate the loop: `top-state*elaborate*startmission` latches
`^start-mission yes` once the host reports the operator pressed start, and
`top-state*elaborate*sickness-time-interval` latches the check cadence. No transition
proposes until both are set.

### sickness-monitor — the check

Defined in [`sickness/sickness-propose.soar`](sickness/sickness-propose.soar) and
[`sickness/operators/sickness-apply.soar`](sickness/operators/sickness-apply.soar).

When the host raises `^check-sickness yes` (a check is due) and `^check-done no`,
`propose*check*transition` fires with a best (`>`) preference and flips `^name` to
`sickness-monitor`. There, exactly one of two proposals matches:

```
(<sd> ^sick-thres <st>
      ^pdf1 >= <st>)   ->  apply-sick      ; ^sick 1, OL ^sick sick
(<sd> ^sick-thres <st>
      ^pdf1 <  <st>)   ->  apply-notsick   ; ^sick 0, OL ^sick not-sick
```

The apply rule also sets `^sickness-checked yes` and latches output-link
`^check-done yes`. That latch is the agent's "done" signal; the host sees it, pulses
input-link `^check-done yes` for exactly one cycle, and that pulse lets
`apply*check*cybersickness` switch back to `mission-monitor` and reset
`^sickness-checked` to `no`, arming the next check.

**The `>=` / `<` split is deliberate and load-bearing.** The two tests must partition
every case. An earlier `<` / `>` pair matched neither rule when `pdf1` landed exactly
on the threshold, and because [`settings.soar`](settings.soar) sets `waitsnc --on`,
that stalled the agent silently instead of raising a state-no-change impasse. Exact
ties are the common case here, not a corner: the probabilities are k/32 (S1) and
k/38 (S3), and the threshold is a midpoint of two of them, so for S1 level 4 the tie
falls on intervals 26–27 — precisely where onset should happen.

---

## The IO contract

Everything the agent knows about the world arrives under
`^io.input-link.systemdata`, refreshed by the host every 200 ms.

| input-link attribute | type | meaning |
|---|---|---|
| `sys-start-mission` | double | `1` once the operator starts the mission |
| `pdf1` | double | P(the operator has reached the selected FMS level) at the current mission time |
| `sick-thres` | double | the threshold `pdf1` is compared against — the selected level's `ProbThreshold` |
| `pdf2` | double | sampled Scan-and-Select duration, minutes |
| `pdf3` | double | sampled Deciding duration, minutes |
| `time-interval` | double | sickness-check cadence: 2, 5, or 10 minutes |
| `check-sickness` | string | `yes` when a check is due |
| `check-done` | string | one-cycle `yes` pulse releasing the sickness monitor |

| output-link attribute | meaning |
|---|---|
| `sick` | `sick` / `not-sick` |
| `event` | `Scan-and-Select` / `Deciding` / `Decided` |
| `current-time` | mission clock, echoed from `^time-counter` |
| `total-time` | mission length |
| `check-done` | latched `yes` once a check has been applied |

`pdf2` and `pdf3` are *samples*, redrawn each cycle from distributions fitted to the
ISU study (Burr XII for scanning, GEV for deciding), each with a time-varying trend
that shortens durations as the mission progresses. `pdf1` and `sick-thres` are
*lookups*, not samples — see below.

---

## How sickness is decided

Both `pdf1` and `sick-thres` come from `results/prob_with_thres_*.json`, indexed by
latency condition (S1 = low, S3 = high) and by the FMS sickness level 0–10 the
operator selects in the UI.

- **`pdf1`** is the measured proportion of participants who had reached that FMS level
  during each of 40 one-minute intervals. The host maps those 40 intervals onto
  normalized mission time, so the curve stretches to whatever `^total-time` is set to,
  and reads the containing interval — a step lookup, not interpolated, because each
  entry is a measured proportion rather than a sample of a continuous curve. Every
  curve in the table is monotone non-decreasing, so once the agent turns sick it stays
  sick.
- **`sick-thres`** is that level's `ProbThreshold` field, which the table defines as
  `(max + min) / 2` of the level's own curve — its half-height. The agent therefore
  turns sick at the moment the curve reaches half its total rise, i.e. that level's
  median onset time.

`sick-thres` replaced a fixed `^sick_thres 0.5` that used to be asserted on the state
in [`operators/initialize.soar`](operators/initialize.soar). That constant asked "are
more than half of all participants sick by now" — a question about the population, not
about this agent, and one that no FMS level above 4 could ever answer yes to, because
those curves never reach 0.5. The threshold now lives on the input-link rather than the
state so that changing the level in the UI mid-mission re-targets the comparison at
once, instead of leaving a stale copy in working memory.

<!-- ### Consequences

Onset is **deterministic**. The same condition and level turn sick in the same interval
on every run; there is no run-to-run variance and no sampling. Onset is given below as
the interval index (of 40) and the share of the mission elapsed, which is how the
lookup actually works — the 40 intervals are stretched across whatever `^total-time`
holds, so these positions are the same at any mission length:

| FMS level | S1 threshold | S1 onset | S3 threshold | S3 onset |
|---|---|---|---|---|
| 1 | 0.4844 | interval 7 (17.5%) | 0.4474 | interval 8 (20.0%) |
| 2 | 0.3438 | interval 12 (30.0%) | 0.3816 | interval 17 (42.5%) |
| 3 | 0.3438 | interval 23 (57.5%) | 0.2632 | interval 18 (45.0%) |
| 4 | 0.25 | interval 26 (65.0%) | 0.1579 | interval 15 (37.5%) |
| 5 | 0.1719 | interval 28 (70.0%) | 0.0921 | interval 18 (45.0%) |
| 6 | 0.0938 | interval 35 (87.5%) | 0.0790 | interval 27 (67.5%) |
| 7 | 0.0625 | interval 35 (87.5%) | 0.0658 | interval 22 (55.0%) |
| 8 | 0.0312 | **interval 14 (35.0%)** | 0.0263 | interval 13 (32.5%) |
| 9 | 0.0156 | interval 18 (45.0%) | 0.0263 | interval 13 (32.5%) |
| 10 | 0.0156 | interval 23 (57.5%) | 0.0263 | interval 14 (35.0%) |

Every run eventually turns sick, since `ProbThreshold` never exceeds its curve's
maximum. Level 0 is degenerate: threshold 1 against a curve that is 1 from the first
interval, so the agent is sick at the first check.

### Known artifact

**Onset time is not monotone in severity.** In S1, level 8 turns sick 35% into the
mission but level 4 not until 65% — a more severe symptom arriving *earlier*. The cause
is that `ProbThreshold` is each level's *own* half-height, so a level only 2 of 32
participants ever reached has a threshold of 0.0312, which the first small bump in its
curve clears immediately. S3 levels 8–10 collapse the same way, all landing around a
third of the way in.

A single global threshold applied across levels (a fixed quantile rather than a
per-level half-height) would restore the ordering, because the higher levels' curves
sit strictly below the lower ones. That change has not been made.

--- -->

## File layout

```
load.soar                          sources everything, in order
settings.soar                      waitsnc --on
top-level.soar                     proposes initialize
operators/
  load.soar
  initialize.soar                  asserts the starting state and output-link
mission/
  load.soar
  task-propose.soar                start/interval elaborations, 3 task transitions,
                                   switch to sickness-monitor
  operators/
    load.soar
    task-apply.soar                applies the transitions, advances ^time-counter
sickness/
  load.soar
  sickness-propose.soar            sick / not-sick proposals, switch back
  operators/
    load.soar
    sickness-apply.soar            applies the verdict, latches ^check-done
```

Initial state, from `operators/initialize.soar`:

```
^name mission-monitor      ^action 3                 ^sick 0
^start-mission no          ^time-counter 1           ^total-time 1200
^sickness-checked no       ^sickness-time-interval-set no
```

<!-- ## Running it

Launch `StartAgent` in `ICS_MATRICS-version-2`; the JSoar host sources `load.soar`
and opens the UI, where the operator picks the latency condition, the FMS level to
monitor, and the check interval, then starts the mission.

Two absolute paths are hardcoded in `CheckCybersicknessAgent.java` and need to match
your checkout — `pathToSoar` (this directory's `load.soar`) and `PROB_JSON_PATH` (the
`prob_with_thres_*.json` table).

`TIME_SCALE_DENOM` scales the mission clock when the host schedules checks. It is
currently `1.0`; the in-source comment documents `60.0` as real-time (60 seconds to a
minute) and smaller values such as `2.0` or `5.0` as speed-ups for debugging. -->
