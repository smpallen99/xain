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
<div id='my-id' class='my-class'><span class='bold'>Testing</span></div>
```

## HTML Tag Attributes

Additional tag attributes can be included in the html tag by passing in key-value pairs.

```Elixir
markup do
  script src: "http://www.someexamplesite.com/example.js", type: "text/javascript"
end
```

Will render:

```html
<script src='http://www.someexamplesite.com/example.js' type='text/javascript'></script>
```

Or, with content:

```Elixir
markup do
  a "ExampleSite", [name: "example", href: "http://www.someexamplesite.com/"]
end
```

Will Render:

```html
<a name='example' href='http://www.someexamplesite.com/'>ExampleSite</a>
```

## Configuration

### Add a call back to transform the returned html

i.e. Phoenix raw

Add the following to your project's config file

```Elixir
config :xain, :after_callback, {Phoenix.HTML, :raw}
```

```Elixir
  markup safe: true do
    div ("#my-id.my-class") do
      span ".bold Testing"
    end
  end
```

Will render the above as:

```Elixir
{safe, "<div id='my-id' class='my-class'><span class='bold'>Testing</span></div>"}
```

### Change attribute quoting

To have return markup attributes use single quotes instead of the
default double, add the following to your project's config file.

```Elixir
config :xain, :quote, "\""
```

Will render the above as:

```html
<div id="my-id" class="my-class"><span class="bold">Testing</span></div>
```
## Acknowledgments

This work was inspired by Chris McCord's book ["Metaprogramming Elixir"](https://pragprog.com/book/cmelixir/metaprogramming-elixir), and by the ruby project ["Arbre"](https://github.com/activeadmin/arbre)

## License

xain is Copyright (c) 2015-2016 E-MetroTel
