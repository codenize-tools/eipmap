# Eipmap

Eipmap is a tool to manage Elastic IP Addresses (EIP).

It defines the state of EIP using DSL, and updates EIP according to DSL.

[![Gem Version](https://badge.fury.io/rb/eipmap.svg)](http://badge.fury.io/rb/eipmap)
[![Build Status](https://travis-ci.org/winebarrel/eipmap.svg?branch=master)](https://travis-ci.org/winebarrel/eipmap)
[![Coverage Status](https://coveralls.io/repos/winebarrel/eipmap/badge.png?branch=master)](https://coveralls.io/r/winebarrel/eipmap?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eipmap'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eipmap

## Usage

```sh
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_REGION='us-east-1'
eipmap -e -o EIPfile  # export EIP status
vi EIPfile
eipmap -a --dry-run
eipmap -a             # apply `EIPfile`
```

## Help

```
Usage: eipmap [options]
    -p, --profile PROFILE_NAME
        --credentials-path PATH
    -k, --access-key ACCESS_KEY
    -s, --secret-key SECRET_KEY
    -r, --region REGION
    -a, --apply
    -f, --file FILE
        --dry-run
        --allow-reassociation
    -e, --export
    -o, --output FILE
        --no-color
        --debug
```

## EIPfile example

```ruby
require 'other/eipfile'

domain "standard" do
  ip "54.256.256.1"
  ip "54.256.256.2", :instance_id=>"i-12345678"
end

domain "vpc" do
  ip "54.256.256.11", :network_interface_id=>"eni-12345678", :private_ip_address=>"10.0.1.1"
  ip "54.256.256.12", :network_interface_id=>"eni-12345678"  #, :private_ip_address=>"10.0.1.2" (optional)
  ip "54.256.256.13"
end
```
