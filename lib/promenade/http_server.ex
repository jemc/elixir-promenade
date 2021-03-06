
defmodule Promenade.HttpServer do
  require Logger
  import Plug.Conn
  
  alias Promenade.Registry
  alias Promenade.TextFormat
  alias Promenade.ProtobufFormat
  
  def port, do: Application.fetch_env!(:promenade, :http_port)
  def start_link(name, opts) do
    # TODO: make this actually linked
    Logger.info("#{inspect name} serving HTTP requests on port #{port()}")
    
    Plug.Adapters.Cowboy.http(__MODULE__, opts, port: port())
  end
  
  def init(opts), do: opts
  
  def call(conn = %Plug.Conn { path_info: ["status"] }, _opts) do
    conn |> respond(200, "", "")
  end
  
  def call(conn, opts) do
    incl_internal = opts |> Keyword.get(:include_internal, true)
    
    data =
      if Promenade.memory_over_hwm? do
        opts |> Keyword.fetch!(:registry) |> Registry.flush_data(incl_internal)
      else
        opts |> Keyword.fetch!(:tables) |> Registry.data(incl_internal)
      end
    
    accept =
      case conn |> get_req_header("accept") do
        []           -> ""
        [accept | _] -> accept
      end
    
    {format, content_type} =
      if accept =~ "application/vnd.google.protobuf" do
        {ProtobufFormat,
          "application/vnd.google.protobuf; " <>
          "proto=io.prometheus.client.MetricFamily; " <>
          "encoding=delimited"}
      else
        {TextFormat, "text/plain; version=0.0.4"}
      end
    
    conn |> respond(200, content_type, format.snapshot(data))
  end
  
  defp respond(conn, code, content_type, body) do
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(code, body)
  end
end
