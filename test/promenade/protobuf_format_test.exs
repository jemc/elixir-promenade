
defmodule Promenade.ProtobufFormatTest do
  use ExUnit.Case
  
  alias Promenade.ProtobufFormat
  alias Promenade.ProtobufFormat.Messages, as: M
  alias Promenade.Summary
  
  test "prints formatted metrics from table data" do
    data = {
      [
        {"foo", %{
          %{ "x" => "XXX" } => 77.7,
          %{ "y" => "YYY" } => 44.4,
        }},
        {"foo2", %{
          %{ "x" => "XXX", "y" => "YYY" } => 33.3
        }},
      ],
      [
        {"bar", %{
          %{ "x" => "XXX" } => 222,
          %{ "y" => "YYY" } => 33,
        }},
        {"bar2", %{
          %{ "x" => "XXX", "y" => "YYY" } => 111
        }},
      ],
      [
        {"baz", %{
          %{ "x" => "XXX" } => Summary.new(5.5),
          %{ "y" => "YYY" } => Summary.new(6.6),
        }},
        {"baz2", %{
          %{ "x" => "XXX", "y" => "YYY" } => Summary.new(3.3),
        }},
      ],
    }
    
    expected = [
      M.MetricFamily.new(
        type: :GAUGE,
        name: "foo",
        metric: [
          M.Metric.new(
            gauge: M.Gauge.new(value: 77.7),
            label: [M.LabelPair.new(name: "x", value: "XXX")]
          ),
          M.Metric.new(
            gauge: M.Gauge.new(value: 44.4),
            label: [M.LabelPair.new(name: "y", value: "YYY")]
          )
        ]
      ),
      M.MetricFamily.new(
        type: :GAUGE,
        name: "foo2",
        metric: [
          M.Metric.new(
            gauge: M.Gauge.new(value: 33.3),
            label: [
              M.LabelPair.new(name: "x", value: "XXX"),
              M.LabelPair.new(name: "y", value: "YYY"),
            ]
          )
        ]
      ),
      M.MetricFamily.new(
        type: :COUNTER,
        name: "bar",
        metric: [
          M.Metric.new(
            counter: M.Counter.new(value: 222),
            label: [M.LabelPair.new(name: "x", value: "XXX")]
          ),
          M.Metric.new(
            counter: M.Counter.new(value: 33),
            label: [M.LabelPair.new(name: "y", value: "YYY")]
          )
        ]
      ),
      M.MetricFamily.new(
        type: :COUNTER,
        name: "bar2",
        metric: [
          M.Metric.new(
            counter: M.Counter.new(value: 111),
            label: [
              M.LabelPair.new(name: "x", value: "XXX"),
              M.LabelPair.new(name: "y", value: "YYY"),
            ]
          )
        ]
      ),
      M.MetricFamily.new(
        type: :SUMMARY,
        name: "baz",
        metric: [
          M.Metric.new(
            label: [M.LabelPair.new(name: "x", value: "XXX")],
            summary: M.Summary.new(
              sample_count: 1,
              sample_sum:   5.5,
              quantile: [
                M.Quantile.new(quantile: 0.5,  value: 5.5),
                M.Quantile.new(quantile: 0.9,  value: 5.5),
                M.Quantile.new(quantile: 0.99, value: 5.5),
              ]
            )
          ),
          M.Metric.new(
            label: [M.LabelPair.new(name: "y", value: "YYY")],
            summary: M.Summary.new(
              sample_count: 1,
              sample_sum:   6.6,
              quantile: [
                M.Quantile.new(quantile: 0.5,  value: 6.6),
                M.Quantile.new(quantile: 0.9,  value: 6.6),
                M.Quantile.new(quantile: 0.99, value: 6.6),
              ]
            )
          ),
        ]
      ),
      M.MetricFamily.new(
        type: :SUMMARY,
        name: "baz2",
        metric: [
          M.Metric.new(
            label: [
              M.LabelPair.new(name: "x", value: "XXX"),
              M.LabelPair.new(name: "y", value: "YYY"),
            ],
            summary: M.Summary.new(
              sample_count: 1,
              sample_sum:   3.3,
              quantile: [
                M.Quantile.new(quantile: 0.5,  value: 3.3),
                M.Quantile.new(quantile: 0.9,  value: 3.3),
                M.Quantile.new(quantile: 0.99, value: 3.3),
              ]
            )
          )
        ]
      )
    ]
    |> Enum.map(&ProtobufFormat.Messages.MetricFamily.encode/1)
    |> Enum.map(&ProtobufFormat.Messages.MetricFamily.decode/1)
    
    assert expected ==
      ProtobufFormat.snapshot(data)
      |> Enum.map(&ProtobufFormat.Messages.MetricFamily.decode(Enum.at(&1, 1)))
    
    # # Use the following call to print the snapshot bytes in hex:
    # IO.inspect ProtobufFormat.snapshot(data), limit: 9999, base: :hex
    assert ProtobufFormat.snapshot(data) == [
      [
        <<0x35>>, <<
          0x0A, 0x03, 0x66, 0x6F, 0x6F, 0x18, 0x01, 0x22,
          0x15, 0x0A, 0x08, 0x0A, 0x01, 0x78, 0x12, 0x03,
          0x58, 0x58, 0x58, 0x12, 0x09, 0x09, 0xCD, 0xCC,
          0xCC, 0xCC, 0xCC, 0x6C, 0x53, 0x40, 0x22, 0x15,
          0x0A, 0x08, 0x0A, 0x01, 0x79, 0x12, 0x03, 0x59,
          0x59, 0x59, 0x12, 0x09, 0x09, 0x33, 0x33, 0x33,
          0x33, 0x33, 0x33, 0x46, 0x40
        >>
      ], [
        <<0x29>>, <<
          0x0A, 0x04, 0x66, 0x6F, 0x6F, 0x32, 0x18, 0x01,
          0x22, 0x1F, 0x0A, 0x08, 0x0A, 0x01, 0x78, 0x12,
          0x03, 0x58, 0x58, 0x58, 0x0A, 0x08, 0x0A, 0x01,
          0x79, 0x12, 0x03, 0x59, 0x59, 0x59, 0x12, 0x09,
          0x09, 0x66, 0x66, 0x66, 0x66, 0x66, 0xA6, 0x40,
          0x40
        >>
      ], [
        <<0x35>>, <<
          0x0A, 0x03, 0x62, 0x61, 0x72, 0x18, 0x00, 0x22,
          0x15, 0x0A, 0x08, 0x0A, 0x01, 0x78, 0x12, 0x03,
          0x58, 0x58, 0x58, 0x1A, 0x09, 0x09, 0x00, 0x00,
          0x00, 0x00, 0x00, 0xC0, 0x6B, 0x40, 0x22, 0x15,
          0x0A, 0x08, 0x0A, 0x01, 0x79, 0x12, 0x03, 0x59,
          0x59, 0x59, 0x1A, 0x09, 0x09, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x80, 0x40, 0x40
        >>
      ], [
        <<0x29>>, <<
          0x0A, 0x04, 0x62, 0x61, 0x72, 0x32, 0x18, 0x00,
          0x22, 0x1F, 0x0A, 0x08, 0x0A, 0x01, 0x78, 0x12,
          0x03, 0x58, 0x58, 0x58, 0x0A, 0x08, 0x0A, 0x01,
          0x79, 0x12, 0x03, 0x59, 0x59, 0x59, 0x1A, 0x09,
          0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0x5B,
          0x40
        >>
      ], [
        <<0xB1, 0x01>>, <<
          0x0A, 0x03, 0x62, 0x61, 0x7A, 0x18, 0x02, 0x22,
          0x53, 0x0A, 0x08, 0x0A, 0x01, 0x78, 0x12, 0x03,
          0x58, 0x58, 0x58, 0x22, 0x47, 0x08, 0x01, 0x11,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x16, 0x40,
          0x1A, 0x12, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0xE0, 0x3F, 0x11, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x16, 0x40, 0x1A, 0x12, 0x09, 0xCD,
          0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xEC, 0x3F, 0x11,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x16, 0x40,
          0x1A, 0x12, 0x09, 0xAE, 0x47, 0xE1, 0x7A, 0x14,
          0xAE, 0xEF, 0x3F, 0x11, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x16, 0x40, 0x22, 0x53, 0x0A, 0x08,
          0x0A, 0x01, 0x79, 0x12, 0x03, 0x59, 0x59, 0x59,
          0x22, 0x47, 0x08, 0x01, 0x11, 0x66, 0x66, 0x66,
          0x66, 0x66, 0x66, 0x1A, 0x40, 0x1A, 0x12, 0x09,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0x3F,
          0x11, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x1A,
          0x40, 0x1A, 0x12, 0x09, 0xCD, 0xCC, 0xCC, 0xCC,
          0xCC, 0xCC, 0xEC, 0x3F, 0x11, 0x66, 0x66, 0x66,
          0x66, 0x66, 0x66, 0x1A, 0x40, 0x1A, 0x12, 0x09,
          0xAE, 0x47, 0xE1, 0x7A, 0x14, 0xAE, 0xEF, 0x3F,
          0x11, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x1A,
          0x40
        >>
      ], [
        <<0x67>>, <<
          0x0A, 0x04, 0x62, 0x61, 0x7A, 0x32, 0x18, 0x02,
          0x22, 0x5D, 0x0A, 0x08, 0x0A, 0x01, 0x78, 0x12,
          0x03, 0x58, 0x58, 0x58, 0x0A, 0x08, 0x0A, 0x01,
          0x79, 0x12, 0x03, 0x59, 0x59, 0x59, 0x22, 0x47,
          0x08, 0x01, 0x11, 0x66, 0x66, 0x66, 0x66, 0x66,
          0x66, 0x0A, 0x40, 0x1A, 0x12, 0x09, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0xE0, 0x3F, 0x11, 0x66,
          0x66, 0x66, 0x66, 0x66, 0x66, 0x0A, 0x40, 0x1A,
          0x12, 0x09, 0xCD, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC,
          0xEC, 0x3F, 0x11, 0x66, 0x66, 0x66, 0x66, 0x66,
          0x66, 0x0A, 0x40, 0x1A, 0x12, 0x09, 0xAE, 0x47,
          0xE1, 0x7A, 0x14, 0xAE, 0xEF, 0x3F, 0x11, 0x66,
          0x66, 0x66, 0x66, 0x66, 0x66, 0x0A, 0x40
        >>
      ]
    ]
  end
end
