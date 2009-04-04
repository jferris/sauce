require 'spec'
require 'rr'

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'sauce'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end

describe Sauce::Parser, "given an upstream app that returns 200 and a body" do
  before do
    @upstream = 'upstream-app'
    @upstream_body = ['gimme some ', 'sass']
    @upstream_headers = { 'Magic' => 'Johnson' }
    @template = @upstream_body.join
    @env = 'environment'
    stub(@upstream).call { [200, @upstream_headers, @upstream_body] }
  end

  subject { Sauce::Parser.new(@upstream) }

  describe "called with a template that compiles correctly" do
    before do
      @engine = 'sass-engine'
      @css = 'css-ho'
      stub(Sass::Engine).new { @engine }
      stub(@engine).render { @css }

      @status, @headers, @body = subject.call(@env)
    end

    it "should pass the environment to the upstream app" do
      @upstream.should have_received.call(@env)
    end

    it "should build a Sass engine using the upstream response body" do
      Sass::Engine.should have_received.new(@template)
    end

    it "should render the Sass template" do
      @engine.should have_received.render
    end

    it "should use the rendered teplate as the response" do
      @body.should == @css
    end

    it "should return a 200 response" do
      @status.should == 200
    end

    it "should set the content length and type" do
      @headers['Content-Length'].should == @css.size.to_s
      @headers['Content-Type'].should == 'text/css'
    end

    it "should append to existing headers" do
      @upstream_headers.each do |key, value|
        @headers[key].should == value
      end
    end
  end
end

describe Sauce::Parser, "called with an upstream app that returns non-200" do
  before do
    @upstream = 'upstream-app'
    @upstream_body = 'upstream-app-body'
    @upstream_headers = 'upstream-app-headers'
    @env = 'environment'
    stub(@upstream).call { [404, @upstream_headers, @upstream_body] }
    @engine = 'sass-engine'
    stub(Sass::Engine).new { @engine }
    stub(@engine).render { 'result' }

    @app = Sauce::Parser.new(@upstream)
    @response = @app.call(@env)
  end

  it "should call the upstream app with the environment" do
    @upstream.should have_received.call(@env)
  end

  it "should return the response from the upstream app" do
    @response.should == [404, @upstream_headers, @upstream_body]
  end

  it "should not build a Sass engine" do
    Sass::Engine.should have_received.new(anything).never
  end
end
