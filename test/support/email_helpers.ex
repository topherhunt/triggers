defmodule TriggersWeb.EmailHelpers do
  use ExUnit.CaseTemplate

  def count_emails_sent, do: length(Bamboo.SentEmail.all())

  def assert_email_sent([to: to, subject: subject]) do
    unless find_email(to: to, subject: subject) do
      all = Bamboo.SentEmail.all() |> Enum.map(& "  * #{describe_email(&1)}")
      raise "No matching email found.\n\nSearched for:\n    [to: #{to}, subject: \"#{subject}\"]\n\nAll emails sent:\n#{Enum.join(all, "\n")}"
    end
  end

  def find_email([to: to, subject: subject]) do
    to = [to] |> List.flatten() |> Enum.sort()

    Bamboo.SentEmail.all()
    |> Enum.filter(& &1.to |> Keyword.values() |> Enum.sort() == to)
    |> Enum.filter(& &1.subject =~ subject)
    |> List.first()
  end

  def describe_email(email) do
    to = email.to |> Keyword.values() |> Enum.sort()
    "[to: #{inspect(to)}, subject: \"#{email.subject}\"]"
  end

  def list_all_emails do
    IO.puts "list_all_emails:"
    Bamboo.SentEmail.all() |> Enum.map(& IO.puts "  * #{describe_email(&1)}")
  end
end
