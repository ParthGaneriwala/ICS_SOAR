# PRISM–Soar Cybersickness Cognitive Agent

This branch contains a translation of a PRISM DTMC (Discrete-Time Markov Chain) model of cybersickness into a modular Soar cognitive architecture. It simulates how users with different demographics (e.g., gender) experience cybersickness in VR/AR environments based on headset-induced sensory effects.

---

## Overview

In the original PRISM model, cybersickness is represented as a probabilistic state machine (user's SSQ: low → medium → high), influenced by:
- **Gender susceptibility** (via a gender_factor)
- **Headset properties** (optic flow and latency) affecting sickness likelihood
- **Stochastic transitions** between SSQ states based on headset severity

This branch translates those stochastic transitions into **Soar production rules** using:
- **Numeric preferences** with log-probabilities
- **Softmax-based decision making** via Soar's indifference resolution

## Soar Concepts Used

- **Operators** represent user transitions between SSQ states (e.g., low → medium).
- **Numeric preferences** simulate PRISM probabilities (e.g., log(0.9), log(0.1)).
- **Indifference resolution** allows Soar to choose stochastically between actions.
- **Working memory** stores headset state, gender, and precomputed probabilities.

---

## How PRISM Is Represented in Soar

| PRISM Concept            | Soar Equivalent                        |
|--------------------------|----------------------------------------|
| `module user`            | `^ssq`, `^gender` in working memory    |
| Probabilistic transition | Competing Soar operators w/ log-prefs  |
| `l2mprob`, etc.          | `^log-l2mprob`, `^log-stay-low`, etc.  |
| Headset `h` influence    | `^headset.h`, categorized in rules     |

---
