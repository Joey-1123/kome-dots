"""Strip the omarchy menu module out of vendored waybar stylesheets.

The vendored sheets are upstream verbatim except for two things: the omarchy
palette import is replaced by aliases onto the generated kome palette, and every
selector that names the omarchy menu module is removed. Rules that only styled
omarchy are dropped outright; rules shared with kome's modules keep the rest of
their selector list.
"""

import re
import sys

OMARCHY = re.compile(r"custom-omarchy[\w-]*")


def matching_brace(text, start):
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("unbalanced braces")


def split_top_level(text):
    parts, depth, current = [], 0, []
    for char in text:
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        if char == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
    parts.append("".join(current))
    return parts


def clean(text):
    out = []
    index = 0
    while index < len(text):
        brace = text.find("{", index)
        if brace == -1:
            out.append(text[index:])
            break
        prelude = text[index:brace]
        if prelude.strip().startswith("@"):
            # at-rule such as @keyframes: keep it whole
            end = matching_brace(text, brace)
            out.append(prelude + "{" + text[brace + 1:end] + "}")
            index = end + 1
            continue
        end = matching_brace(text, brace)
        body = text[brace + 1:end]
        selectors = split_top_level(prelude)
        kept = [s for s in selectors if not OMARCHY.search(s)]
        if not kept:
            index = end + 1
            continue
        out.append(",".join(kept) + "{" + body + "}")
        index = end + 1
    return "".join(out)


for path in sys.argv[1:]:
    source = open(path).read()
    result = clean(source)
    result = re.sub(r"\n{3,}", "\n\n", result)
    open(path, "w").write(result)
    print(f"{path}: {result.count('custom-omarchy')} omarchy selector(s) left")
