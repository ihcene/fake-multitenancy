# Fake-Multitenancy

With fake-multitenancy, you can serve several clients with one single database. Each client (tenant) will have it's own incremented ids. Data is transparently isolated between tenants.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fake-multitenancy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fake-multitenancy

## Usage

There's no much to do. Just install the gem and multitenancy will work out of the box. You next tables created with migrations will be multitenant ready.

You just need to have a model named Tenant. This class should respond to an instance method called `name` returning a String. Tenant should have a class method named "current" that returns an instance of Tenant.

While you should consider a database powered solution, here is the simplest implementation to test this gem :

```ruby
class Tenant
  def switch
    @@current = self
  end

  attr_accessor :name


  def self.find(name)
    new.tap{ |t| t.name = name }
  end

  def self.current
    @@current
  end
end
```

## Internals


This gem does the followings :
- Adds columns `multitenant_id` and `tenant` to all your tables (via migrations) ;
- It turns the `id` column to an indexed integer, unique, not primary key, that is assigned in a callback
- Exclude tables from multitenancy when the parameter `multitenant: false` is set on create_table calls ;
- Add a default_scope to all you models inheriting from ActiveRecord::Base ;
- Modify schema.rb generation internals by excluding the multitenancy.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fake-multitenancy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
