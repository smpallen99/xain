defmodule Xain.CallbackTest do
  use ExUnit.Case
  use Xain

  def callback(output), do: {:safe, output}

  test "after callback" do
    Application.put_env :xain, :after_callback, {__MODULE__, :callback}
    result = markup safe: true do
      div
    end
    Application.put_env :xain, :after_callback, nil
    assert result == {:safe, "<div></div>"}
  end
end
