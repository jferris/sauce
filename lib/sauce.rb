require 'rack'
require 'sass'

module Sauce
  class Parser
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      body = css_from(body)
      return [200, css_headers(headers, body), body]
    end

    private

    def css_from(body)
      render(template_from(body))
    end

    def render(template)
      Sass::Engine.new(template).render
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
