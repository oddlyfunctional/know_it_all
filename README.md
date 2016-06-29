> Well, actually...

# KnowItAll

KnowItAll is a small, object-oriented approach to authorization. It knows everything about your application!

More of an architectural pattern for API-focused authorization than properly a dependency, and heavily inspired by [Pundit](https://github.com/elabs/pundit), this gem simply provides a small set of helpers that make applying the pattern easier.

If your application needs to validate pre-requisites before performing certain actions, at the same time providing helpful error messages for the API's clients, all that while using regular magic-less Ruby and object oriented design patterns, KnowItAll is your friend.

## Why?

The assumption made is that each action has its own requirements based on the current context. Some may be related to the current user's permissions in the system, others with the parameters sent, and others yet may even have nothing to do with any input received. Let's say you're building the API for a food delivery app. To be able to checkout, you need to validate the following requirements:

- The user must be signed in;
- The user must have a registered address;
- The registered address must be within a determined radius;
- The cart must contain at least $10 in items;
- The chosen items must be available for delivery;
- The store must be opened.

It'd be very helpful for a developer consuming this API if, in case of failure, the API returned an appropriate error message explaining exactly what when wrong, instead of an empty `403 Forbidden`. Performing this manually is easy, but quickly polutes the action's code:

```ruby
class OrdersController < ApplicationController
  def create
    return error("User must be signed in") unless current_user
    return error("User must have a registered address") unless current_user.address
    return error("Registered address is outside the range") unless address_in_range?(current_user.address)
    return error("Cart must contain at least $10 in items") unless cart_has_minimum?(cart)
    return error("Some of the items are not available") unless items_available?(cart.items)
    return error("The store is closed") unless store.opened?

    # Here finally starts what the action actually does
    order = Order.create(order_params)
    if order.save
      render json: order, status: :created
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def error(message)
      render json: { error: message }, status: :forbidden
    end
end
```

It's much more readable, as well as easier to test and extend, if all of those requirement tests were contained in a proper class:

```ruby
class OrdersController < ApplicationController
  def create
    policy = OrdersPolicy::Create.new(current_user, cart, store)
    return render json: { errors: authorization.errors } unless policy.authorize?

    order = Order.create(order_params)
    if order.save
      render json: order, status: :created
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
```

That's exactly the architectural pattern encouraged by this gem. By including a small set of helpers, it makes it extremely simple to perform complex validations and provide helpful feedback through the API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'know_it_all'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install know_it_all

## Usage

There are two steps to using this gem: creating and using policies:

### Using policies

The simplest approach is to include the `KnowItAll` module in the controller you want to perform the validation. For this example, let's make the helpers available to all controllers by including it in the `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
end
```

After that, we can use the helpers in any controller that inherits from `ApplicationController`:

```ruby
class OrdersController < ApplicationController
  def create
    authorize current_user, cart, store

    order = Order.create(order_params)
    if order.save
      render json: order, status: :created
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
```

### What to do when the authorization failed

The `authorize` method raises a `KnowItAll::NotAuthorized` exception in case the authorization has failed, and contains the instance of the policy used to perform the validation:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
  rescue_from KnowItAll::NotAuthorized do |exception|
    render json: { errors: exception.policy.errors }, status: :forbidden
  end
end
```

This pattern is so common that I've wrote a method that does exactly that:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
  rescue_from KnowItAll::NotAuthorized, with: :render_not_authorized
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/know_it_all. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

