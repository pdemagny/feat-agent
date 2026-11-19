# Contract: the `--weights` file

A JSON object. Every section and every key is optional; what is given
replaces the default, the rest stays.

```json
{
  "tokens": {
    "input": 1,
    "cache_read": 0.1,
    "output": 5,
    "cache_write_1h": 2,
    "cache_write_5m": 1.25
  },
  "models": {
    "haiku": 1,
    "sonnet": 3,
    "opus": 5,
    "claude-opus-5-5": 5
  },
  "prices": {
    "opus": 5.0,
    "sonnet": 3.0,
    "haiku": 1.0
  }
}
```

| Section | Keys | Value |
| --- | --- | --- |
| `tokens` | exactly `input`, `cache_read`, `output`, `cache_write_1h`, `cache_write_5m` | number ≥ 0: cost units per token of that kind |
| `models` | a model id (`claude-opus-5-5`) or a part of one (`opus`) | number ≥ 0: multiplier for that model |
| `prices` | same keys as `models` | number ≥ 0: USD per million **input** tokens of that model |

Rules:

- Model lookup, for `models` and `prices` alike: a key equal to the model id
  wins; else a key equal to one of the id's `-`-separated parts; else the
  highest value in that section, and the model is named in the report
  (`unweighted models:` / `unpriced models:`).
- Cost units of a call = Σ tokens of each kind × `tokens` weight, × the
  model's `models` weight.
- USD of a call = Σ tokens of each kind × `tokens` weight × the model's
  price / 1,000,000. So with the default token weights, output costs five
  times the input price and a cache read a tenth of it.
- No `prices` section, or an empty one: no money anywhere in the output.
- A valid value is an integer or a decimal number, finite and ≥ 0. `true`
  and `false` are not numbers here; `NaN`, `Infinity` and `-Infinity`
  (which Python's `json` accepts by default) are refused while parsing, and
  a literal too large to be finite (`1e400`) is refused too.
- Errors (stderr, exit 2): file not readable, not JSON, not an object, an
  unknown section or `tokens` key, a section that is not an object, a value
  that is not valid as above. The message names the section and key, never
  the file's other content.

The script carries no price table (brief: "Money only from prices the user
supplies").
