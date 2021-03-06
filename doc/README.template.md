# Testify

Simple synchronous and asynchronous testing, using the assertions of your choice.

Written (and most easily used) in CoffeeScript.

## Basic usage

```../examples/basic_usage.coffee```

Output:

![basic usage output](https://raw.github.com/automatthew/testify/documentation/doc/basic_usage.png)


## Asynchronous usage

```../examples/async_usage.coffee#L4```

Output:

![async usage output](https://raw.github.com/automatthew/testify/documentation/doc/async_usage.png)

Run your test files with the `coffee` executable, or by requiring them, or using `bin/testify [--color]`.

    coffee path/to/test.coffee
    bin/testify -c path/to/test.coffee

## Examples

[Tests for Shred, an HTTP client](https://github.com/automatthew/shred/blob/master/test/shred_test.coffee)

You can also use test nesting with entirely synchronous work, as a way to structure the
test results:

[Shred's header processing test](https://github.com/automatthew/shred/blob/master/test/headers_test.coffee)




