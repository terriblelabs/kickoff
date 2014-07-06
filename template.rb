options = {}

def ask_with_default(prompt, default)
  value = ask("#{prompt} [#{default}]")
  value.blank? ? default : value
end

def git_email
  `git config --get user.email`.chomp
end

if yes?('Do you want to use Devise?')
  options[:devise_model] = ask_with_default(
    'What should the user model be called?', 'User').classify

  say "Let's seed the database with the first #{options[:devise_model]}...", :yellow
  options[:user_email]    = ask_with_default 'Email', git_email
  options[:user_password] = ask_with_default 'Password', 'password'
end

gem 'airbrake'
gem 'devise' if options[:devise_model]
gem 'foundation-rails'
gem 'haml'
gem 'newrelic_rpm'
gem 'pg'
gem 'redcarpet'
gem 'simple_form'
gem 'stamp'

gem_group :production do
  gem 'rails_12factor'
end

gem_group :development, :test do
  gem 'byebug'
  gem 'quiet_assets'
  gem 'rb-inotify', require: false
  gem 'rb-fsevent', require: false
  gem "rspec-rails", '~> 2.14.2'
end

gem_group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'foreman'
  gem 'letter_opener'
  gem 'guard-rspec'
  gem 'pry-rails'
  gem 'haml-rails'
end

gem_group :test do
  gem "capybara", '~> 2.2.1'
  gem 'poltergeist'
  gem 'connection_pool'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'ffaker'
  gem 'shoulda-matchers'
end

# configure newrelic for heroku
get 'https://gist.github.com/rwdaigle/2253296/raw/newrelic.yml', 'config/newrelic.yml'

run 'bundle install'

generate 'rspec:install'
remove_file 'app/views/layouts/application.html.erb'
generate 'foundation:install'
generate 'simple_form:install', '--foundation'

if options[:devise_model]
  generate 'devise:install'
  generate 'devise', options[:devise_model]
  generate 'devise:views'

  # create seed user
  append_to_file 'db/seeds.rb', <<-CODE
#{options[:devise_model]}.create!(
  email: %q{#{options[:user_email]}},
  password: %q{#{options[:user_password]}}) unless #{options[:devise_model]}.any?
CODE

  # create factory for user model
  create_file "spec/factories/#{options[:devise_model].underscore}s.rb", <<-CODE
FactoryGirl.define do
  factory :#{options[:devise_model].underscore} do
    email      { Faker::Internet.disposable_email }
    password   'password'
  end
end
CODE
end


# initialize guard for rspec
run 'bundle exec guard init rspec'


# enable simple factory girl syntax (create, build) in rspec
create_file 'spec/support/factory_girl.rb', <<-CODE
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
CODE


# configure sendgrid for heroku
create_file 'config/initializers/mail.rb', <<-CODE
ActionMailer::Base.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: '587',
  authentication: :plain,
  user_name: ENV['SENDGRID_USERNAME'],
  password: ENV['SENDGRID_PASSWORD'],
  domain: 'heroku.com'
}
CODE


# configure airbrake notifier
create_file 'config/initializers/airbrake.rb', <<-CODE
Airbrake.configure do |config|
  config.api_key     = ENV['AIRBRAKE_API_KEY']
  config.host        = ENV['AIRBRAKE_HOST'] if ENV['AIRBRAKE_HOST'].present?
  config.port        = 80
  config.secure      = config.port == 443
end if ENV['AIRBRAKE_API_KEY'].present?
CODE


create_file 'app/assets/stylesheets/screen.css.sass', <<-CODE
@import "foundation_and_overrides"
CODE


remove_file 'app/views/layouts/application.html.erb'
create_file 'app/views/layouts/application.html.haml', <<-CODE
!!!
%html.no-js{ lang: 'en' }
  %head
    %title= yield(:title)

    %meta{ name: 'viewport', content: 'width=device-width, initial-scale=1.0' }
    %meta{ charset: 'utf-8' }

    = csrf_meta_tag

    = stylesheet_link_tag :application
    = javascript_include_tag :application
    = javascript_include_tag "vendor/modernizr"

  %body{ body_attributes }
    = render 'shared/flashes'

    %main
      = yield
CODE


create_file 'app/views/shared/_flashes.html.haml', <<-CODE
- flash.each do |key, message|
  %p.alert{ class: key }= message
CODE

# require css assets explicitly instead of `require_tree`
gsub_file 'app/assets/stylesheets/application.css', /require_tree \.$/, 'require screen'

gsub_file 'config/initializers/secret_token.rb', /= '.*?'/, %(= ENV['SECRET_TOKEN'] || "#{SecureRandom.hex(20)}")

insert_into_file 'app/helpers/application_helper.rb', after: 'module ApplicationHelper\n' do
<<-CODE
  # Renders controller and action as CSS classes on the body element.
  def body_attributes
    {
      class: [controller.controller_name, controller.action_name].join(' ')
    }
  end
CODE
end

insert_into_file 'app/controllers/application_controller.rb', before: /^end$/ do
<<-CODE
  before_filter :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
CODE
end

create_file 'spec/support/capybara_poltergeist.rb', <<-CODE
if ENV["TRAVIS"].present?
  Capybara.default_wait_time = 240
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, timeout: 240)
  end
end

Capybara.javascript_driver = :poltergeist
CODE

create_file 'spec/support/shared_connection.rb', <<-CODE
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || ConnectionPool::Wrapper.new(:size => 1) { retrieve_connection }
  end
end

module SharedConnection
  def self.share!
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
  end
end

RSpec.configure do |config|
  config.before do
    if example.metadata[:js]
      SharedConnection.share!
    end
  end
end
CODE

rake 'db:migrate'
rake 'db:seed'

remove_file 'README.rdoc'
remove_file 'public/index.html'
remove_file 'app/assets/images/rails.png'
remove_dir 'test'

git :init
git add: '.'
git commit: %{-m 'Initial commit.\r\nGenerated by https://github.com/terriblelabs/kickoff'}
