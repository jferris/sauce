require 'rubygems'
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
    @options = { :one => '1', :two => '2' }
    stub(@upstream).call { [200, @upstream_headers, @upstream_body] }
  end

  subject { Sauce::Parser.new(@upstream, @options) }

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

    it "should build a Sass engine using the upstream response body and options" do
      Sass::Engine.should have_received.new(@template, @options)
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

    @app = Sauce::Parser.new(@upstream, {})
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

describe Sauce::Parser, "without engine options" do
  subject { Sauce::Parser.new('app') }
  it "should build" do
    subject.should be_instance_of(Sauce::Parser)
  end
end

share_examples_for "forwards to parser" do
  before do
    @upstream          = 'upstream-app'
    @prefix            = '/sauce'
    @parser            = 'sauce-parser-app'
    @file              = 'file-app'
    @root              = '/path/to/templates'
    @parser_response   = [200, {}, 'parser-response']
    @upstream_response = [200, {}, 'upstream-response']

    stub(Sauce::Parser).new { @parser }
    stub(Rack::File).   new { @file   }

    stub(@parser).  call { @parser_response   }
    stub(@upstream).call { @upstream_response }
  end
end

describe Sauce, "with a prefix and root" do
  it_should_behave_like "forwards to parser"
  before { @app = Sauce.new(@upstream, :prefix => @prefix, :root => @root) }
  subject { @app }

  it "should build a file server" do
    Rack::File.should have_received.new(@root)
  end

  it "should wrap the file server with a parser" do
    Sauce::Parser.should have_received.new(@file, :load_paths => [@root])
  end

  it "should intercept a request underneath the prefix" do
    env = env_for('/sauce/test.css')
    subject.call(env.dup).should be(@parser_response)
    updated_env = env.merge('PATH_INFO' => '/test.sass')
    @parser.should have_received.call(updated_env)
  end

  it "should not intercept a request outside the prefix" do
    env = env_for('/other/test.css')
    subject.call(env.dup).should be(@upstream_response)
    @upstream.should have_received.call(env)
  end

  def env_for(uri)
    @env = Rack::MockRequest.env_for(uri, :method => 'GET')
  end
end

describe Sauce, "without a prefix" do
  it_should_behave_like "forwards to parser"
  before { @app = Sauce.new(@upstream, :root => @root) }
  subject { @app }

  it "should use /stylesheets as the default prefix" do
    subject.prefix.should == '/stylesheets'
  end
end

describe Sauce, "without a root" do
  it_should_behave_like "forwards to parser"
  before { @app = Sauce.new(@upstream, :prefix => '/stylesheets') }
  subject { @app }

  it "should use stylesheets as the default root" do
    subject.root.should == 'stylesheets'
  end
end

describe Sauce, "without a root or prefix" do
  it_should_behave_like "forwards to parser"
  before { @app = Sauce.new(@upstream) }
  subject { @app }

  it "should use stylesheets as the default root" do
    subject.root.should == 'stylesheets'
  end

  it "should use /stylesheets as the default prefix" do
    subject.prefix.should == '/stylesheets'
  end
end
