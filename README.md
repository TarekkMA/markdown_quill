## Limitation


### Block attributes exclusivity

Currently flutter_quill block attributes have restrictions
on how they will be combined. 

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