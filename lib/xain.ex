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

  @quote  Application.get_env :xain, :quote, "\""

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
    Xain.build_tag(name, contents, attrs, inner, sc )
  end

  def build_tag(name, contents, attrs, _inner, sc) when is_list(contents) do
    build_tag(name, "", contents, attrs, sc)
  end
  def build_tag(name, contents, attrs, inner, sc) do
    {inner, [contents, attrs]} = extract_do_block(contents, attrs, inner)
    sc_str = if sc, do: "/", else: ""

    quote location: :keep do
      name = unquote(name)
      contents = unquote(contents)
      sc_str = unquote(sc_str)
      sc = unquote(sc)
      attrs = unquote(attrs)

      attrs = attrs |> set_defaults(name)
      {contents, attrs} = id_and_class_shortcuts(contents, attrs)

      #put_buffer var!(buffer, Xain), open_tag(unquote_splicing([name, attrs, sc_str]))
      put_buffer open_tag(name, attrs, sc_str)
      text(contents)
      unquote(inner)

      if not sc do
        put_buffer "</#{unquote(name)}>"
      end
    end
  end

  def open_tag(name, attrs, sc \\ "")
  def open_tag(name, [], sc), do: "<#{name}#{sc}>" 
  def open_tag(name, attrs, sc) do
    attr_html = for {key, val} <- attrs, into: "", do: " #{key}=#{@quote}#{val}#{@quote}"
    "<#{name}#{attr_html}#{sc}>"
  end

  defmacro markup(do: block) do 
    quote location: :keep do
      require Logger
      import Kernel, except: [div: 2]
      import unquote(__MODULE__)
      {:ok, _} = start_buffer([[]])
      unquote(block)
      result = render()
      :ok = stop_buffer()
      case Application.get_env :xain, :after_callback do
        nil -> 
          result
        callback ->   
          callback.(result)
      end
    end
  end

  defmacro markup(:nested, do: block) do
    quote location: :keep do
      require Logger
      import Kernel, except: [div: 2]
      import unquote(__MODULE__)

      get_buffer |> Agent.update(&([[] | &1]))
    
      unquote(block)
      result = render
      get_buffer |> Agent.update(&(tl &1)) 
      case Application.get_env :xain, :after_callback do
        nil -> 
          result
        callback ->   
          callback.(result)
      end
    end
  end

  def start_ets() do
    my_pid = self
    unless :ets.info(:xain) == :undefined do
      raise Xain.MarkupNestingError, message: "Cannot nest markup calls"
    else
      pid = spawn fn -> 
        :ets.new :xain, [:public, :named_table]
        send my_pid, :ets_done
        receive do
          {:stop, pid} -> 
            :ets.delete :xain
            send pid, :done
            :ok
        end
      end
      receive do
        :ets_done -> 
          :ets.insert :xain, {:pid, pid}    
      end
    end
  end

  def stop_ets() do 
    :ets.lookup(:xain, :pid)
    |> Keyword.get(:pid)
    |> send({:stop, self})
    wait_done
  end

  defp wait_done do
    receive do
      :done -> 
        :ok
      other -> 
        send self, other
        wait_done
    end
  end

  def get_buffer() do
    :ets.lookup(:xain, :buffer)
    |> Keyword.get(:buffer)
  end

  def start_buffer(state) do 
    start_ets
    {:ok, pid} = Agent.start_link(fn -> state end) 
    :ets.insert :xain, {:buffer, pid}
    {:ok, pid}
  end

  def stop_buffer(buff), do: Agent.stop(buff)
  def stop_buffer do
    get_buffer |> stop_buffer
    stop_ets
    :ok
  end

  def put_buffer(buff, content) do 
    Agent.update(buff, fn([head | tail]) -> 
      [[content | head] | tail] 
    end) # &[content | &1]) 
  end
  def put_buffer(content) do
    if :ets.info(:xain) == :undefined do
      raise Xain.NoMarkupError, message: "Must call API inside markup do"
    end
    get_buffer |> put_buffer(content)
  end

  def render(buff) do 
    Agent.get(buff, &(hd &1)) |> Enum.reverse |> Enum.join("") 
  end
  def render do
    get_buffer |> render
  end

  defmacro text(string) do 
    quote do: put_buffer(unquote(string))
  end

  def get_defaults(name) do
    Keyword.get(@defaults, name, [])
  end

  def set_defaults(attrs, name) do
    Keyword.merge(get_defaults(name), attrs)
  end
end
