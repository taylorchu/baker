# baker, the real static blog generator in bash
![baker](http://i.imgur.com/Tngl5Vv.png)
very concise and simple.
![thumb](http://i.imgur.com/3RMqeR0.jpg?1)

## benefit
1. easily hook any other command's stdout and put it into your blog.  
i.e. {% snippet cal %} gives a simple calendar

2. less dependency: all are covered by coreutil
3. experiment with your mac/linux
4. only re-bake if required

## usage

```
baker.sh
    post [title]        create new post
    page [title]        create new post
    bake [--force]      ship static page

```
1. ./baker.sh post I like the baker's bread
2. baker will turn that into a markdown file in posts/, so you can use your editor. vim it.
3. ./baker bake
4. profit!

## template (bash)

1. `dry` and simple.
2. all html escapes by default. use `{{{   }}}` to skip html escaping

```
# if: {% if var %} ... {% endif %} 
# foreach: {% foreach var %} ... {% endforeach %}
# include: {% include name%}
# escape_var: {{ name }}
# var: {{{ name }}}
## snippet: {% snippet name %}

```

## markdown (bash)

beautiful and maintainable implementation in bash


## contribute
please:

1. improve code simplicity and performance
2. share useful snippet
3. improve bake chain
4. refactor, refactor

## note
snippets are dangerous.

## license & author
taylorchu, gpl2 licensed

