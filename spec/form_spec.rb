require 'spec_helper'

class RegistrationController
  include RegistrationRedtape
end

describe Redtape::Form do
  subject { Redtape::Form.new(controller_stub, :top_level_name => :user) }

  context "given a Form accepting a first and last name that creates a User" do
    context "with valid data" do
      let (:controller_stub) {
        RegistrationController.new.tap do |c|
          c.stub(:params).and_return({
            :user => {
              :first_name => "Evan",
              :last_name => "Light"
            }
          })
        end
      }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should be_valid }
        specify { subject.model.should be_valid }
        specify { subject.model.should be_persisted }
      end

      context "after validating the form" do
        before do
          subject.valid?
        end

        specify { subject.model.should be_valid }
      end
    end

    context "with invalid data" do
      let (:controller_stub) {
        RegistrationController.new.tap do |c|
          c.stub(:params).and_return({
            :user => {
              :first_name => "Evan"
            }
          })
        end
      }

      context "after saving the form" do
        before do
          subject.save
        end

        specify { subject.should_not be_valid }
        specify { subject.should_not be_persisted }
        specify { subject.errors.should have_key(:name) }
        specify { subject.model.should_not be_valid }
      end
    end
  end

  context "Creating a Redtape::Form that provides whitelisted attrs and a #populate_individual_record impl" do
    let(:controller_stub) {
      RegistrationController.new.tap { |c|
        c.stub(:params => {
          :user => { :first_name => "Evan " }
        })
      }
    }

    it "should raise a DuelingBanjosError" do
      expect {
          Redtape::Form.new(controller_stub, :whitelisted_attrs => { :user => [:name] })
      }.to raise_error(Redtape::DuelingBanjosError)
    end
  end
end

