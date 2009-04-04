require 'rack'
require 'sass'

module Sauce
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
end
