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

`each` iterates an array. This is why a number is not allowed in a variable name.

For example,

```
posts = [
	{
		"title": "first",
		"content": "example1",
	},
	{
		"title": "second",
		"content": "example2",
	},
]
```

is encoded as:

```
posts_0_title=first
posts_0_content=example1

posts_1_title=second
posts_1_content=example2
```

```
@each posts
	{{ title }} - {{ content }}
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
