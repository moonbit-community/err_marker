# core design

This page explains the model behind `err_marker` 0.1, how the marker line is
computed, and where that model is wrong. The 0.2.0 model that replaces it is
specified in [#5](https://github.com/moonbit-community/err_marker/issues/5).

## The model

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

## Where the model is wrong

The formulas measure length, but the reader sees columns. The two agree only
when every code unit takes exactly one terminal column. Each known bug is a
case where they disagree, or where the two sequence kinds disagree with each
other:

| Case | What happens | Issue |
| --- | --- | --- |
| Wide characters (CJK, emoji) | one character is 2 columns but 1 or 2 code units; the marker drifts left | [#6](https://github.com/moonbit-community/err_marker/issues/6) |
| Surrogate pairs | positions are code units, so a caller counting characters points at the wrong place; spans are widened to whole characters, so nothing is split | [#7](https://github.com/moonbit-community/err_marker/issues/7) |
| Tabs inside the span | a tab gets one marker character although it moves to the next tab stop; tabs before the span are copied into the padding and no longer shift the marker | [#8](https://github.com/moonbit-community/err_marker/issues/8) |

## The model in 0.2.0

0.2.0 measures columns instead of length, with these decisions (details and
the rejected alternatives are recorded in #5):

- **Positions.** Arrays use element indices; strings use Unicode scalar
  indices. Every span is snapped outward to extended grapheme cluster
  boundaries (UAX #29). Snapping is a closure operator on spans ordered by
  inclusion: if $\sigma$ snaps a span, then $S \subseteq \sigma(S)$,
  $S \subseteq T \Rightarrow \sigma(S) \subseteq \sigma(T)$ and
  $\sigma(\sigma(S)) = \sigma(S)$.
- **Columns.** Each grapheme cluster acts on the cursor $(\ell, c)$: an
  ordinary cluster of width $w$ maps $c \mapsto c + w$, a tab maps
  $c \mapsto t(\lfloor c/t \rfloor + 1)$, and a newline maps
  $(\ell, c) \mapsto (\ell + 1, 0)$. These moves form a monoid. Every
  composite is a shift, a tab move $c \mapsto T(c + a) + b$ with
  $0 \le a < t$, or a line break, because $T(T(x) + b) = T(x) + T(b)$. The
  marker column of a span is the move of its prefix applied to the origin.
- **Widths** come from tables generated from the Unicode Character Database
  (Unicode 18.0.0), with East Asian Width (UAX #11) for wide characters.
- **Several marks** overlay as a semilattice, so the output does not depend
  on the order in which marks are added.
- **Elements are quoted** when needed, so the rendered line can always be
  split back into its elements.
