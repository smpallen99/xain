defmodule Xain.HelpersTest do
  use ExUnit.Case
  import Xain.Helpers


  test "id_and_class_shortcuts empty contents and attrs" do
    assert id_and_class_shortcuts("", []) == {"", []}
  end

  test "id_and_class_shortcuts empty contents and some attrs" do
    attrs = [class: "cls"]
    assert id_and_class_shortcuts("", attrs) == {"", attrs}
  end

  test "id_and_class_shortcuts some contents and some attrs" do
    attrs = [class: "cls"]
    assert id_and_class_shortcuts("test", attrs) == {"test", attrs}
  end
  
  test "id_and_class_shortcuts #id" do
    assert id_and_class_shortcuts("#test", []) == {"", [id: "test"]}
  end

  test "id_and_class_shortcuts doesn't broke multilines" do
    str = """
      line1
      line2
      line3
    """
    assert id_and_class_shortcuts(str, []) == {str, []}
  end
end
