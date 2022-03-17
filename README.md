# Hyrax::Autopopulation

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'hyrax-autopopulation'
```

And then execute:
```bash
$ bundle exec rails g hyrax:autopopulation:install
```

Or install it yourself as:
```bash
$ gem install hyrax-autopopulation
```

For Hyrax engine.rb does the include but if you are using Hyku or HykuAddons then include the module below into the files shown in order
to add the property :autopopulation_status:
````ruby
 include Hyrax::Autopopulation::AutopopulationProperty
````

into the following files:

https://github.com/ubiquitypress/hyku_addons/blob/main/app/models/concerns/hyku_addons/work_base.rb

https://github.com/ubiquitypress/hyku_addons/blob/main/app/models/concerns/hyku_addons/schema/work_base.rb


Also for Hyku & HykuAddons users only include:
````ruby
  include Hyrax::Autopopulation::SolrDocumentBehavior
````

https://github.com/ubiquitypress/hyku_addons/blob/main/app/models/concerns/hyku_addons/solr_document_behavior.rb

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
