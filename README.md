# baker, the real static blog generator in bash

![baker](http://i.imgur.com/Tngl5Vv.png)

It is under a big redesign.

## Why

- simple: bring your own editor
- fun: use any command in your blog
- portable: blog on almost any linux/mac distribution

## Template redesigned

The new template engine is much faster (and smaller) than the previous version. It now uses bash's scope as its context.

### variable

Variable identifier should only use `[A-Za-z_]`. Notice that any number is not allowed in a variable name.

```
{{ var_name }}

{{ content }} # embed child layout output
```

### if

Notice that spaces are not allowed between `!` and `var`.

```
@if !var
	...
@end
```

### each

```
@each array
	...
@end
```

### include

`@include` includes a partial from `$LAYOUT_DIR/$filename.md`. Notice that `.md` is already added.

```
@include filename
```

### cmd

`@cmd` uses any command's stdout and ignore its stderr.

```
@cmd
	...
@end
```

## Markdown

It currently uses the implementation from [Daring Fireball](http://daringfireball.net/projects/markdown/).

## License

This software is made by taylorchu, and is released under GPL2.
