# baker, the real static blog generator

very concise and simple.

## benefit
1. easily hook any other command's stdout and put it into your blog.  
i.e. {% snippet cal %} gives a simple calendar

2. less dependency: except `jshon`, all are covered by coreutil
3. experiment with your mac/linux
4. only re-bake if required


## template (bash)

1. `dry` and simple.
2. all html escapes by default. use `{{{   }}}` to skip html escaping

``f
# if: {% if var %} ... {% endif %} 
# foreach: {% foreach var %} ... {% endforeach %}
# include: {% include name%}
# escape_var: {{ name }}
# var: {{{ name }}}
## snippet: {% snippet name %}

``

## markdown (bash)

beautify implementation in bash, and maintainable


## contribute
please:

1. improve code simplicity and performance
2. share useful snippet
3. improve bake chain
4. refactor, refactor

## author
1. taylorchu

