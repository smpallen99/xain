ExUnit.start()

defmodule Xain.Case do
  import ExUnit.CaptureIO


  def capture_log(level \\ :debug, fun) do
    Logger.configure(level: level)
    capture_io(:user, fn ->
      fun.()
      GenEvent.which_handlers(:error_logger)
      GenEvent.which_handlers(Logger)
    end)
  after
    Logger.configure(level: :debug)
  end

end