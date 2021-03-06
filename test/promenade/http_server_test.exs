
defmodule Promenade.HttpServerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  
  alias Promenade.HttpServer
  alias Promenade.Registry
  alias Promenade.TextFormat
  alias Promenade.ProtobufFormat
  
  def registry do
    {:error, {:already_started, pid}} = Registry.start_link(Registry, [])
    
    pid
  end
  
  def tables, do: registry() |> Registry.get_tables
  
  def call_opts, do: [registry: registry(), tables: tables()]
  
  def call(method, path, include_internal) do
    conn(method, path)
    |> HttpServer.call(call_opts() ++ [include_internal: include_internal])
  end
  
  def call(method, path, include_internal, accept_header) do
    conn(method, path)
    |> put_req_header("accept", accept_header)
    |> HttpServer.call(call_opts() ++ [include_internal: include_internal])
  end
  
  test "/status" do
    conn = call(:get, "/status", false)
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == ""
    
    [content_type] = conn |> get_resp_header("content-type")
    assert content_type =~ ""
  end
  
  test "/metrics (no flush - metrics are retained between scrapes)" do
    Registry.handle_metrics registry(), [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
    ]
    
    expected_body = tables() |> Registry.data(false) |> TextFormat.snapshot
    
    conn = call(:get, "/metrics", false)
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
    
    [content_type] = conn |> get_resp_header("content-type")
    assert content_type =~ "text/plain"
    
    conn = call(:get, "/metrics", false)
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
    
    [content_type] = conn |> get_resp_header("content-type")
    assert content_type =~ "text/plain"
  end
  
  test "/metrics (flush due to memory high water mark)" do
    Registry.handle_metrics registry(), [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
    ]
    
    expected_body = tables() |> Registry.data(false) |> TextFormat.snapshot
    
    # Set a very low high water mark that we are surely already above,
    # which will ensure a flush on the next metrics scrape.
    Application.put_env(:promenade, :memory_hwm, Promenade.memory / 10)
    assert Promenade.memory_over_hwm?
    
    conn = call(:get, "/metrics", false)
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
    
    [content_type] = conn |> get_resp_header("content-type")
    assert content_type =~ "text/plain"
    
    # Reset high water mark.
    Application.put_env(:promenade, :memory_hwm, 0)
    assert !Promenade.memory_over_hwm?
    
    conn = call(:get, "/metrics", false)
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == TextFormat.snapshot({[], [], []})
    
    [content_type] = conn |> get_resp_header("content-type")
    assert content_type =~ "text/plain"
  end
  
  test "/metrics (protobuf format preferred when accepted)" do
    Registry.handle_metrics registry(), [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
    ]
    
    expected_body =
      tables()
      |> Registry.data(false)
      |> ProtobufFormat.snapshot
      |> List.flatten
      |> Enum.join
    
    accept_header = "application/vnd.google.protobuf; text/plain"
    conn = call(:get, "/metrics", false, accept_header)
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
    
    [content_type] = conn |> get_resp_header("content-type")
    assert content_type =~ "application/vnd.google.protobuf"
  end
end
