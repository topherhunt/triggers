defmodule Triggers.NaggerTest do
  use Triggers.DataCase
  import Factory

  setup do
    # Clear all emails sent by previous tests. Tests CANNOT be async.
    Bamboo.SentEmail.reset()
  end

  describe "#send_nags" do
    test "sends the correct reminders" do
      user1 = insert_user()
      # user2 = insert_user()

      trigger1 = insert_trigger(user: user1)
      trigger2 = insert_trigger(user: user1)
      trigger3 = insert_trigger(user: user1, last_nagged_at: H.mins_ago(20))
      trigger4 = insert_trigger(user: user1)
      trigger5 = insert_trigger(user: user1, last_nagged_at: H.mins_ago(10))
      # trigger6 = insert_trigger(user: user2)

      insert_trigger_instance(trigger: trigger1, due_at: H.hours_ago(1))
      insert_trigger_instance(trigger: trigger2, due_at: H.in_hours(1))
      insert_trigger_instance(trigger: trigger3, due_at: H.hours_ago(1))
      insert_trigger_instance(trigger: trigger4, due_at: H.hours_ago(1), status: "done")
      insert_trigger_instance(trigger: trigger5, due_at: H.hours_ago(1))
      # insert_trigger_instance(trigger: trigger6, due_at: H.in_hours(1))

      Triggers.Nagger.send_nags()

      # Setup:
      # - trigger1 is due recently, so it's mentioned in the nag email
      # - trigger2 is due in 1 hour, so it's not mentioned in the nag email
      # - trigger3 is same as trigger1 (nagged, but can now re-nag)
      # - trigger4 is resolved, so it's not mentioned in the nag email
      # - trigger5 was just nagged, so it's ignored
      # - trigger6 isn't due yet, so it's skipped

      assert count_emails_sent() == 1
      assert_email_sent(to: user1.email, subject: "2 due triggers")
      email = find_email(to: user1.email, subject: "2 due triggers")
      assert email.html_body =~ trigger1.title
      assert email.html_body =~ trigger3.title
    end
  end
end
