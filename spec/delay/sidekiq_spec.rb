require 'spec_helper'

begin
  require 'rollbar/delay/sidekiq'
  require 'sidekiq/testing'
rescue LoadError
end

describe Rollbar::Delay::Sidekiq, :if => defined?(Sidekiq) do
  let(:payload) { anything }

  describe "#perform" do
    it "performs payload" do
      Rollbar.should_receive(:process_payload).with(payload)
      subject.perform payload
    end
  end

  describe "#call" do
    shared_examples "a Rollbar processor" do

      it "processes payload" do
        Rollbar.should_receive(:process_payload).with(payload)

        subject.call payload
        described_class.drain
      end
    end

    context "with default options" do
      it "enqueues to default queue" do
        options = Rollbar::Delay::Sidekiq::OPTIONS.merge('args' => payload)
        ::Sidekiq::Client.should_receive(:push).with options

        subject.call payload
      end

      it_behaves_like "a Rollbar processor"
    end

    context "with custom options" do
      let(:custom_config) { { 'queue' => 'custom_queue' } }
      subject { Rollbar::Delay::Sidekiq.new custom_config }

      it "enqueues to custom queue" do
        options = Rollbar::Delay::Sidekiq::OPTIONS.merge(custom_config.merge('args' => payload))
        ::Sidekiq::Client.should_receive(:push).with options

        subject.call payload
      end

      it_behaves_like "a Rollbar processor"
    end
  end
end
