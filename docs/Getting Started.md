# Getting Started

This is a polyglot [monorepo](https://monorepo.tools/) that requires multiple toolchains to be set up. Theoretically, we could use a build tool like [Pants](https://pantsbuild.org) or [Bazel](https://bazel.build) to integrate everything, but unfortunately those build systems don't have great support for [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/), so I decided I'd rather just use each language's native toolchains instead. That means:

- [pnpm](https://pnpm.io/) for [TypeScript](https://www.typescriptlang.org/)
- [cargo](https://doc.rust-lang.org/cargo/guide/why-cargo-exists.html) for [Rust](https://www.rust-lang.org/)
- [tenv](https://tofuutils.github.io/tenv/) for [OpenTofu](https://opentofu.org)
- ...and so on and so forth. There's also linters, formatters, etc.

So, as an alternative to [Make](https://www.gnu.org/software/make/), we're using [just](https://just.systems/). That means there's recipes defined in a [justfile](/justfile) that will run cross-toolchain tasks, like linting. So getting started should be as easy as

1. Installing `just` ([instructions](https://just.systems/man/en/chapter_4.html))
2. Running `just install`

If you're getting an error like "Justfile does not contain recipe ``install``", that means I haven't setup a recipe for your operating system yet. You can look at the recipe definition and figure out what deps you'll need to install. And you can contribute an install script for your OS!
