require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Sauce'
  rdoc.options << '--line-numbers' << '--inline-source' << "--main" << "README.rdoc"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name        = %q{sauce}
  s.version     = "0.1"
  s.summary     = %q{Rack middleware for rendering Sass stylesheets}
  s.description = s.summary

  s.files        = FileList['[A-Z]*', 'lib/**/*.rb', 'spec/**/*.rb']
  s.require_path = 'lib'
  s.test_files   = Dir[*['spec/**/*_spec.rb']]

  s.has_rdoc         = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options = ['--line-numbers', '--inline-source', "--main", "README.rdoc"]

  s.authors = ["Joe Ferris"]
  s.email   = %q{joe.r.ferris@gmail.com}

  s.platform = Gem::Platform::RUBY
end

Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc "Clean files generated by rake tasks"
task :clobber => [:clobber_rdoc, :clobber_package]

desc "Generate a gemspec file"
task :gemspec do
  File.open("#{spec.name}.gemspec", 'w') do |f|
    f.write spec.to_yaml
  end
end

