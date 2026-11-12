# core design

This page states the contract that 0.2.0 renders by, after recording the 0.1
model it replaces and where that model went wrong. The decisions are tracked
in [#5](https://github.com/moonbit-community/err_marker/issues/5).

## The 0.1 model

A report has three lines: the rendered sequence $s$, a marker line, and the
message. The marker line is $p$ padding characters followed by $w$ marker
characters, so the whole design is the choice of $p$ (where the span starts)
and $w$ (how wide it is). The padding is a space for each of the first $p$
code units of $s$, except that a tab is copied as a tab, so the marker lines
up whatever tab width the terminal uses.

### Arrays

For elements $x_0, \dots, x_{n-1}$ rendered as strings $r_i = \texttt{to\_string}(x_i)$
and a separator of length $j$, the rendered text is

$$
s = r_0 \, \texttt{join} \, r_1 \, \texttt{join} \cdots \texttt{join} \, r_{n-1}.
$$

If $\texttt{to\_string}(x_i)$ is empty or contains whitespace, a double
quote or the separator, $r_i$ is that string wrapped in double quotes, with
`\` and `"` escaped by a backslash. This makes the rendering injective: $s$
can always be split back into $r_0, \dots, r_{n-1}$.

A span from element $a$ with offset $k$ covers elements $a$ to $a + k$, and

$$
p = \sum_{i < a} |r_i| + j\,a, \qquad
w = \sum_{i=a}^{a+k} |r_i| + j\,k,
$$

where $|r|$ is `String::length`, the number of UTF-16 code units. If $a < 0$,
nothing is drawn. A negative $k$ counts as $0$, and $a + k$ is clamped to
$n - 1$. If $a \ge n$, the mark is the point after the text: $p = |s|$ and
$w = 1$.

### Strings

For a string, the span from $a$ with offset $k$ covers code units $a$ to
$a + k$, so $p = a$ and $w = k + 1$. The same rules apply with $n = |s|$: $a + k$
is clamped to $n - 1$, and $a \ge n$ gives the point $p = n$, $w = 1$.
If the span would start or end between the two code units of a surrogate
pair, it is widened to include the whole pair, so a character is never split.

### Several lines

If $s$ contains line breaks, let $\ell$ be the offset where the line holding
the start of the span begins. The padding then covers code units $\ell$ to
$p - 1$ only, the marker line is printed right after that line, and $w$ stops
at the end of the line.

## Where the 0.1 model was wrong

The 0.1.4 release fixed tabs before the span, ranges, newlines, quoting and
split surrogate pairs within this model. What remained needs the contract
below, which 0.2.0 implements; `ErrorData::mark` now renders by it too. The
formulas measure length, but the reader sees columns. The two agree only
when every code unit takes exactly one terminal column. Each known bug is a
case where they disagree, or where the two sequence kinds disagree with each
other:

| Case | What happens | Issue |
| --- | --- | --- |
| Wide characters (CJK, emoji) | one character is 2 columns but 1 or 2 code units; the marker drifts left | [#6](https://github.com/moonbit-community/err_marker/issues/6) |
| Surrogate pairs | positions are code units, so a caller counting characters points at the wrong place; spans are widened to whole characters, so nothing is split | [#7](https://github.com/moonbit-community/err_marker/issues/7) |
| Tabs inside the span | a tab gets one marker character although it moves to the next tab stop; tabs before the span are copied into the padding and no longer shift the marker | [#8](https://github.com/moonbit-community/err_marker/issues/8) |

## The 0.2.0 contract

0.2.0 measures columns instead of length. This section is the contract that
the 0.2.0 code is written and tested against; the decisions and the rejected
alternatives are recorded in
[#5](https://github.com/moonbit-community/err_marker/issues/5).

### Coordinates

An array sequence has elements $x_0, \dots, x_{n-1}$ and positions
$0, \dots, n$. A string sequence is read as Unicode scalar values
$u_0, \dots, u_{m-1}$ and has positions $0, \dots, m$. A helper converts a
UTF-16 offset $o$ into the number of scalars before it; an offset inside a
surrogate pair counts that pair as not yet passed.

### Spans

A span is a half-open interval $[a, b)$ of positions with $0 \le a \le b$.
Constructors make every span valid: a negative end point becomes $0$, and
$b < a$ becomes $b = a$. A zero-width span $[p, p)$ is an insertion point.

Clamping to a sequence of length $n$ is the map

$$
\kappa_n([a, b)) = [\min(a, n), \min(b, n)).
$$

It is a retraction onto the spans inside the sequence: it is idempotent and
leaves every span inside the sequence unchanged. A span past the end becomes
the insertion point $[n, n)$.

### Snapping to grapheme clusters

Let $B \subseteq \{0, \dots, m\}$ be the extended grapheme cluster boundaries
of the rendered text (UAX #29); $0 \in B$ and $m \in B$. For a position $x$,
let $\lfloor x \rfloor_B$ be the greatest boundary $\le x$ and
$\lceil x \rceil_B$ the least boundary $\ge x$. Snapping is

$$
\sigma([a, b)) = [\lfloor a \rfloor_B, \lceil b \rceil_B).
$$

With $e$ the inclusion of $B$ into the positions, $\lfloor \cdot \rfloor_B$ is
right adjoint and $\lceil \cdot \rceil_B$ left adjoint to $e$:
$e(\beta) \le x \iff \beta \le \lfloor x \rfloor_B$ and
$\lceil x \rceil_B \le \beta \iff x \le e(\beta)$. Hence $\sigma$ is a closure
operator on spans ordered by inclusion:

$$
S \subseteq \sigma(S), \qquad
S \subseteq T \Rightarrow \sigma(S) \subseteq \sigma(T), \qquad
\sigma(\sigma(S)) = \sigma(S).
$$

A zero-width span strictly inside a cluster widens to that cluster. The three
laws are property tests.

### Order of operations

A mark on an array is first mapped to the text: element span $[i, j)$ becomes
the scalar span from the start of $r_i$ to the end of $r_{j-1}$, the hull of
the rendered elements. Every span is then clamped with $\kappa$ and snapped
with $\sigma$, in that order, and only then turned into columns.

### Columns

Each grapheme cluster $g$ acts on the cursor $(\ell, c)$:

$$
c \mapsto c + w(g), \qquad
c \mapsto t \left( \left\lfloor c / t \right\rfloor + 1 \right) \text{ for a tab}, \qquad
(\ell, c) \mapsto (\ell + 1, 0) \text{ for a line break},
$$

where $w(g)$ is the cluster width from the generated UCD 18.0.0 tables and
$t \ge 1$ is the tab width of the model, 8 by default. These moves form a
monoid under composition. Every composite has exactly one of three normal
forms: a shift $c \mapsto c + k$; a tab move $c \mapsto T(c + a) + b$ with
$0 \le a < t$, where $T(x) = t(\lfloor x/t \rfloor + 1)$; or a line break
$(\ell, c) \mapsto (\ell + n, k)$. The forms are closed under composition
because $T(T(x) + b) = T(x) + T(b)$. Laying out a text is a monoid
homomorphism from cluster sequences, and the column of a span is the move of
the text before it applied to $(0, 0)$.

### Rendering

- Array rendering is injective: an element is quoted exactly when its text
  is empty or contains whitespace, a double quote or the separator.
- Several marks overlay as a semilattice (commutative, associative,
  idempotent). Where marks overlap, the column goes to the higher priority,
  then the higher severity, then the later start, then the earlier end, then
  the primary mark, then the message that is smaller in code-point order.
- Message rows are assigned greedily by left endpoint, which uses the
  minimum number of rows: the largest number of messages that overlap at one
  column.

### Compact layout

`Report::render` draws the line that holds the primary mark (the primary
mark with the highest priority, then the earliest start), then the marker
row. The message of the mark whose marker ends rightmost follows the markers
on that row, which is always free to the right of them. The remaining
messages start under their marks, with the rows assigned as above. Marks
equal in every field are drawn once, so overlaying is idempotent as well as
commutative; the tests check every order of a set of four marks with ties at
each level of the tie-break.
