# Common one-line helpers that the standard Elixir lib doesn't give us.
defmodule Triggers.Helpers do

  #
  # System
  #

  def env!(key), do: System.get_env(key) || raise("Env var '#{key}' is missing!")

  def memory_mb, do: Float.round(:erlang.memory[:total] / 1_000_000.0, 3)

  #
  # Maps
  #

  def invert_map(map), do: Map.new(map, fn {k, v} -> {v, k} end)

  # Example: H.try(user_struct_or_nil, :field)
  def try(nil, _), do: nil
  def try(%{} = map, field), do: Map.get(map, field)

  #
  # Lists
  #

  def intersect?(a, b), do: Enum.any?(a, & &1 in b)

  def sort(a), do: Enum.sort(a)

  #
  # Strings
  #

  def blank?(nil), do: true
  def blank?(string) when is_binary(string), do: String.trim(string) == ""

  def present?(string), do: !blank?(string)

  def presence(string), do: if present?(string), do: string, else: nil

  def capitalize_each_word(string) when is_binary(string) do
    string |> String.split() |> Enum.map(& String.capitalize(&1)) |> Enum.join(" ")
  end

  def downcase(nil), do: nil
  def downcase(string), do: String.downcase(string)

  def to_atom(nil), do: nil
  def to_atom(string), do: String.to_atom(string)

  #
  # Integers
  #

  def to_int(nil), do: nil
  def to_int(int) when is_integer(int), do: int
  def to_int(string) when is_binary(string), do: String.to_integer(string)

  #
  # Dates
  #

  def today, do: Date.utc_today()

  def to_date(nil), do: nil
  def to_date(%DateTime{} = dt), do: DateTime.to_date(dt)
  def to_date(%NaiveDateTime{} = dt), do: NaiveDateTime.to_date(dt)

  def date_gt?(a, b), do: Date.compare(a, b) == :gt # returns true if A > B
  def date_lt?(a, b), do: Date.compare(a, b) == :lt # returns true if A < B
  def date_gte?(a, b), do: Date.compare(a, b) in [:gt, :eq] # true if A >= B
  def date_lte?(a, b), do: Date.compare(a, b) in [:lt, :eq] # true if A <= B
  def date_between?(date, a, b), do: date_gte?(date, a) && date_lte?(date, b)

  # Returns A or B, whichever is sooner.
  def ceil_date(%Date{} = a, %Date{} = b), do: if date_lt?(a, b), do: a, else: b

  # Returns A or B, whichever is later.
  def floor_date(%Date{} = a, %Date{} = b), do: if date_gt?(a, b), do: a, else: b

  #
  # Datetimes
  #

  def now, do: DateTime.utc_now()

  def datetime_gt?(a, b), do: DateTime.compare(a, b) == :gt # returns true if A > B
  def datetime_lt?(a, b), do: DateTime.compare(a, b) == :lt # returns true if A < B
  def datetime_gte?(a, b), do: DateTime.compare(a, b) in [:gt, :eq] # true if A >= B
  def datetime_lte?(a, b), do: DateTime.compare(a, b) in [:lt, :eq] # true if A <= B
  def datetime_between?(dt, a, b), do: datetime_gte?(dt, a) && datetime_lte?(dt, b)

  def beginning_of_day(%Date{} = d), do: d |> Timex.to_datetime() |> beginning_of_day()
  def beginning_of_day(%DateTime{} = dt), do: dt |> Timex.beginning_of_day()

  def end_of_day(%Date{} = d), do: d |> Timex.to_datetime() |> end_of_day()
  def end_of_day(%DateTime{} = dt), do: dt |> Timex.end_of_day()

  def hours_ago(n) when is_integer(n), do: now() |> Timex.shift(hours: -n)
  def in_hours(n) when is_integer(n), do: now() |> Timex.shift(hours: n)

  def mins_ago(n) when is_integer(n), do: now() |> Timex.shift(minutes: -n)
  def in_mins(n) when is_integer(n), do: now() |> Timex.shift(minutes: n)

  #
  # Datetime formatting
  #

  # See https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html
  def print_datetime(datetime, format \\ "%Y-%m-%d %l:%M %P") do
    if datetime, do: Timex.format!(datetime, format, :strftime)
  end

  def print_date(datetime, format \\ "%Y-%m-%d"), do: print_datetime(datetime, format)

  def print_time(datetime, format \\ "%l:%M %P"), do: print_datetime(datetime, format)

end
