RSpec.describe Matchd::Rule::Passthrough do
  subject { described_class.new(options.merge("passthrough" => resolver)) }

  let(:options) do
    { "match" => //, "resource_class" => "ANY" }
  end

  let(:resolver) { ["udp://0.0.0.0:53"] }

  describe "options" do
    context "flat options" do
      subject { described_class.new(options.merge("passthrough" => resolver)) }

      specify do
        expect(subject).to have_attributes(
          resolver: resolver,
          passthrough_options: {}
        )
      end
    end

    context "nested resolver option" do
      subject do
        described_class.new(options.merge("passthrough" => { "resolver" => resolver }))
      end

      specify do
        expect(subject).to have_attributes(
          resolver: resolver,
          passthrough_options: {}
        )
      end
    end

    context "nested resolver and passthrough options" do
      subject do
        described_class.new(
          options.merge(
            "passthrough" => {
              "resolver" => resolver,
              "force" => false
            }
          )
        )
      end

      specify do
        expect(subject).to have_attributes(
          resolver: resolver,
          passthrough_options: { force: false }
        )
      end
    end
  end

  describe "#passthrough_resolver" do
    context "with a Async::DNS::Resolver" do
      let(:resolver) { Async::DNS::Resolver.new([[:udp, "0.0.0.0", 53]]) }

      specify do
        expect(subject.passthrough_resolver).to eql(resolver)
      end
    end

    ["system", :system, nil].each do |r|
      context "with #{r.inspect}" do
        let(:resolver) { r }

        let(:system_nameservers) { [[:udp, "0.0.0.0", 53]] }
        let(:passthrough_resolver) { instance_double(Async::DNS::Resolver) }

        before do
          expect(Async::DNS::System).to receive(:nameservers).and_return(system_nameservers)
          expect(Async::DNS::Resolver).to receive(:new).with(system_nameservers).and_return(passthrough_resolver)
        end

        specify do
          expect(subject.passthrough_resolver).to eql(passthrough_resolver)
        end
      end
    end

    context "parseable resolver config" do
      let(:resolver) { ["udp://0.0.0.1:53", ["tcp", "0.0.0.2", 53]] }
      let(:passthrough_resolver) { instance_double(Async::DNS::Resolver) }

      subject { described_class.new(options.merge("passthrough" => resolver)) }

      before do
        expect(Matchd::Glue::AsyncEndpoint).to receive(:parse).at_least(:once).and_call_original
        expect(Async::DNS::Resolver).to receive(:new).with([[:udp, "0.0.0.1", 53], [:tcp, "0.0.0.2", 53]]).and_return(passthrough_resolver)
      end

      specify do
        expect(subject.passthrough_resolver).to eql(passthrough_resolver)
      end
    end
  end

  describe "#visit!" do
    let(:server) { instance_double(Matchd::Server) }
    let(:name) { "example.test" }
    let(:resource_class) { Resolv::DNS::Resource::IN::A }
    let(:transaction) { instance_double(Async::DNS::Transaction) }

    specify do
      expect(transaction).to receive(:passthrough!).with(
        kind_of(Async::DNS::Resolver), {}
      )

      subject.visit!(server, name, resource_class, transaction)
    end

    describe "logging" do
      let(:logger) { instance_double(Logger) }
      let(:resolver) { ["udp://1.1.1.1:53"] }
      let(:server) { instance_double(Matchd::Server, logger: logger) }

      let(:response_class) { Resolv::DNS::Resource::IN::A }
      let(:response_ttl)   { 36000 }
      let(:response_name)  { "example.com." }
      let(:response_data)  { "93.184.216.34" }

      before do
        allow(transaction).to receive(:passthrough!).with(
          kind_of(Async::DNS::Resolver), kind_of(Hash)
        ).and_yield(response)
      end

      context "with answer" do
        let(:response) do
          Resolv::DNS::Message.new.tap do |m|
            m.qr = 1
            m.ra = 1
            m.rd = 1
            m.add_question(response_name, response_class)

            data = response_class.new(response_data)
            data.instance_variable_set(:@ttl, response_ttl) # this is how the MessageDecoder does it :shrug:
            m.add_answer(response_name, response_ttl, data)
          end
        end

        specify do
          expect(logger).to receive(:debug).with(";; Passthrough to upstream resolver")

          expect(logger).to receive(:debug).with(";; Question")
          expect(logger).to receive(:debug).with("#{response_name}\t#{resource_class}")

          expect(logger).to receive(:debug).with(";; Answer")
          expect(logger).to receive(:debug).with("#{response_name}\t#{response_ttl}\t#{resource_class}\t#{response_data}")

          subject.visit!(server, name, resource_class, transaction)
        end
      end

      context "without answer" do
        let(:response) do
          Resolv::DNS::Message.new.tap do |m|
            m.qr = 1
            m.ra = 1
            m.rd = 1
            m.add_question(response_name, response_class)
          end
        end

        specify do
          expect(logger).to receive(:debug).with(";; Passthrough to upstream resolver")

          expect(logger).to receive(:debug).with(";; Question")
          expect(logger).to receive(:debug).with("#{response_name}\t#{resource_class}")

          expect(logger).to receive(:debug).with(";; Answer")
          expect(logger).to receive(:debug).with(";; Empty")

          subject.visit!(server, name, resource_class, transaction)
        end
      end
    end
  end
end
