BEGIN {
    scope = "<no-nonlocal-scope>"
}

/^[A-Za-z_][A-Za-z0-9_]*:$/ {
    scope = $0
    sub(/:$/, "", scope)
}

/^[[:space:]]+jmp \.nebo_function_return_[0-9]+$/ {
    label = $0
    sub(/^[[:space:]]+jmp /, "", label)
    key = scope SUBSEP label
    references[key]++
    scopes[key] = scope
    labels[key] = label
    total_references++
    if (scope == "<no-nonlocal-scope>") {
        cross_function++
    }
}

/^\.nebo_function_return_[0-9]+:$/ {
    label = $0
    sub(/:$/, "", label)
    key = scope SUBSEP label
    definitions[key]++
    scopes[key] = scope
    labels[key] = label
    total_definitions++
    if (scope == "<no-nonlocal-scope>") {
        cross_function++
    }
}

END {
    unresolved = 0
    duplicate = 0
    for (key in references) {
        if (references[key] > 0 && definitions[key] != 1) {
            unresolved++
        }
    }
    for (key in definitions) {
        if (definitions[key] > 1) {
            duplicate++
        }
    }
    printf "SUMMARY refs=%d defs=%d unresolved=%d duplicate=%d cross_function=%d\n", \
        total_references, total_definitions, unresolved, duplicate, cross_function
    if (unresolved != 0 || duplicate != 0 || cross_function != 0) {
        exit 1
    }
}
