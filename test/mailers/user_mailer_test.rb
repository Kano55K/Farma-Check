require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome" do
    user = users(:employee)
    mail = UserMailer.welcome(user)
    assert_equal "Bienvenido a Farma-Check", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match user.email_address, mail.body.encoded
  end
end
