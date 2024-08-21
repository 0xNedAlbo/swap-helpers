# Swap Helpers

Smart contracts and libraries to help with token swaps for Coinflakes strategies.

## Getting Started

To get started with this project install the tools and dependencies:

```sh
$ bun install # install Solhint, Prettier, and other Node.js deps
```

Use `make` to build and run tests. See `Makefile` for further options.

## ISwapper Interface

The `ISwapper` interface provides a unified way to perform token swaps. There are functions to buy tokens and functions to sell tokens. Each swap supports a combination of two tokens which are called token A and token B.

To buy a fixed amount of token A, you use the `buyA()` function and you need to spend an variable amount of token B depending on current price. 

To buy a fixed amount of token B, you use the `buyB()` function and you need to spend an variable amount of token A depending on current price. 

To sell a fixed amount of token A, you use the `sellA()` function which acquires a variable amount of token B depending on price.

To sell a fixed amount of token B, you use the `sellB()` function which acquires a variable amount of token A depending on price.

There are `preview` functions to determine how much of token B is needed to get the desired amount of token A.

## License

This project is licensed under MIT.
