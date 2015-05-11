
describe Ngrok::Tunnel do

  describe "Before start" do

    it "should not be running" do
      expect(Ngrok::Tunnel.running?).to be false
    end

    it "should be stopped" do
      expect(Ngrok::Tunnel.stopped?).to be true
    end

    it "should have status = :stopped" do
      expect(Ngrok::Tunnel.status).to eq :stopped
    end

  end

  describe "Run process" do

    before(:all) do
      Ngrok::Tunnel.start
    end

    after(:all) { Ngrok::Tunnel.stop }

    it "should be running" do
      expect(Ngrok::Tunnel.running?).to be true
    end

    it "should not be stopped" do
      expect(Ngrok::Tunnel.stopped?).to be false
    end

    it "should have status = :running" do
      expect(Ngrok::Tunnel.status).to eq :running
    end

    it "should match local_port" do
      expect(Ngrok::Tunnel.port).to eq(3001)
    end

    it "should have valid ngrok_url" do
      expect(Ngrok::Tunnel.ngrok_url).to be =~ /http:\/\/.*ngrok\.io$/
    end

    it "should have valid ngrok_url_https" do
      expect(Ngrok::Tunnel.ngrok_url_https).to be =~ /https:\/\/.*ngrok\.io$/
    end

    it "ngrok_url_tcp should be nil" do
      expect(Ngrok::Tunnel.ngrok_url_tcp).to eq(nil)
    end

    it "should have pid > 0" do
      expect(Ngrok::Tunnel.pid).to be > 0
    end
  end

  describe 'load multiple tunnels from config file' do
    before(:all) do
      Ngrok::Tunnel.start({ config: '~/.ngrok2/ngrok.yml' })
    end

    after(:all) { Ngrok::Tunnel.stop }

    it "should have valid ngrok_url_tcp" do
      expect(Ngrok::Tunnel.ngrok_url_tcp).to be =~ /tcp:\/\/.*tcp\.*ngrok\.io:\d{5}$/
    end
  end

  describe "Custom log file" do
    it "should be able to use custom log file" do
      Ngrok::Tunnel.start(log: 'test.log')
      expect(Ngrok::Tunnel.running?).to eq true
      expect(Ngrok::Tunnel.log.path).to eq 'test.log'
      Ngrok::Tunnel.stop
      expect(Ngrok::Tunnel.stopped?).to eq true
    end
  end

  describe "Custom subdomain" do
    it "should fail with incorrect authtoken" do
      expect {Ngrok::Tunnel.start(subdomain: 'test-subdomain', authtoken: 'incorrect_token')}.to raise_error
    end
  end

end
