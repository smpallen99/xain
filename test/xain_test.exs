defmodule XainTest do
  use ExUnit.Case
  use Xain

  setup do
    Application.put_env :xain, :after_callout, nil
    Application.put_env :xain, :quote, "\""
    :ok
  end

  test "simple div" do
    result = markup do
      div()
    end
    assert result == {:safe, "<div></div>"}
  end

  test "nesting div span" do
    result = markup do
      div do
        span()
      end
    end
    assert result == {:safe, "<div><span></span></div>"}
  end

  test "attributes" do
    result = markup do
      div class: "test"
    end
    assert result == {:safe, "<div class=\"test\"></div>"}
  end

  test "escapes attributes" do
    result = markup do
      div class: "test\"><script>alert(1);</script>"
    end
    assert result == {:safe, "<div class=\"test&quot;&gt;&lt;script&gt;alert(1);&lt;/script&gt;\"></div>"}
  end

  test "attributes with do" do
    result = markup do
      div class: "test" do
        span()
      end
    end
    assert result == {:safe, "<div class=\"test\"><span></span></div>"}
  end

  test "escapes attributes with do" do
    result = markup do
      div class: "test\"><script>alert(1);</script>" do
        span()
      end
    end
    assert result == {:safe, "<div class=\"test&quot;&gt;&lt;script&gt;alert(1);&lt;/script&gt;\"><span></span></div>"}
  end

  test "contents" do
    result = markup do
      div "test"
    end
    assert result == {:safe, "<div>test</div>"}
  end

  test "escapes contents" do
    result = markup do
      div "<script>alert(1);</script>"
    end
    assert result == {:safe, "<div>&lt;script&gt;alert(1);&lt;/script&gt;</div>"}
  end

  test "escapes contents with do" do
    result = markup do
      div do
        "<script>alert(1);</script>"
      end
    end
    assert result == {:safe, "<div>&lt;script&gt;alert(1);&lt;/script&gt;</div>"}
  end

  test "can put withot escapes with raw" do
    result = markup do
      div do
        raw("<script>alert(1);</script>")
      end
    end
    assert result == {:safe, "<div><script>alert(1);</script></div>"}
  end

  test "creates an a" do
    result = markup do
      a href: "/"
    end
    assert result == {:safe, ~s(<a href="/"></a>)}
  end


  test "includes content and attributes" do
    result = markup do
      div("Some content", [class: "my-class"])
    end
    assert result == {:safe, ~s(<div class="my-class">Some content</div>)}
  end

  test "nests" do
    result = markup do
      div do
        span "my span"
      end
    end
    assert result == {:safe, "<div><span>my span</span></div>"}
  end

  test "nests 3 deep" do
    result = markup do
      div id: "one" do
        div id: "two" do
          div "Inner", id: "three"
        end
      end
    end
    assert result == {:safe, ~s(<div id="one"><div id="two"><div id="three">Inner</div></div></div>)}

  end

  test "two children" do
    result = markup do
      div do
        div(id: "one")
        div(id: "two")
      end
    end
    assert result  == {:safe, ~s(<div><div id="one"></div><div id="two"></div></div>)}
  end

  test "self closing" do
    result = markup do
      input()
    end
    assert result == {:safe, ~s(<input type="text"/>)}
  end

  test "self closing with attributes" do
    result = markup do
      input([type: :text] ++ [])
    end
    assert result == {:safe, ~s(<input type="text"/>)}
  end

  test "tag with attributes list" do
    result = markup do
      div([class: :text] ++ [])
    end
    assert result == {:safe, ~s(<div class="text"></div>)}
  end

  test "tag with attributes list no parenthesis" do
    result = markup do
      div [class: :text] ++ []
    end
    assert result == {:safe, ~s(<div class="text"></div>)}
  end

  test "tag with attributes list and do block" do
    result = markup do
      div [class: :text] ++ [] do
        span()
      end
    end
    assert result == {:safe, ~s(<div class="text"><span></span></div>)}
  end

  test "tag with contents attributes list and do block" do
    result = markup do
      div "#id", [class: :text] ++ [] do
        span()
      end
    end
    assert result == {:safe, ~s(<div id="id" class="text"><span></span></div>)}
  end

  test "Example form" do
    expected = "<form method=\"post\" action=\"/model\" name=\"form\">" <>
               "<input type=\"text\" id=\"model[name]\" name=\"model_name\" value=\"my name\"/>" <>
               "<input type=\"hidden\" id=\"model[group_id]\" name=\"model_group_id\" value=\"42\"/>" <>
               "<input type=\"submit\" name=\"commit\" value=\"submit\"/>" <>
               "</form>"


    result = markup do
      form method: :post, action: "/model", name: "form" do
        input(type: :text, id: "model[name]", name: "model_name", value: "my name")
        input(type: :hidden, id: "model[group_id]", name: "model_group_id", value: "42")
        input(type: :submit, name: "commit", value: "submit")
      end
    end
    assert result == {:safe, expected}
  end

  test "default type for input" do
    result = markup do
      input(id: 1)
    end
    assert result  == {:safe, ~s(<input type="text" id="1"/>)}
  end

  test "supports id" do
    result = markup do
      div("#id")
    end
    assert result == {:safe, ~s(<div id="id"></div>)}
  end

  test "support single class" do
    result = markup do
      div(".cls")
    end
    assert result == {:safe, ~s(<div class="cls"></div>)}
  end

  test "support douple class and id" do
    result = markup do
      div(".cls.two#ids")
    end
    assert result == {:safe, ~s(<div id=\"ids\" class=\"cls two\"></div>)}
  end

  test "support class and id attributes" do
    result = markup do
      div class: "cls two", id: "ids"
    end
    assert result == {:safe, ~s(<div class=\"cls two\" id=\"ids\"></div>)}
  end

  test "support .class and content and attribute" do
    result = markup do
      div ".cls content", for: "text"
    end
    assert result == {:safe, ~s(<div class="cls" for="text">content</div>)}
  end

  test "support string interpolation" do
    result = markup do
      var = "test"
      div ".#{var} content"
    end
    assert result == {:safe, ~s(<div class="test">content</div>)}
  end

  test "li, label, and input" do
    expected = "<li class=\"string input optional stringish\" id=\"contact_first_name_input\">" <>
    "<label class=\"label\" for=\"contact_first_name\">first_name</label><input type=\"text\" " <>
    "maxlength=\"255\" id=\"contact_first_name\" name=\"contact[first_name]\" value=\"\"/></li>"
    result = markup do
      model_name = "contact"
      field_name = "first_name"
      ext_name = "#{model_name}_#{field_name}"

      li( class: "string input optional stringish", id: "#{ext_name}_input") do
        label(".label #{field_name}", for: ext_name)
        input(type: :text, maxlength: "255", id: ext_name, name: "#{model_name}[#{field_name}]", value: "")
      end
    end
    assert result == {:safe, expected}
  end

  test "supports nested markups" do
    markup do
      result = markup :nested do
        div ".second"
      end
      assert result == {:safe, ~s(<div class="second"></div>)}
    end
  end
  test "supports nested markups with tags" do
    result2 = markup do
      div ".first"
      result = markup :nested do
        div ".second"
      end
      assert result == {:safe, ~s(<div class="second"></div>)}
      span()
    end
    assert result2 == {:safe, ~s(<div class="first"></div><span></span>)}
  end

  test "supports nested markups nested in tags" do
    result2 = markup do
      div ".first" do
        result = markup :nested do
          div ".second"
        end
        assert result == {:safe, ~s(<div class="second"></div>)}
        span()
      end
    end
    assert result2 == {:safe, ~s(<div class="first"><span></span></div>)}
  end

  test "supports raw" do
    result = markup do
      div ".test" do
        raw "<span>myspan</span>"
      end
    end
    assert result == {:safe, ~s(<div class="test"><span>myspan</span></div>)}
  end
  test "support raw safe content" do
    result = markup do
      div ".another" do
        raw {:safe, ["<span>", "my span", "</span>"]}
      end
    end
    assert result == {:safe, ~s(<div class="another"><span>my span</span></div>)}
  end
  test "supports ' quote" do
    Application.put_env :xain, :quote, "'"
    result = markup do
      div ".test"
    end
    assert result == {:safe, ~s(<div class='test'></div>)}
  end

  test ".class with nested element" do
    field_name = "id"
    result = th(".sortable.th-#{field_name}") do
      a "Id", href: "#test"
    end
    assert result == {:safe, ~s(<th class="sortable th-id"><a href="#test">Id</a></th>)}
  end

  test "doesn't fail with invalid inner block" do
    result = div do
      nil
    end
    assert result == {:safe, ~s(<div></div>)}

    result = div do
      :ok
    end
    assert result == {:safe, ~s(<div></div>)}
  end
end
