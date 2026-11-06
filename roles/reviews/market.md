# Review: market

Competitors, prices and positioning, and where the project stands.

Assumes BASE.md and REVIEWER.md, loaded with it by `/bot review`. Analyzes
the market around the project: who else solves the problem, how, for whom,
at what price, and where the project stands. Market facts age fast; the
report is a picture of its date.

## Method
1. **Frame the question** with the user's words: the segment, the
   audience, and what the analysis must decide (positioning, pricing, a
   feature, whether to go on).
2. **Search outside without exposing the project.** Queries name the
   segment, the problem and the competitors, never the project's internal
   material — unpublished names, designs, code, figures. If the question
   cannot be searched without it, stop and ask.
3. **Map the competitors:** direct (same problem, same audience), indirect
   (same problem, another approach) and substitutes (what people do
   instead). For each: offer, audience, price, distribution, strengths and
   weaknesses, with the source.
4. **Every claim has a source and a date** (REVIEWER §2, rule 9). Fact,
   inference and opinion are kept apart; a figure without a source does not
   enter.
5. **Place the project** against the map from its own documents
   (`README.md`, `DESIGN.md`, `BACKLOG.md`): the gaps it fills, the ones it
   does not, and the risks.
6. **Answer the question** of step 1, with the recommendation and what
   would change it.

## Template

````markdown
# <Subject> — market, YYYY-MM-DD

**Analyst:** <model> · **Question:** <step 1, in the user's words>
**Earlier round:** <path, if any>

## 1. Segment and audience

## 2. Competitors
| Name | Kind (direct / indirect / substitute) | Offer | Audience | Price | Source, date read |
|---|---|---|---|---|---|

## 3. Findings
### 3.n <title>
- **Fact:** <with source and date>
- **Inference:** <what it suggests, marked as inference>

## 4. Where the project stands
| Gap or strength | Evidence in the project (`file:line`) | Risk |
|---|---|---|

## 5. Answer
<the recommendation, and what would change it>

## Sources
- <URL or document> — read YYYY-MM-DD
````
