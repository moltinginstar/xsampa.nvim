local M = {}

local function utf8_char_width(byte)
  if not byte then
    return 0
  end
  if byte < 0x80 then
    return 1
  end
  if byte < 0xE0 then
    return 2
  end
  if byte < 0xF0 then
    return 3
  end
  if byte < 0xF8 then
    return 4
  end
  return 1
end

local function utf8_len(text)
  local count = 0
  local index = 1

  while index <= #text do
    local width = utf8_char_width(text:byte(index))
    index = index + width
    count = count + 1
  end

  return count
end

local function next_utf8(text, index)
  local width = utf8_char_width(text:byte(index))
  return text:sub(index, index + width - 1), width
end

local function clone_spec(spec)
  local copy = {}
  for key, value in pairs(spec) do
    copy[key] = value
  end
  return copy
end

local function push_spec(specs, xsampa, ipa, kind, label, opts)
  local spec = opts and clone_spec(opts) or {}
  spec.xsampa = xsampa
  spec.ipa = ipa
  spec.kind = kind
  spec.label = label
  specs[#specs + 1] = spec
end

local function push_alias(specs, xsampa, ipa, canonical, kind, label, opts)
  local spec = opts and clone_spec(opts) or {}
  spec.alias_of = canonical
  push_spec(specs, xsampa, ipa, kind, label, spec)
end

local function push_identity(specs, symbols, kind)
  for _, symbol in ipairs(symbols) do
    push_spec(specs, symbol, symbol, kind, symbol)
  end
end

local DEFAULT_SPECS = {}

push_identity(DEFAULT_SPECS, { "a", "e", "i", "o", "u", "y" }, "vowel")
push_identity(DEFAULT_SPECS, {
  "b",
  "c",
  "d",
  "f",
  "g",
  "h",
  "j",
  "k",
  "l",
  "m",
  "n",
  "p",
  "q",
  "r",
  "s",
  "t",
  "v",
  "w",
  "x",
  "z",
}, "consonant")

push_spec(DEFAULT_SPECS, "b_<", "ɓ", "consonant", "voiced bilabial implosive")
push_spec(DEFAULT_SPECS, "d`", "ɖ", "consonant", "voiced retroflex plosive")
push_spec(DEFAULT_SPECS, "d_<", "ɗ", "consonant", "voiced alveolar implosive")
push_spec(DEFAULT_SPECS, "g_<", "ɠ", "consonant", "voiced velar implosive")
push_spec(DEFAULT_SPECS, "h\\", "ɦ", "consonant", "voiced glottal fricative")
push_spec(DEFAULT_SPECS, "j\\", "ʝ", "consonant", "voiced palatal fricative")
push_spec(DEFAULT_SPECS, "l`", "ɭ", "consonant", "retroflex lateral approximant")
push_spec(DEFAULT_SPECS, "l\\", "ɺ", "consonant", "alveolar lateral flap")
push_spec(DEFAULT_SPECS, "n`", "ɳ", "consonant", "retroflex nasal")
push_spec(DEFAULT_SPECS, "p\\", "ɸ", "consonant", "voiceless bilabial fricative")
push_spec(DEFAULT_SPECS, "r`", "ɽ", "consonant", "retroflex flap")
push_spec(DEFAULT_SPECS, "r\\", "ɹ", "consonant", "alveolar approximant")
push_spec(DEFAULT_SPECS, "r\\`", "ɻ", "consonant", "retroflex approximant")
push_spec(DEFAULT_SPECS, "s`", "ʂ", "consonant", "voiceless retroflex fricative")
push_spec(DEFAULT_SPECS, "s\\", "ɕ", "consonant", "voiceless alveolo-palatal fricative")
push_spec(DEFAULT_SPECS, "t`", "ʈ", "consonant", "voiceless retroflex plosive")
push_spec(DEFAULT_SPECS, "v\\", "ʋ", "consonant", "labiodental approximant")
push_alias(DEFAULT_SPECS, "P", "ʋ", "v\\", "consonant", "labiodental approximant")
push_spec(DEFAULT_SPECS, "x\\", "ɧ", "consonant", "voiceless palatal-velar fricative")
push_spec(DEFAULT_SPECS, "z`", "ʐ", "consonant", "voiced retroflex fricative")
push_spec(DEFAULT_SPECS, "z\\", "ʑ", "consonant", "voiced alveolo-palatal fricative")

push_spec(DEFAULT_SPECS, "A", "ɑ", "vowel", "open back unrounded vowel")
push_spec(DEFAULT_SPECS, "B", "β", "consonant", "voiced bilabial fricative")
push_spec(DEFAULT_SPECS, "B\\", "ʙ", "consonant", "bilabial trill")
push_spec(DEFAULT_SPECS, "C", "ç", "consonant", "voiceless palatal fricative")
push_spec(DEFAULT_SPECS, "D", "ð", "consonant", "voiced dental fricative")
push_spec(DEFAULT_SPECS, "E", "ɛ", "vowel", "open-mid front unrounded vowel")
push_spec(DEFAULT_SPECS, "F", "ɱ", "consonant", "labiodental nasal")
push_spec(DEFAULT_SPECS, "G", "ɣ", "consonant", "voiced velar fricative")
push_spec(DEFAULT_SPECS, "G\\", "ɢ", "consonant", "voiced uvular plosive")
push_spec(DEFAULT_SPECS, "G\\_<", "ʛ", "consonant", "voiced uvular implosive")
push_spec(DEFAULT_SPECS, "H", "ɥ", "consonant", "labial-palatal approximant")
push_spec(DEFAULT_SPECS, "H\\", "ʜ", "consonant", "voiceless epiglottal fricative")
push_spec(DEFAULT_SPECS, "I", "ɪ", "vowel", "near-close front unrounded vowel")
push_spec(DEFAULT_SPECS, "I\\", "ᵻ", "vowel", "near-close central unrounded vowel")
push_spec(DEFAULT_SPECS, "J", "ɲ", "consonant", "palatal nasal")
push_spec(DEFAULT_SPECS, "J\\", "ɟ", "consonant", "voiced palatal plosive")
push_spec(DEFAULT_SPECS, "J\\_<", "ʄ", "consonant", "voiced palatal implosive")
push_spec(DEFAULT_SPECS, "K", "ɬ", "consonant", "voiceless alveolar lateral fricative")
push_spec(DEFAULT_SPECS, "K\\", "ɮ", "consonant", "voiced alveolar lateral fricative")
push_spec(DEFAULT_SPECS, "L", "ʎ", "consonant", "palatal lateral approximant")
push_spec(DEFAULT_SPECS, "L\\", "ʟ", "consonant", "velar lateral approximant")
push_spec(DEFAULT_SPECS, "M", "ɯ", "vowel", "close back unrounded vowel")
push_spec(DEFAULT_SPECS, "M\\", "ɰ", "consonant", "velar approximant")
push_spec(DEFAULT_SPECS, "N", "ŋ", "consonant", "velar nasal")
push_spec(DEFAULT_SPECS, "N\\", "ɴ", "consonant", "uvular nasal")
push_spec(DEFAULT_SPECS, "O", "ɔ", "vowel", "open-mid back rounded vowel")
push_spec(DEFAULT_SPECS, "O\\", "ʘ", "consonant", "bilabial click")
push_spec(DEFAULT_SPECS, "Q", "ɒ", "vowel", "open back rounded vowel")
push_spec(DEFAULT_SPECS, "R", "ʁ", "consonant", "voiced uvular fricative")
push_spec(DEFAULT_SPECS, "R\\", "ʀ", "consonant", "uvular trill")
push_spec(DEFAULT_SPECS, "S", "ʃ", "consonant", "voiceless postalveolar fricative")
push_spec(DEFAULT_SPECS, "T", "θ", "consonant", "voiceless dental fricative")
push_spec(DEFAULT_SPECS, "U", "ʊ", "vowel", "near-close back rounded vowel")
push_spec(DEFAULT_SPECS, "U\\", "ᵿ", "vowel", "near-close central rounded vowel")
push_spec(DEFAULT_SPECS, "V", "ʌ", "vowel", "open-mid back unrounded vowel")
push_spec(DEFAULT_SPECS, "W", "ʍ", "consonant", "voiceless labial-velar fricative")
push_spec(DEFAULT_SPECS, "X", "χ", "consonant", "voiceless uvular fricative")
push_spec(DEFAULT_SPECS, "X\\", "ħ", "consonant", "voiceless pharyngeal fricative")
push_spec(DEFAULT_SPECS, "Y", "ʏ", "vowel", "near-close front rounded vowel")
push_spec(DEFAULT_SPECS, "Z", "ʒ", "consonant", "voiced postalveolar fricative")

push_spec(DEFAULT_SPECS, ".", ".", "separator", "syllable break")
push_spec(DEFAULT_SPECS, '"', "ˈ", "stress", "primary stress")
push_spec(DEFAULT_SPECS, "%", "ˌ", "stress", "secondary stress")
push_spec(DEFAULT_SPECS, "'", "ʲ", "diacritic", "palatalized", { alias_of = "_j" })
push_spec(DEFAULT_SPECS, ":", "ː", "length", "long")
push_spec(DEFAULT_SPECS, ":\\", "ˑ", "length", "half-long")
push_spec(DEFAULT_SPECS, "-", "", "separator", "separator", { reverse = false, prefer_incomplete_at_eof = true })
push_spec(DEFAULT_SPECS, "_", "͡", "tie", "tie bar", { prefer_incomplete_at_eof = true })
push_spec(DEFAULT_SPECS, "@", "ə", "vowel", "schwa")
push_spec(DEFAULT_SPECS, "@\\", "ɘ", "vowel", "close-mid central unrounded vowel")
push_spec(DEFAULT_SPECS, "@`", "ɚ", "vowel", "r-colored schwa")
push_spec(DEFAULT_SPECS, "{", "æ", "vowel", "near-open front unrounded vowel")
push_spec(DEFAULT_SPECS, "}", "ʉ", "vowel", "close central rounded vowel")
push_spec(DEFAULT_SPECS, "1", "ɨ", "vowel", "close central unrounded vowel")
push_spec(DEFAULT_SPECS, "2", "ø", "vowel", "close-mid front rounded vowel")
push_spec(DEFAULT_SPECS, "3", "ɜ", "vowel", "open-mid central unrounded vowel")
push_spec(DEFAULT_SPECS, "3\\", "ɞ", "vowel", "open-mid central rounded vowel")
push_spec(DEFAULT_SPECS, "4", "ɾ", "consonant", "alveolar flap")
push_spec(DEFAULT_SPECS, "5", "ɫ", "consonant", "velarized alveolar lateral approximant")
push_spec(DEFAULT_SPECS, "6", "ɐ", "vowel", "near-open central vowel")
push_spec(DEFAULT_SPECS, "7", "ɤ", "vowel", "close-mid back unrounded vowel")
push_spec(DEFAULT_SPECS, "8", "ɵ", "vowel", "close-mid central rounded vowel")
push_spec(DEFAULT_SPECS, "9", "œ", "vowel", "open-mid front rounded vowel")
push_spec(DEFAULT_SPECS, "&", "ɶ", "vowel", "open front rounded vowel")
push_spec(DEFAULT_SPECS, "?", "ʔ", "consonant", "glottal stop")
push_spec(DEFAULT_SPECS, "?\\", "ʕ", "consonant", "voiced pharyngeal fricative")
push_spec(DEFAULT_SPECS, "/", "/", "delimiter", "delimiter")
push_spec(DEFAULT_SPECS, "<", "⟨", "bracket", "begin nonsegmental notation")
push_spec(DEFAULT_SPECS, "<\\", "ʢ", "consonant", "voiced epiglottal fricative")
push_spec(DEFAULT_SPECS, ">", "⟩", "bracket", "end nonsegmental notation")
push_spec(DEFAULT_SPECS, ">\\", "ʡ", "consonant", "epiglottal plosive")
push_spec(DEFAULT_SPECS, "^", "ꜛ", "tone", "upstep")
push_spec(DEFAULT_SPECS, "!", "ꜜ", "tone", "downstep")
push_spec(DEFAULT_SPECS, "!\\", "ǃ", "consonant", "postalveolar click")
push_spec(DEFAULT_SPECS, "|", "|", "group", "minor group")
push_spec(DEFAULT_SPECS, "|\\", "ǀ", "consonant", "dental click")
push_spec(DEFAULT_SPECS, "||", "‖", "group", "major group")
push_spec(DEFAULT_SPECS, "|\\|\\", "ǁ", "consonant", "alveolar lateral click")
push_spec(DEFAULT_SPECS, "=\\", "ǂ", "consonant", "palatal click")
push_spec(DEFAULT_SPECS, "-\\", "‿", "linking", "linking mark")

push_spec(DEFAULT_SPECS, '_"', "̈", "diacritic", "centralized")
push_spec(DEFAULT_SPECS, "_+", "̟", "diacritic", "advanced")
push_spec(DEFAULT_SPECS, "_-", "̠", "diacritic", "retracted")
push_spec(DEFAULT_SPECS, "_/", "̌", "tone", "rising contour")
push_alias(DEFAULT_SPECS, "_R", "̌", "_/", "tone", "rising contour")
push_spec(DEFAULT_SPECS, "_0", "̥", "diacritic", "voiceless")
push_spec(DEFAULT_SPECS, "=", "̩", "diacritic", "syllabic")
push_alias(DEFAULT_SPECS, "_=", "̩", "=", "diacritic", "syllabic")
push_spec(DEFAULT_SPECS, "_>", "ʼ", "diacritic", "ejective")
push_spec(DEFAULT_SPECS, "_?\\", "ˤ", "diacritic", "pharyngealized")
push_spec(DEFAULT_SPECS, "_\\", "̂", "tone", "falling contour")
push_alias(DEFAULT_SPECS, "_F", "̂", "_\\", "tone", "falling contour")
push_spec(DEFAULT_SPECS, "_^", "̯", "diacritic", "non-syllabic")
push_spec(DEFAULT_SPECS, "_}", "̚", "diacritic", "no audible release")
push_spec(DEFAULT_SPECS, "`", "˞", "diacritic", "rhotacization")
push_spec(DEFAULT_SPECS, "~", "̃", "diacritic", "nasalization")
push_alias(DEFAULT_SPECS, "_~", "̃", "~", "diacritic", "nasalization")
push_spec(DEFAULT_SPECS, "_A", "̘", "diacritic", "advanced tongue root")
push_spec(DEFAULT_SPECS, "_a", "̺", "diacritic", "apical")
push_spec(DEFAULT_SPECS, "_B", "̏", "tone", "extra low tone")
push_spec(DEFAULT_SPECS, "_B_L", "᷅", "tone", "low rising tone")
push_spec(DEFAULT_SPECS, "_c", "̜", "diacritic", "less rounded")
push_spec(DEFAULT_SPECS, "_d", "̪", "diacritic", "dental")
push_spec(DEFAULT_SPECS, "_e", "̴", "diacritic", "velarized or pharyngealized")
push_spec(DEFAULT_SPECS, "_f", "↘", "tone", "global fall")
push_spec(DEFAULT_SPECS, "_G", "ˠ", "diacritic", "velarized")
push_spec(DEFAULT_SPECS, "_H", "́", "tone", "high tone")
push_spec(DEFAULT_SPECS, "_H_T", "᷄", "tone", "high rising tone")
push_spec(DEFAULT_SPECS, "_h", "ʰ", "diacritic", "aspirated")
push_spec(DEFAULT_SPECS, "_j", "ʲ", "diacritic", "palatalized")
push_spec(DEFAULT_SPECS, "_k", "̰", "diacritic", "creaky voice")
push_spec(DEFAULT_SPECS, "_L", "̀", "tone", "low tone")
push_spec(DEFAULT_SPECS, "_l", "ˡ", "diacritic", "lateral release")
push_spec(DEFAULT_SPECS, "_M", "̄", "tone", "mid tone")
push_spec(DEFAULT_SPECS, "_m", "̻", "diacritic", "laminal")
push_spec(DEFAULT_SPECS, "_N", "̼", "diacritic", "linguolabial")
push_spec(DEFAULT_SPECS, "_n", "ⁿ", "diacritic", "nasal release")
push_spec(DEFAULT_SPECS, "_O", "̹", "diacritic", "more rounded")
push_spec(DEFAULT_SPECS, "_o", "̞", "diacritic", "lowered")
push_spec(DEFAULT_SPECS, "_q", "̙", "diacritic", "retracted tongue root")
push_spec(DEFAULT_SPECS, "_r", "̝", "diacritic", "raised")
push_spec(DEFAULT_SPECS, "_R_F", "᷈", "tone", "rising falling tone")
push_spec(DEFAULT_SPECS, "_T", "̋", "tone", "extra high tone")
push_spec(DEFAULT_SPECS, "_t", "̤", "diacritic", "breathy voice")
push_spec(DEFAULT_SPECS, "_v", "̬", "diacritic", "voiced")
push_spec(DEFAULT_SPECS, "_w", "ʷ", "diacritic", "labialized")
push_spec(DEFAULT_SPECS, "_X", "̆", "diacritic", "extra-short")
push_spec(DEFAULT_SPECS, "_x", "̽", "diacritic", "mid-centralized")

push_spec(DEFAULT_SPECS, "ts", "ts", "cluster", "voiceless alveolar affricate")
push_spec(DEFAULT_SPECS, "dz", "dz", "cluster", "voiced alveolar affricate")
push_spec(DEFAULT_SPECS, "tS", "tʃ", "cluster", "voiceless postalveolar affricate")
push_spec(DEFAULT_SPECS, "dZ", "dʒ", "cluster", "voiced postalveolar affricate")
push_spec(DEFAULT_SPECS, "ts\\", "tɕ", "cluster", "voiceless alveolo-palatal affricate")
push_spec(DEFAULT_SPECS, "dz\\", "dʑ", "cluster", "voiced alveolo-palatal affricate")
push_spec(DEFAULT_SPECS, "tK", "tɬ", "cluster", "voiceless alveolar lateral affricate")
push_spec(DEFAULT_SPECS, "dK\\", "dɮ", "cluster", "voiced alveolar lateral affricate")
push_spec(DEFAULT_SPECS, "kp", "kp", "cluster", "voiceless labial-velar plosive")
push_spec(DEFAULT_SPECS, "gb", "gb", "cluster", "voiced labial-velar plosive")
push_spec(DEFAULT_SPECS, "Nm", "ŋm", "cluster", "labial-velar nasal stop")

M.DEFAULT_SPECS = DEFAULT_SPECS

local function compile_lookup(specs, source_key, target_key)
  local by_len = {}
  local max_len = 0
  local prefixes = {}

  for _, spec in ipairs(specs) do
    local source = spec[source_key]
    local source_len = #source

    if source_len > max_len then
      max_len = source_len
    end

    if not by_len[source_len] then
      by_len[source_len] = {}
    end

    local entry = clone_spec(spec)
    entry.source = source
    entry.target = spec[target_key]
    entry.source_chars = utf8_len(source)
    entry.target_chars = utf8_len(spec[target_key])
    by_len[source_len][source] = entry

    for prefix_len = 1, source_len - 1 do
      prefixes[source:sub(1, prefix_len)] = true
    end
  end

  return {
    by_len = by_len,
    max_len = max_len,
    prefixes = prefixes,
  }
end

local function build_reverse_specs(specs)
  local reverse_specs = {}
  local grouped = {}
  local order = {}

  for _, spec in ipairs(specs) do
    if spec.reverse ~= false and spec.ipa ~= "" then
      local entry = grouped[spec.ipa]
      if not entry then
        entry = {
          ipa = spec.ipa,
          xsampa = spec.xsampa,
          kind = spec.kind,
          label = spec.label,
          aliases = {},
          seen = {},
          alias_only = spec.alias_of ~= nil,
        }
        grouped[spec.ipa] = entry
        order[#order + 1] = spec.ipa
      elseif entry.alias_only and spec.alias_of == nil and entry.xsampa ~= spec.xsampa then
        if not entry.seen[entry.xsampa] then
          entry.seen[entry.xsampa] = true
        end
        entry.aliases[#entry.aliases + 1] = entry.xsampa
        entry.xsampa = spec.xsampa
        entry.kind = spec.kind
        entry.label = spec.label
        entry.alias_only = false
      end

      if not entry.seen[spec.xsampa] then
        entry.seen[spec.xsampa] = true
        if entry.xsampa ~= spec.xsampa then
          entry.aliases[#entry.aliases + 1] = spec.xsampa
        end
      end
    end
  end

  for _, ipa in ipairs(order) do
    local entry = grouped[ipa]
    entry.seen = nil
    entry.alias_only = nil
    entry.alternatives = entry.aliases
    entry.aliases = nil
    reverse_specs[#reverse_specs + 1] = entry
  end

  return reverse_specs
end

local function build_result(mode, input, output, tokens, input_chars, output_chars)
  return {
    mode = mode,
    input = input,
    output = output,
    tokens = tokens,
    input_span = {
      byte_start = 0,
      byte_stop = #input,
      char_start = 0,
      char_stop = input_chars,
    },
    output_span = {
      byte_start = 0,
      byte_stop = #output,
      char_start = 0,
      char_stop = output_chars,
    },
  }
end

local function render_incomplete(fragment, opts)
  local policy = opts and opts.incomplete or "preserve"

  if policy == "omit" then
    return ""
  end

  if policy == "mark" then
    local marker = opts and opts.incomplete_marker or "…"
    return marker
  end

  return fragment
end

local function transcode(text, machine, mode, opts)
  local tokens = {}
  local pieces = {}
  local input_index = 1
  local input_byte_col = 0
  local input_char_col = 0
  local output_byte_col = 0
  local output_char_col = 0

  while input_index <= #text do
    local remaining = #text - input_index + 1
    local max_len = machine.max_len
    if remaining < max_len then
      max_len = remaining
    end

    local matched = nil
    local matched_text = nil
    local matched_len = 0

    for len = max_len, 1, -1 do
      local bucket = machine.by_len[len]
      if bucket then
        local chunk = text:sub(input_index, input_index + len - 1)
        local spec = bucket[chunk]
        if spec then
          matched = spec
          matched_text = chunk
          matched_len = len
          break
        end
      end
    end

    local output_text
    local token_kind
    local token_label
    local input_chars
    local output_chars
    local status

    local remaining_fragment = text:sub(input_index)
    local at_eof = input_index + matched_len - 1 == #text
    local incomplete = false

    if matched and at_eof and matched.prefer_incomplete_at_eof then
      incomplete = true
    elseif not matched and machine.prefixes[remaining_fragment] then
      incomplete = true
      matched_text = remaining_fragment
      matched_len = #remaining_fragment
    end

    if incomplete then
      output_text = render_incomplete(matched_text, opts)
      token_kind = matched and (matched.kind or "mapped") or "incomplete"
      token_label = matched and matched.label or nil
      input_chars = utf8_len(matched_text)
      output_chars = utf8_len(output_text)
      status = "incomplete"
    elseif matched then
      output_text = matched.target
      token_kind = matched.kind or "mapped"
      token_label = matched.label
      input_chars = matched.source_chars
      output_chars = matched.target_chars
      status = matched.alternatives and #matched.alternatives > 0 and "ambiguous" or "mapped"
    else
      matched_text, matched_len = next_utf8(text, input_index)
      output_text = matched_text
      token_kind = "raw"
      token_label = nil
      input_chars = 1
      output_chars = 1
      status = "raw"
    end

    pieces[#pieces + 1] = output_text
    tokens[#tokens + 1] = {
      kind = token_kind,
      label = token_label,
      status = status,
      alias_of = matched and matched.alias_of or nil,
      alternatives = matched and matched.alternatives or nil,
      input = {
        text = matched_text,
        byte_start = input_byte_col,
        byte_stop = input_byte_col + matched_len,
        char_start = input_char_col,
        char_stop = input_char_col + input_chars,
      },
      output = {
        text = output_text,
        byte_start = output_byte_col,
        byte_stop = output_byte_col + #output_text,
        char_start = output_char_col,
        char_stop = output_char_col + output_chars,
      },
    }

    input_index = input_index + matched_len
    input_byte_col = input_byte_col + matched_len
    input_char_col = input_char_col + input_chars
    output_byte_col = output_byte_col + #output_text
    output_char_col = output_char_col + output_chars
  end

  return build_result(mode, text, table.concat(pieces), tokens, input_char_col, output_char_col)
end

local function finalize_result(result, opts)
  if opts and opts.tokens then
    return result
  end
  return result.output
end

local function get_unit_key(unit)
  if unit == "byte" then
    return "byte"
  end
  return "char"
end

local function map_position(result, source_key, target_key, col, unit)
  local unit_key = get_unit_key(unit)
  local start_key = unit_key .. "_start"
  local stop_key = unit_key .. "_stop"

  if col <= 0 then
    return 0
  end

  for _, token in ipairs(result.tokens) do
    local source = token[source_key]
    local target = token[target_key]

    if col <= source[start_key] then
      return target[start_key]
    end

    if col < source[stop_key] then
      return target[start_key]
    end

    if col == source[stop_key] then
      return target[stop_key]
    end
  end

  return result[target_key .. "_span"][stop_key]
end

local function build_engine(specs)
  local forward = compile_lookup(specs, "xsampa", "ipa")
  local reverse_specs = build_reverse_specs(specs)
  local reverse = compile_lookup(reverse_specs, "ipa", "xsampa")

  local engine = {}

  function engine:xsampa_to_ipa(text, opts)
    return finalize_result(transcode(text, forward, "xsampa_to_ipa", opts), opts)
  end

  function engine:ipa_to_xsampa(text, opts)
    return finalize_result(transcode(text, reverse, "ipa_to_xsampa", opts), opts)
  end

  function engine:render(result)
    return result.output
  end

  function engine:map_input_to_output(result, col, unit)
    return map_position(result, "input", "output", col, unit)
  end

  function engine:map_output_to_input(result, col, unit)
    return map_position(result, "output", "input", col, unit)
  end

  function engine:is_prefix(fragment, direction)
    local machine = direction == "ipa_to_xsampa" and reverse or forward
    return machine.prefixes[fragment] == true
  end

  function engine:specs()
    local copies = {}
    for index, spec in ipairs(specs) do
      copies[index] = clone_spec(spec)
    end
    return copies
  end

  return engine
end

function M.new(opts)
  local specs = DEFAULT_SPECS

  if opts and opts.specs then
    specs = opts.specs
  elseif opts and opts.extend_specs then
    specs = {}
    for _, spec in ipairs(DEFAULT_SPECS) do
      specs[#specs + 1] = clone_spec(spec)
    end
    for _, spec in ipairs(opts.extend_specs) do
      specs[#specs + 1] = clone_spec(spec)
    end
  end

  return build_engine(specs)
end

local default_engine = build_engine(DEFAULT_SPECS)

function M.xsampa_to_ipa(text, opts)
  return default_engine:xsampa_to_ipa(text, opts)
end

function M.ipa_to_xsampa(text, opts)
  return default_engine:ipa_to_xsampa(text, opts)
end

function M.render(result)
  return default_engine:render(result)
end

function M.map_input_to_output(result, col, unit)
  return default_engine:map_input_to_output(result, col, unit)
end

function M.map_output_to_input(result, col, unit)
  return default_engine:map_output_to_input(result, col, unit)
end

function M.is_prefix(fragment, direction)
  return default_engine:is_prefix(fragment, direction)
end

return M
