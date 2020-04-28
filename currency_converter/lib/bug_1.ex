defmodule Cashy.Bug1 do
  def convert(:sgd, :usd, amount) do
    {:ok, amount * 0.70}
  end

  def run() do
    convert(:sgd, :usd, 100)
  end
end
