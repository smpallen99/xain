defmodule Xain.Helpers do
  
  def extract_do_block(item) when is_list(item) do
    if Keyword.get(item, :do, nil) do
      block = case Keyword.get item, :do do
        block when is_list(block) -> block
        other -> [other]
      end
      {Keyword.delete(item, :do), block}
    else
      {item, []}
    end
  end
  def extract_do_block(other), do: {other, []}

  def extract_do_block(contents, attributes, block) do
    {children, list} = [contents, attributes, block] 
    |> Enum.reduce({[],[]}, fn(item, {block_list, items}) -> 
      {entry, children} = extract_do_block(item)
      {block_list ++ children, [entry | items]}
    end)
    {children, Enum.reverse(list) |> Enum.take(2)}
  end

  def push!([], item) do
    [item]
  end

  def push!([top | rest], item) do
    [[item | top] | rest]
  end

  def push_level!(buffer) do
    [[] | buffer]
  end

  def pop!([item | rest]) do
    {rest, item |> Enum.reverse}
  end
  
  def id_and_class_shortcuts(contents, attrs) when is_binary(contents) do
    tokenize(contents) |> _id_and_class_shortcuts(attrs)
  end
  def id_and_class_shortcuts(attrs, _) when is_list(attrs), do: {"", attrs}

  defp _id_and_class_shortcuts([], attrs), do: {"", attrs}

  defp _id_and_class_shortcuts([h | t], attrs) do
    case h do
      "#" <> id -> 
        id = String.strip(id)
        _id_and_class_shortcuts(t, merge_id_or_class(:id, id, attrs))
        
      "." <> class -> 
        class = String.strip(class)
        _id_and_class_shortcuts(t, merge_id_or_class(:class, class, attrs))

      # "%" <> name -> 
      #   name = String.strip(name)
      #   _id_and_class_shortcuts(t, struct(tag, name: String.to_atom(name)))

      contents -> 
        {contents, attrs}
    end
  end

  defp merge_id_or_class(:id, item, attrs ) do
    Keyword.merge([id: item], attrs)
  end

  defp merge_id_or_class(:class, item, attrs) do
    case Keyword.get(attrs, :class, "") do
      "" -> 
        Keyword.put(attrs, :class, item)
      other -> 
        Keyword.put(attrs, :class, other <> " " <> item)
    end
  end

  @tag_class_id ~S/(^%|[.#])[-:\w]+/
  @rest         ~S/(.+)/

  @regex        ~r/(?:#{@tag_class_id}|#{@rest})\s*/


  defp tokenize(string) do
    Regex.scan(@regex, string, trim: true) |> reduce
  end

  defp reduce([]), do: []
  defp reduce([h|t]) do
    [List.foldr(h, "", fn(x, _acc) -> x end) | reduce(t)]
  end
end
