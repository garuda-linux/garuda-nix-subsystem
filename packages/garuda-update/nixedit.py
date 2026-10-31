"""Edits of Nix files that keep comments and formatting, via tree-sitter-nix."""

import warnings

ATTRSETS = ("attrset_expression", "rec_attrset_expression")
WRAPPERS = (
    "source_code",
    "function_expression",
    "let_expression",
    "with_expression",
    "assert_expression",
    "parenthesized_expression",
)


class Unavailable(Exception):
    pass


class EditError(Exception):
    pass


def parse(src):
    try:
        import tree_sitter
        import tree_sitter_nix
    except ImportError as e:
        raise Unavailable(f"tree-sitter-nix is not available ({e})") from e

    with warnings.catch_warnings():
        # tree-sitter-nix still hands out the language as an int
        warnings.simplefilter("ignore", DeprecationWarning)
        language = tree_sitter.Language(tree_sitter_nix.language())

    root = tree_sitter.Parser(language).parse(src).root_node

    if root.has_error:
        raise EditError("file does not parse as Nix")

    return root


def string_value(node):
    """The fragment node of a string literal without interpolation, else None."""

    if node is not None and node.type == "string_expression":
        parts = node.named_children

        if len(parts) == 1 and parts[0].type == "string_fragment":
            return parts[0]

    return None


def _body(node):
    while node is not None and node.type in WRAPPERS:
        node = node.child_by_field_name("body") or next(
            (c for c in reversed(node.named_children) if c.type != "comment"), None
        )

    return node


def _key(node):
    if node.type == "identifier":
        return node.text.decode()

    fragment = string_value(node)

    return fragment.text.decode() if fragment else None


def bindings(node, prefix=()):
    """Yield (full path, value node) of static bindings."""
    node = _body(node)

    if node is None or node.type not in ATTRSETS:
        return

    for group in node.named_children:
        for binding in group.named_children if group.type == "binding_set" else ():
            if binding.type != "binding":
                continue

            keys = binding.child_by_field_name("attrpath").named_children
            names = [_key(k) for k in keys]

            if None in names:
                continue

            value = binding.child_by_field_name("expression")

            yield prefix + tuple(names), value
            yield from bindings(value, prefix + tuple(names))


def splice(src, edits):
    """Apply (start, end, replacement) byte edits."""

    for start, end, new in sorted(edits, reverse=True):
        src = src[:start] + new + src[end:]

    return src
