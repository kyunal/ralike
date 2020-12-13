# ralike

A reddit-username-alike finder using pushshift comment data, written in [crystal](https://crystal-lang.org)

## Installation

Clone the repository. Requires [crystal](https://crystal-lang.org/install) to run.

## Usage

As there are no dependencies other than Crystal's standard library, you can just run the tool using something like
```shell
$ crystal run src/ralike.cr -- -i INPUT -c CONFIG
```
or after compilation using something like
```shell
$ ralike -i INPUT -c CONFIG
```
The [input](#input) and [config](#config) parameters are both mandatory, each represent a JSON file.
You can see other available parameters by either giving no parameters or using `-h`/`--help`.

### Config

The config describes, what should be matched. Multiple possible matches can be defined.
So far, matching is possible using Levenshtein distance as well as defining a regex pattern to match. You can use either or both options simultaneously.
If a config entry uses both options, only one of them has to be matched. An example config can be found [here](examples/config.json).

### Input

`ralike` uses search data provided by pushhift in the form of comment data. Currently, this must be done manually.  
I suggest to use a tool like [redditsearch.io](https://www.redditsearch.io/) to do this. Keep in mind, only comments are supported so far.

## Development

There's nothing specific for now. Things will be changed as needed.

## Hacking

If you feel that a config/matching option is missing, you can simply add it.

First, you'll have to adjust the JSON Mapping for the config, which is `ConfigEntry` in [mappings.cr](src/mappings.cr). This will retain the tool's modularity.
After that is done, you can add the feature definition in the most inner loop which iterates over config entries.
Add code to validate your option using `name` for the comment's author and append a string to `reasons` if it matches. Everything else will be handled automatically.
See the implementation of `distance` in [ralike.cr](src/ralike.cr#L81) for a specific example.

## Contributing

1. Fork it (<https://github.com/kyunal/ralike/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [kyunal](https://github.com/kyunal) - creator and maintainer
