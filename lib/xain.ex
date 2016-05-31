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

  for tag <- @html5_elements -- @self_closing_elements do
    defmacro unquote(tag)(contents \\ "", attrs \\ nil, inner \\ nil) do
      tag = unquote(tag)
      quote location: :keep, do: tag(unquote(tag), unquote(contents), unquote(attrs), unquote(inner), false)
    end
  end

  for tag <- @self_closing_elements do
    defmacro unquote(tag)(contents \\ "", attrs \\ nil, inner \\ nil) do
      tag = unquote(tag)
      quote location: :keep, do: tag(unquote(tag), unquote(contents), unquote(attrs), unquote(inner), true)
    end
  end

  defmacro tag(name, inline_content \\ "", attrs \\ nil, inner_block \\ nil, sc \\ false) do
    {inline_content, attrs, inner_content} = prepare_args(inline_content, attrs, inner_block)
    inner_content = join_lines(inner_content)

    quote bind_quoted: [name: name, inline_content: inline_content, attrs: attrs, inner_content: inner_content, sc: sc], location: :keep do
      Xain.build_tag(name, inline_content, attrs, inner_content, sc)
    end
  end

  defp prepare_args([do: inner_content], nil, nil), do: {"", [], inner_content}
  defp prepare_args(content, [do: inner_content], nil), do: {content, [], inner_content}
  defp prepare_args(content, attrs, [do: inner_content]), do: {content, attrs, inner_content}
  defp prepare_args(content, attrs, nil), do: {content, attrs || [], []}

  defp join_lines(ast) do
    case ast do
      {:__block__, trace, inner_list} ->
        {:__block__, trace, handle_inner_list(inner_list)}
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

  def build_tag(name, attrs, _, inner, sc) when is_list(attrs) do
    build_tag(name, "", attrs, inner, sc)
  end
  def build_tag(name, inline_content, attrs, inner, sc) do
    inline_content
    |> ensure_valid_contents(name)
    |> merge_attrs(attrs, name)
    |> merge_content(inner)
    |> wrap_in_tags(name, sc)
  end


  defp merge_attrs(content, attrs, tag_name) do
    attrs = attrs |> set_defaults(tag_name)
    {content, attrs} = id_and_class_shortcuts(content, attrs)
    attrs_html = for {key, val} <- attrs, into: "", do: " #{key}=#{quote_symbol}#{val}#{quote_symbol}"
    {content, attrs_html}
  end

  defp merge_content({inline_content, attrs_html}, inner) do
    inner_content = cond do
      is_list(inner) -> Enum.join(inner)
      is_binary(inner) -> inner
      true -> ""
    end
    {inline_content <> inner_content, attrs_html}
  end

  defp wrap_in_tags({_content, attrs_html}, name, true) do
    "<#{name}#{attrs_html}/>"
  end
  defp wrap_in_tags({content, attrs_html}, name, false) do
    "<#{name}#{attrs_html}>#{content}</#{name}>"
  end


  defmacro markup(opts \\ [], block)
  defmacro markup(:nested, do: block) do
    quote location: :keep do
      markup([safe: true], do: unquote(block))
    end
  end
  defmacro markup(opts, do: block) do
    block = join_lines(block)
    quote location: :keep do
      require Logger
      import Kernel, except: [div: 2]
      import unquote(__MODULE__)
      opts = unquote(opts)

      result = try do
        unquote(block)
      rescue
        exception ->
          Logger.error inspect(exception)
          Logger.error inspect(System.stacktrace)
          reraise exception, System.stacktrace
      end
      if opts[:safe] do
        case Application.get_env :xain, :after_callback do
          nil ->
            result
          {mod, fun} ->
            apply mod, fun, [result]
        end
      else
        result
      end
    end
  end

  defmacro text(string) do
    quote do: to_string(unquote(string))
  end

  defmacro raw(string) do
    quote do
      str = case unquote(string) do
        string when is_binary(string) -> string
        {:safe, list} -> List.to_string list
        other -> to_string other
      end
    end
  end

  defp get_defaults(name) do
    Keyword.get(@defaults, name, [])
  end

  defp set_defaults(attrs, name) do
    Keyword.merge(get_defaults(name), attrs)
  end
end
