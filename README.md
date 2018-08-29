# Matchd

Matchd is a DNS server which can be configured via YAML files.

Like it's example [`RubyDNS`](https://github.com/socketry/rubydns), it uses a pattern matching rule model  but does not require you to write any ruby.

[![Build Status](https://travis-ci.org/fnordfish/matchd.svg?branch=master)](https://travis-ci.org/fnordfish/matchd)
[![Maintainability](https://api.codeclimate.com/v1/badges/9791617021f321155cb0/maintainability)](https://codeclimate.com/github/fnordfish/matchd/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/9791617021f321155cb0/test_coverage)](https://codeclimate.com/github/fnordfish/matchd/test_coverage)
[![Inline docs](https://inch-ci.org/github/fnordfish/matchd.svg?branch=master)](http://inch-ci.org/github/fnordfish/matchd)
[![Gem Version](https://badge.fury.io/rb/matchd.svg)](https://badge.fury.io/rb/matchd)

## Table of Contents

- [Matchd](#matchd)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Intended use](#intended-use)
  - [Usage](#usage)
  - [Configure the Server/Daemon (`config.yml`)](#configure-the-serverdaemon-configyml)
  - [Configure the Rules registry (`registry.yml`)](#configure-the-rules-registry-registryyml)
    - [Matching the hostname](#matching-the-hostname)
    - [Matching the resource_class](#matching-the-resourceclass)
    - [respond](#respond)
      - [`A`](#a)
      - [`AAAA`](#aaaa)
      - [`CNAME`](#cname)
      - [`MX`](#mx)
      - [`NS`](#ns)
      - [`PTR`](#ptr)
      - [`SOA`](#soa)
      - [`SRV`](#srv)
      - [`TXT`](#txt)
    - [append](#append)
    - [passthrough](#passthrough)
    - [fail](#fail)
  - [Using as a local Dev DNS](#using-as-a-local-dev-dns)
    - [macOS / resolver](#macos--resolver)
  - [Using as a library](#using-as-a-library)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
    - [Previous Work](#previous-work)

## Installation

    $ gem install matchd

## Intended use

Although it's probably possible to use as a public/private DNS, Matchd is intended to be used in a development environment where using "localhost" or "editing /etc/hosts" isn't feasible anymore. Such as:

- large list of sub-domains (use regular expressions to match them all)
- DNS record types like TXT, MX, SRV etc. for integration testing or development

The idea is to use a globally non-route-able top level domain like `.test` and configure your local system in a way, that it will use Matchd as a resolver for such domains.

You can use Matchd to hook into global top level domain such as `.com` if you wish, and Matchd will forward everything it can't match to an upstream resolver. But keep in mind that doing so can have unexpected or even catastrophic results when expediently matching a domain you actually need for work.

Please refer to the section "[Using as a local Dev DNS](#using-as-a-local-dev-dns)" on how to make your system use Matchd as a resolver.

## Usage

Print available commands and sub-commands:

    $ matchd help
    $ matchd help start          # to display details for a specific command
    $ matchd help config         # ... or sub-command
    $ matchd config help setup   # prints details for a specific sub-commands command


Create the default configuration directory within your `$HOME`

    $ matchd config setup

- `.matchd`: This is also the home for log and pid files
- `.matchd/config.yml`: Base configurations of the server
- `.matchd/registry.yml`: The registry for all of your rules

Please also see [`examples`](../examples/) for more.

## Configure the Server/Daemon (`config.yml`)

- `dot_dir`: Path to the daemons base directory. This is where log and pid files are written to.
- `listen`: Collection of interface where the server will listen on.
  This setting supports multiple formats:
  - Array/Collection form:
  ```yaml
  listen:
  - ["udp", "127.0.0.1", 15353]
  ```
  - Hash/Structure form:
  ```yaml
  listen:
  - protocol: udp
    ip: 127.0.0.1
    port: 15353
  ```
  - URL form:
  ```yaml
  listen:
  - "udp://127.0.0.1:15353"
  ```
- `resolver`: Collection of upstream resolvers for "passthrough" requests. (If a query could net been matched, we'll forward that request to this server)
  Supports the same formats as `listen`:
  - Array/Collection form:
  ```yaml
  resolver:
  - ["udp", "1.1.1.1", 53]
  ```
  - Hash/Structure form:
  ```yaml
  resolver:
  - protocol: udp
    ip: 1.1.1.1
    port: 53
  ```
  - URL form:
  ```yaml
  resolver:
  - "udp://1.1.1.1:53"
  ```
  You can also default to your system settings (NOTE that this is a single value):
  ```yaml
  resolver: system
  ```

## Configure the Rules registry (`registry.yml`)

This file uses a single key `rules` which lists all the rules. Each rule is a structure with three keys.

```yaml
- rules:
  - match: ...          # String or Regexp
    resource_class: ... # A IN::* resource record name
    _action_: ...       # How to answer this match
```

The first two options, `match` and `resource_class` describe which query to match. The third describes how to respond and should be one of: `append_question`, `respond`, `passthrough` or `fail`.

Rules will get evaluated top-to-bottom. Once a rule matches, it will get executed and processing stops.
A match always considers the name _and_ resource class of the query.

The query name can be matched against a specific string or regular expression.
The query resource class can be matched against a single or a list of targets. When a list is used, any of the targets in the list will trigger.

When no rule matches, the query will be forwarded to the configured resolvers (see `config.yml` and it's `resolver` key).

### Matching the hostname

To match against a specific name use the string notation.

```yaml
# This will only match where the requested domain is exactly `mydomain.test`, sub-domains like `sub.mydomain.test` will not match.
match: mydomain.test
```

To match all sub-domains, use a regular expression.

```yaml
# This will only match sub-domain queries like `sub.mydomain.test` or `bus.mydomain.test`, but not `mydomain.de`
match: /^\w+\.mydomain\.test$/
# This will only match sub-domain queries like `sub.mydomain.test` or `bus.mydomain.test`, and also `mydomain.de`
match: /(^\w+\.)?mydomain\.test$/
# This will also match any depth of sub-domain queries like `bus.sub.mydomain.test`:
match: /(^\w+\.)*mydomain\.test$/
```

Under the hood, Matchd uses [ruby regular expressions](https://ruby-doc.org/core-2.5.1/Regexp.html).
For the YAML configuration format only the `/.../` syntax is supported, optionally using the `m`, `x` and `i` modifiers.

When using regular expressions, it's recommended to use `^` and `$` anchors to have better control over what you want to match. Also keep in mind, that you'll need to escape dots (`.` -> `\.`).

### Matching the resource_class

A single or a list of ARPA Internet specific resource record (RRs) names:
`A`, `AAAA`, `ANY`, `CNAME`, `HINFO`, `LOC`, `MINFO`, `MX`, `NS`, `PTR`, `SOA`, `SRV`, `TXT`, `WKS`

To give some most common samples:

```yaml
# IPv4 record
resource_class: A
# IPv6 record
resource_class: AAAA
# I'm funny:
resource_class:
  - TXT
  - CNAME
```

### respond

To let a rule respond, include the `respond` key.

Supported response types are: `A`, `AAAA`, `CNAME`, `MX`, `NS`, `PTR`, `SOA`, `SRV`, `TXT`

You can configure multiple responses per rule. Each rule has it's own configuration keys (see below) but they all support a common set of options:


```yaml
ttl: 86400                # The Time-To-Live of the record (default: 86400 seconds == 24h)
name: "other.sample.test." # The absolute DNS name (needs to end with a dot). Default is the question name.
section: answer           # The answer section. One of "answer", "additional", "authority" (default: "answer")
```

To avoid clutter, there are some shortcuts when defining a rule:

1. Omit the List for single responses
2. Omit the Collection for responses that take only one argument
3. Omit the responds `resource_class` when it's the same as the queries `resource_class`

Example:

One single value response:

```yaml
- match: sample.test
  resource_class: A
  respond: 10.0.0.1

# is the same as:
- match: sample.test
  resource_class: A
  respond:
  - resource_class: A
    ip: 10.0.0.1
```

Multiple single value responses:

```yaml
- match: sample.test
  resource_class: NS
  respond:
  - 'ns1.sample.test.'
  - 'ns2.sample.test.'

# is the same as:
- match: sample.test
  resource_class: NS
  respond:
  - resource_class: NS
    host: 'ns1.sample.test.'
  - resource_class: NS
    host: 'ns2.sample.test.'
```

#### `A`

```yaml
resource_class: A
ip: "127.0.0.1"
```

#### `AAAA`

```yaml
resource_class: AAAA
ip: "::1"
```

#### `CNAME`

```yaml
resource_class: CNAME
alias: "sample.test"
```

#### `MX`

```yaml
resource_class: MX
preference: 10
host: "mail.sample.test"
```

#### `NS`

```yaml
resource_class: NS
host: "ns1.sample.test"
```

#### `PTR`

```yaml
resource_class: PTR
host: "host1.sample.test"
```

#### `SOA`

```yaml
resource_class: SOA
mname: "ns1.sample.test."       # master zone name
rname: "admin.sample.test."     # Responsible Name
serial: "1533038712"           # Serial Number
refresh: 1200                  # Refresh Time
retry: 900                     # Retry Time
expire: 3600000                # Maximum TTL / Expiry Time
minimum_ttl: 172800            # Minimum TTL
```

#### `SRV`

```yaml
resource_class: SRV
target: jabber
priority: 10
weight: 0
port: 5269
# To make this meaningful, we need to provide a name:
name: "_xmpp-server._tcp.sample.test"
```

#### `TXT`

```yaml
resource_class: TXT
txt: "some-token=value"
```

### append

Append the results of another query to the response.

```yaml
append_question: A
# is the same as:
append_question:
- A
```

Append rules accept the same common options as Respond rules. The Response rules options will take precedence if configured.

```yaml
append_question:
  ttl: 86400                # The Time-To-Live of the record (default: 86400 seconds == 24h)
  name: "other.sample.test." # The absolute DNS name (needs to end with a dot). Default is the question name.
  section: answer           # The answer section. One of "answer", "additional", "authority" (default: "answer")
  resource_class:
    - A
    - AAAA
```

Example:

```yaml
- match: dev.sample.test
  resource_class: ANY
  append_question:
    ttl: 86400
    resource_class:
    - A
    - CNAME
    - MX
    - NS
```

### passthrough

Query an upstream resolver and use its response.

Takes the same parameters as the server config's `resolver`:

```yaml
# Mixing IPv4 and IPv6 in different formats:
passthrough:
  - ["udp", "1.1.1.1", 53]
  - protocol: udp
    ip: 1.0.0.1
    port: 53
  - "tcp://[2606:4700:4700::1111]:53"
  - system

# Shortcut, if you need only one:
passthrough: system # or any other version above

# Long format with added options
passthrough:
  force: true
  resolver:
  - ["udp", "1.1.1.1", 53]
  - protocol: udp
    ip: 1.0.0.1
    port: 53
  - "tcp://[2606:4700:4700::1111]:53"
  - system
```



### fail

Indicate an error processing the query.

To cite `Async::DNS` list of list of the most commonly used errors:

- `NoError`: No error occurred.
- `FormErr`: The incoming data was not formatted correctly.
- `ServFail`: The operation caused a server failure (internal error, etc).
- `NXDomain`: Non-eXistant Domain (domain record does not exist).
- `NotImp`: The operation requested is not implemented.
- `Refused`: The operation was refused by the server.
- `NotAuth`: The server is not authoritive for the zone.

Note that the above values are all case __sensitive__!

Example:

```yaml
- match: not-there.sample.test
  resource_class: A
  fail: NXDomain

# a catchall rule:
- match: /^(\w+\.)?sample.test$/
  resource_class: A
  respond: "127.0.0.1"
```

## Using as a local Dev DNS

When using Matchd as a local dns server for development purposes, it's recommended to:

1. use non-route-able top level domains, such as `.test`
2. use a non-privileged port (usually < 1024), such as 15353 (the default)

### macOS / resolver

Create a file under `/etc/resolver/` which is named like the top level domain you'd like to specify a different resolver (Matchd) for.

```bash
cat <<EOF | sudo tee /etc/resolver/test
nameserver 127.0.0.1
nameserver ::1
port 15353
EOF
```



## Using as a library

While Matchd is intended to be used as a demonizing CLI tool, you can use it as a library.

TODO: Docs

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bin/rake install`. To release a new version, update the version number in `version.rb`, and then run `bin/rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fnordfish/matchd

## License

This software is distributed under the Mozilla Public License Version 2.0

A copy of the license text can be found in this repository under `License.txt` or at http://mozilla.org/MPL/2.0/

### Previous Work

This software is based on the ideas of:

- [vagrant-dns](https://github.com/BerlinVagrant/vagrant-dns), created by Florian Gilcher and released under the MIT License
- [rubydns](https://github.com/socketry/rubydns), created by Samuel Williams and released under the MIT License.
