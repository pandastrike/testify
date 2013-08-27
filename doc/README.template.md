# Testify

Simple synchronous and asynchronous testing, using the assertions of your choice.

Written (and most easily used) in CoffeeScript.

## Basic usage

```../examples/basic_usage.coffee```

Output:

![basic usage output](https://raw.github.com/automatthew/testify/documentation/doc/basic_usage.png)


## Asynchronous usage

```../examples/async_usage.coffee#L4```


Run your test files with the `coffee` executable, or by requiring them.

    coffee path/to/test.coffee

## Examples

[Testing the Shred HTTP client](https://github.com/automatthew/shred/blob/master/test/shred_test.coffee)

You can also use test nesting with entirely synchronous work, as a way to structure the
test results:

[Shred's header processing test](https://github.com/automatthew/shred/blob/master/test/headers_test.coffee)




