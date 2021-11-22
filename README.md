## Limitation

### Code Block

language are currently not preserved

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
- Fix bloc/italic can wrap multiple leafs