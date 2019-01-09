# Tiki::Torch

[![Build Status](https://travis-ci.org/aemadrid/tiki_torch.svg?branch=feature%2Fmove_to_sqs)](https://travis-ci.org/aemadrid/tiki_torch)

Master is a backwards-compatible TikiTorch branch that has been augmented for use with Amazon SQS attributes. It can consume and produce messages in the prefix-style notation, and the API should also be backwards compatible (when changing to the new version in Merchant Portal, we did have to modify the way some of the test helpers worked). The widely-used branch at https://github.com/aemadrid/tiki_torch/tree/feature/move_to_sqs has been tagged as v0.0.3 here. Previous incarnations have been versioned and tagged (version 0.0.1 is the Rabbit MQ implementation, and versions starting with v0.0.3 are Amazon SQS based).

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tiki_torch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tiki_torch

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/aemadrid/tiki_torch/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
