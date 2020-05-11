defmodule ListsEQC do
  use ExUnit.Case
  use EQC.ExUnit

  property "reversing a list twice yields the original list" do
    forall l <- list(int()) do
      ensure(l |> Enum.reverse() |> Enum.reverse() == l)
    end
  end

  property "encoding is the reverse of decoding" do
    forall bin <- binary() do
      ensure(bin |> Base.encode64() |> Base.decode64!() == bin)
    end
  end

  property "appending an element and sorting it is the same as prepending an element and sorting it" do
    forall {i, l} <- {int, list(int)} do
      ensure([i | l] |> Enum.sort() == (l ++ [i]) |> Enum.sort())
    end
  end

  property "tail of list" do
    forall l <- non_empty(list(int)) do
      [_head | tail] = l
      ensure(tl(l) == tail)
    end
  end

  property "list concatenation" do
    forall {l1, l2} <- {list(int), list(int)} do
      ensure(Enum.concat(l1, l2) == l1 ++ l2)
    end
  end

  defp join(parts, delimiter) do
    parts |> Enum.intersperse(delimiter) |> Enum.join()
  end

  defp string_with_commas() do
    let len <- choose(1, 10) do
      vector(len, frequency([{3, oneof(:lists.seq(?a, ?z))}, {1, ?,}]))
    end
  end

  property "splitting a string with a delimiter and joining it again yields the same string" do
    forall s <- string_with_commas do
      s = to_string(s)

      :eqc.classify(
        String.contains?(s, ","),
        :string_with_commas,
        ensure(String.split(s, ",") |> join(",") == s)
      )
    end
  end

  def nested_list(gen) do
    sized size do
      nested_list(size, gen)
    end
  end

  defp nested_list(0, _gen) do
    []
  end

  defp nested_list(n, gen) do
    lazy do
      oneof([[gen | nested_list(n - 1, gen)], [nested_list(n - 1, gen)]])
    end
  end
end
