## Limitation

### Code Block

language are currently not preserved

```markdown
``dart
void main() {
    print("Hello\n");
}
``
```
will be treated as:
```markdown
``
void main() {
    print("Hello\n");
}
``
```


### Image

Currently this convertor doesn't support image alts, only image src will be retained

### Block attributes exclusivity

flutter_quill block attributes have restrictions on how they can be combined.

These block attributes are executive and cannot be combined:

- Header
- List
- Code Block
- Block Quote

if the input markdown is:

```markdown
> # Foo
> bar
> baz
```

it will be treated as

```markdown
> Foo
> bar
> baz
```

## TODO

- Improve the output of `DeltaToMarkdown`