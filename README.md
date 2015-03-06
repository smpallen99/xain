Xain - Easy HTML in Elixir
====

Library Providing HTML tag macros for Elixir

## Example usage

```Elixir
defmodule Example do
  use Xain

  markup do
    div ("#my-id.my-class") do
      span ".bold Testing"
    end
  end
end
```

Will render the following:

```html 
<div id="my-id" class="my-class"><span class="bold">Testing</span></div>
```

## Configuration 

### Add a call back to transform the returned html 

i.e. Phoenix safe

Add the following to your project's config file

```Elixir 
config :xain, :after_callback, &Phoenix.HTML.safe/1
```

Will render the above as:

```Elixir
{safe, "<div id=\"my-id\" class=\"my-class\"><span class=\"bold\">Testing</span></div>"}
```

### Change attribute quoting

To have return markup attributes use single quotes instead of the 
default double, add the following to your project's config file.

```Elixir
config :xain, :quote, "'"
```

Will render the above as:

```html
<div id='my-id' class='my-class'><span class='bold'>Testing</span></div>
```
## Acknowledgments 

This work was inspired by Chris McCord's book ["Metaprogramming Elixir"](https://pragprog.com/book/cmelixir/metaprogramming-elixir), and by the ruby project ["Arbre"](https://github.com/activeadmin/arbre)

## License

xain is Copyright (c) 2015 E-MetroTel

The source code is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
