require 'rack'
require 'sass'

class Sauce
  class Parser
    def initialize(app, options = {})
      @app     = app
      @options = options
    end

    def call(env)
      status, headers, body = @app.call(env)
      if status == 200
        body = css_from(body)
        [200, css_headers(headers, body), body]
      else
        [status, headers, body]
      end
    end

    private

    def css_from(body)
      render(template_from(body))
    end

    def render(template)
      Sass::Engine.new(template, @options).render
    end

    def template_from(body)
      result = ''
      body.each {|part| result << part }
      result
    end

    def css_headers(headers, body)
      headers = Rack::Utils::HeaderHash.new(headers)
      headers['Content-Length'] = body.size.to_s
      headers['Content-Type'] = 'text/css'
      headers
    end
  end

  attr_reader :root, :prefix

  def initialize(app, options = {})
    @root   = options[:root]   || 'stylesheets'
    @prefix = options[:prefix] || '/stylesheets'

    @upstream_app = app
    @file_app     = Rack::File.new(root)
    @parser_app   = Parser.new(@file_app, :load_paths => [@root])
  end

  def call(env)
    if env['PATH_INFO'] =~ prefix_expr
      @parser_app.call(transform(env))
    else
      @upstream_app.call(env)
    end
  end

  private

  def transform(env)
    env.merge(
      'PATH_INFO' => env['PATH_INFO'].
                       sub(prefix_expr, '').
                       sub(/\.css$/, '.sass')
    )
  end

  def prefix_expr
    /^#{Regexp.escape(@prefix)}/
  end
end
