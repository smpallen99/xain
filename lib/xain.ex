defmodule Xain do
  require Logger
  import Xain.Helpers

  defmacro __using__(opts) do
    except = Keyword.get opts, :except, []

    quote do
      import unquote(__MODULE__), except: unquote(except)
      import Kernel, except: [div: 2]
    end
  end

  def quote_symbol, do: Application.get_env(:xain, :quote, "'")

  @defaults [
    input: [type: :text],
    form: [method: :post],
    table: [border: 0, cellspacing: 0, cellpadding: 0]
  ]

  @auto_build_elements [ :a, :abbr, :address, :area, :article, :aside, :audio, :b, :base,
                         :bdo, :blockquote, :body, :br, :button, :canvas, :caption, :cite,
                         :code, :col, :colgroup, :command, :datalist, :dd, :del, :details,
                         :dfn, :div, :dl, :dt, :em, :embed, :fieldset, :figcaption, :figure,
                         :footer, :form, :h1, :h2, :h3, :h4, :h5, :h6, :head, :header, :hgroup,
                         :hr, :html, :i, :iframe, :img, :input, :ins, :keygen, :kbd, :label,
                         :legend, :li, :link, :map, :mark, :menu, :menuitem, :meta, :meter, :nav, :noscript,
                         :object, :ol, :optgroup, :option, :output, :param, :pre, :progress, :q,
                         :s, :samp, :script, :section, :select, :small, :source, :span,
                         :strong, :style, :sub, :summary, :sup, :svg, :table, :tbody, :td,
                         :textarea, :tfoot, :th, :thead, :time, :title, :tr, :track, :ul, :var, :video, :wbr ]

  @self_closing_elements  [ :area, :base, :br, :col, :embed, :hr, :img, :input, :keygen, :link,
                            :menuitem, :meta, :param, :source, :track, :wbr ]

  @html5_elements [ :p ] ++ @auto_build_elements

  for tag <-@html5_elements -- @self_closing_elements do
    defmacro unquote(tag)(contents \\ "", attrs \\ [], inner \\ []) do
      tag = unquote(tag)
      quote location: :keep, do: tag(unquote(tag), unquote(contents), unquote(attrs), unquote(inner), false)
    end
  end

  for tag <- @self_closing_elements do
    defmacro unquote(tag)(contents \\ "", attrs \\ [], inner \\ []) do
      tag = unquote(tag)
      quote location: :keep, do: tag(unquote(tag), unquote(contents), unquote(attrs), unquote(inner), true)
    end
  end

  defmacro tag(name, contents \\ "", attrs \\ [], inner \\ [], sc \\ false) do
    contents = join_lines(contents)
    attrs = join_lines(attrs)

    quote location: :keep do
      name = unquote(name)
      contents = unquote(contents)
      sc = unquote(sc)
      inner = unquote(inner)
      attrs = unquote(attrs)

      Xain.build_tag(name, contents, attrs, inner, sc)
    end
  end

  defp join_lines(ast) do
    case ast do
      [do: {:__block__, _, [_]}] ->
        ast
      [do: {:__block__, trace, inner_list}] ->
        [do: {:__block__, trace, handle_inner_list(inner_list)}]
      _ ->
        ast
    end
  end

  def join(list) do
    list 
    |> Enum.map(&item_to_string/1)
    |> Enum.filter(&(&1))
    |> Enum.reverse
    |> Enum.join
  end

  defp item_to_string(item) when is_list(item) do
    item |> Enum.map(&item_to_string/1) |> Enum.filter(&(&1)) |> Enum.join
  end
  defp item_to_string(item) when is_binary(item) do
    item
  end
  defp item_to_string(_) do
    false
  end

  defp handle_inner_list(list, acc \\ [])
  defp handle_inner_list([], acc) do
    quoted_join = {{:., [], [{:__aliases__, [alias: false], [:Xain]}, :join]}, [], [{:xain_buffer, [], Elixir}]}
    acc = [quoted_join | acc]
    acc = Enum.reverse(acc)
    [{:=, [], [{:xain_buffer, [], Elixir}, []]} | acc]
  end
  defp handle_inner_list([line|tail], acc) do
    case line do
      {:=, _, _} ->
        handle_inner_list(tail, [line | acc])
      _ ->
        line = {:=, [], [{:xain_buffer, [], Elixir}, [{:|, [], [line, {:xain_buffer, [], Elixir}]}]]}
        handle_inner_list(tail, [line | acc])
    end
  end

  def build_tag(name, contents, attrs, _inner, sc) when is_list(contents) do
    build_tag(name, "", contents, attrs, sc)
  end
  def build_tag(name, contents, attrs, inner, sc) do
    {inner, [contents, attrs]} = extract_do_block(contents, attrs, inner)
    sc_str = if sc, do: "/", else: ""

    attrs = attrs |> set_defaults(name)
    contents = ensure_valid_contents(contents, name)
    {contents, attrs} = id_and_class_shortcuts(contents, attrs)

    result = Xain.open_tag(name, attrs, sc_str) 
    result = result <> contents <> Enum.join(inner)

    if not sc do
      result <> "</#{name}>"
    else
      result
    end   
  end

  def open_tag(name, attrs, sc \\ "")
  def open_tag(name, [], sc), do: "<#{name}#{sc}>"
  def open_tag(name, attrs, sc) do
    attr_html = for {key, val} <- attrs, into: "", do: " #{key}=#{quote_symbol}#{val}#{quote_symbol}"
    "<#{name}#{attr_html}#{sc}>"
  end

  defmacro markup(do: block) do
    [do: block] = join_lines([do: block])
    quote location: :keep do
      require Logger
      import Kernel, except: [div: 2]
      import unquote(__MODULE__)

      result = try do
        unquote(block)
      rescue
        exception ->
          Logger.error inspect(exception)
          Logger.error inspect(System.stacktrace)
          reraise exception, System.stacktrace
      end
 
      case Application.get_env :xain, :after_callback do
        nil ->
          result
        {mod, fun} ->
          apply mod, fun, [result]
      end
    end
  end

  defmacro markup(:nested, do: block) do
    [do: block] = join_lines([do: block])
    quote location: :keep do
      require Logger
      import Kernel, except: [div: 2]
      import unquote(__MODULE__)

      result = unquote(block)
      
      case Application.get_env :xain, :after_callback do
        nil ->
          result
        {mod, fun} ->
          apply mod, fun, [result]
      end
    end
  end


  defmacro text(string) do
    quote do: unquote(string)
  end

  defmacro raw(string) do
    quote do
      str = case unquote(string) do
        string when is_binary(string) -> string
        {:safe, list} -> List.to_string list
        other -> inspect other
      end
    end
  end

  def get_defaults(name) do
    Keyword.get(@defaults, name, [])
  end

  def set_defaults(attrs, name) do
    Keyword.merge(get_defaults(name), attrs)
  end
end
