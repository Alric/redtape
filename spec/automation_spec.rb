require 'spec_helper'

describe Redtape::Form do
  subject { AutomatedRegistrationForm.new(fake_rails_params) }

  context "when #populate is not defined in the subclass" do
    context "and the form provides some data that has not been whitelisted" do
      let(:fake_rails_params) {
        HashWithIndifferentAccess.new(
          :name                   => "Evan Light",
          :social_security_number => "123-456-7890",
          :addresses_attributes   => {
            "0" => {
              :address1 =>   "123 Foobar way",
              :city     =>   "Foobar",
              :state    =>   "MN",
              :zipcode  =>   "12345",
              :alarm_code => "12345"
            },
            "1" => {
              :address1 => "124 Foobar way",
              :city     => "Foobar",
              :state    => "MN",
              :zipcode  => "12345",
              :alarm_code => "12345"
            }
          }
        )
      }

      before do
        subject.save
      end


      it "uses the value(s) passed to validate_and_save to locate the model params to use for population"
      it "constantizes the symbol passed to validate_and_saves to identify the top level model class"
      it "only records attributes on the model that have been whitelisted" do
        subject.user.social_security_number.should be_nil
        subject.addresses.each { |a| a.alarm_code.should be_nil }
      end
    end
  end
end
