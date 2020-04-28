defmodule Cashy.Bug3 do
  def convert(:sgd, :usd, amount) when amount > 0 do
    {:ok, amount * 0.70}
  end

  def run(amount) do
    case convert(:sgd, :usd, amount) do
      _ ->
        IO.puts("converted amount is #{amount}")
    end
  end
end
