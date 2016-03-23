
defmodule Promenade.RegistryTest do
  use ExUnit.Case
  doctest Promenade.Registry
  
  def make_subject, do: ({:ok, s} = Promenade.Registry.start_link(nil, []); s)
  
  test "accumulates metrics into its state" do
    subject = make_subject
    
    Promenade.Registry.handle_metrics subject, [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
      {:gauge, "foo", 44.4, %{ "y" => "YYY" }},
      {:gauge, "foo2", 22.2, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 99, %{ "x" => "XXX" }},
      {:counter, "bar", 33, %{ "y" => "YYY" }},
      {:counter, "bar2", 11, %{ "x" => "XXX", "y" => "YYY" }},
      {:summary, "baz", 5.5, %{ "x" => "XXX" }},
    ]
    
    assert Promenade.Registry.get_state(subject).gauges == %{
      "foo" => %{
        %{ "x" => "XXX" } => 88.8,
        %{ "y" => "YYY" } => 44.4,
      },
      "foo2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 22.2
      },
    }
    
    assert Promenade.Registry.get_state(subject).counters == %{
      "bar" => %{
        %{ "x" => "XXX" } => 99,
        %{ "y" => "YYY" } => 33,
      },
      "bar2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 11
      },
    }
    
    summary =
      Promenade.Registry.get_state(subject).summaries
      |> Map.get("baz")
      |> Map.get(%{ "x" => "XXX" })
    
    assert Promenade.Summary.count(summary)          == 1
    assert Promenade.Summary.sum(summary)            == 5.5
    assert Promenade.Summary.quantile(summary, 0.5)  == 5.5
    assert Promenade.Summary.quantile(summary, 0.9)  == 5.5
    assert Promenade.Summary.quantile(summary, 0.99) == 5.5
    
    Promenade.Registry.handle_metrics subject, [
      {:gauge, "foo", 77.7, %{ "x" => "XXX" }},
      {:gauge, "foo2", 33.3, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 123, %{ "x" => "XXX" }},
      {:counter, "bar2", 100, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    assert Promenade.Registry.get_state(subject).gauges == %{
      "foo" => %{
        %{ "x" => "XXX" } => 77.7,
        %{ "y" => "YYY" } => 44.4,
      },
      "foo2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 33.3
      },
    }
    
    assert Promenade.Registry.get_state(subject).counters == %{
      "bar" => %{
        %{ "x" => "XXX" } => 222,
        %{ "y" => "YYY" } => 33,
      },
      "bar2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 111
      },
    }
    
    ["baz1", "baz2"] |> Enum.each fn(name) ->
      [%{ "x" => "XXX" }, %{ "y" => "YYY" }] |> Enum.each fn(labels) ->
        Promenade.Registry.handle_metrics subject, [
          {:summary, name, 5.5,  labels},
          {:summary, name, 1.1,  labels},
          {:summary, name, 2.2,  labels},
          {:summary, name, 3.3,  labels},
          {:summary, name, 10.1, labels},
          {:summary, name, 100,  labels},
          {:summary, name, 88.8, labels},
          {:summary, name, 43.5, labels},
          {:summary, name, 45.5, labels},
          {:summary, name, 33.3, labels},
        ]
        
        summary =
          Promenade.Registry.get_state(subject).summaries
          |> Map.get(name)
          |> Map.get(labels)
        
        assert Promenade.Summary.count(summary)          == 10
        assert Promenade.Summary.sum(summary)            == 333.3
        assert Promenade.Summary.quantile(summary, 0.5)  == 33.3
        assert Promenade.Summary.quantile(summary, 0.9)  == 100
        assert Promenade.Summary.quantile(summary, 0.99) == 100
      end
    end
  end
end
