# Contributing Guidelines

## Quick Start

### Ideas

- File an [issue][issues].
- Explain why you want the feature. How does it help you? What for do you want the feature?

### Bugs

- File an [issue][issues].
- Ideally, write a failing test and send it as a Pull Request.

### Coding

- Dredd is written in [CoffeeScript][].
- Dredd uses [Semantic Release and Conventional Changelog](#sem-rel).

#### Recommended Workflow

1. Fork Dredd.
2. Create a feature branch.
3. Write tests.
4. Write code.
5. Lint what you created: `npm run lint`
6. Send a Pull Request.
7. Make sure [test coverage][] didn't drop and all CI builds are passing.

<a name="sem-rel"></a>
#### Semantic Release and Conventional Changelog

Releasing of new Dredd versions to npm is automatically managed by [Semantic Release][].
Semantic Release makes sure correct version numbers get bumped according to the **meaning**
of your changes once your PR gets merged to `master`.

To make it work, it's necessary to follow [Conventional Changelog][]. That basically
means all commit messages in the project should follow a particular format:

```
<type>: <subject>
```

Where `<type>` is:

- `feat` - New functionality added
- `fix` - Broken functionality fixed
- `perf` - Performance improved
- `docs` - Documentation added/removed/improved/...
- `chore` - Package setup, CI setup, ...
- `refactor` - Changes in code, but no changes in behavior
- `test` - Tests added/removed/improved/...

In the rare cases when your changes break backwards compatibility, the message
must include string `BREAKING CHANGE:`. That will result in bumping the major version.

Seems hard?

- See [existing commits][] as a reference
- [Commitizen CLI][] can help you to create correct commit messages
- `npm run lint` validates format of your messages

## Handbook for Contributors and Maintainers

### Maintainers

[Apiary][] is the main author and maintainer of Dredd's [upstream repository][].
Currently responsible people are:

- [@netmilk](https://github.com/netmilk) - product decisions, feature requests
- [@honzajavorek](https://github.com/honzajavorek) - lead of development

### Programming Language

Dredd is written in [CoffeeScript][] and is meant to be ran on server using
Node.js. Before publishing to npm registry, it is compiled to plain
ES5 JavaScript code (throwaway `lib` directory).

While tests are compiled on-the-fly thanks to CoffeeScript integration with
the Mocha test framework, they actually need the code to be also pre-compiled
every time because some integration tests use code linked from `lib`. This is
certainly a flaw and it slows down day-to-day development, but unless we find
out how to get rid of the `lib` dependency, it's necessary.

Also mind that CoffeeScript is production dependency (not dev dependency),
because it's needed not only for compiling Dredd package before uploading
to npm, but also for running user-provided hooks written in CoffeeScript.

### Compiled vs pure JavaScript

Dredd uses [Drafter][] for parsing [API Blueprint][] documents. Drafter is written in C++11 and needs to be compiled during installation. Because that can cause a lot of problems in some environments, there's also pure JavaScript version of the parser, [drafter.js][]. Drafter.js is fully equivalent, but it can have slower performance. Therefore there's [drafter-npm][] package, which tries to compile the C++11 version of the parser and uses the JavaScript equivalent in case of failure.

Dredd depends on the [drafter-npm][] package. That's the reason why you can see `node-gyp` errors and failures during the installation process, even though when it's done, Dredd seems to normally work and correctly parses API Blueprint documents.

#### Forcing the JavaScript version

The `--no-optional` option forces the JavaScript version of Drafter and avoids any compilation attempts when installing Dredd:

```sh
$ npm install -g dredd --no-optional
```

#### Troubleshooting the compilation

If you need the performance of the C++11 parser, but you are struggling to get it installed, it's usually because of the following problems:

- **Your machine is missing a C++11 compiler.** See how to fix this on [Windows][Windows C++11] or [Travis CI][Travis CI C++11].
- **npm was used with Python 3.** `node-gyp`, which performs the compilation, doesn't support Python 3. If your default Python is 3 (see `python --version`), [tell npm to use an older version][npm Python].

### Versioning

Dredd follows [Semantic Versioning][]. To ensure certain stability of Dredd installations (e.g. in CI builds), users can pin their version. They can also use release tags:

- `npm install dredd` - Installs the latest published version including experimental pre-release versions.
- `npm install dredd@stable` - Skips experimental pre-release versions.

When releasing, make sure you respect the tagging:

- To release pre-release, e.g. `42.1.0-pre.7`, use just `npm publish`.
- To release any other version, e.g. `42.1.0`, use `npm publish && npm dist-tag add dredd@42.1.0 stable`.

Releasing process for standard versions is currently automated by [Semantic Release][]. Releasing process for pre-releases is not automated and needs to be done manually, ideally from a special git branch.

### Testing

Use `npm test` to run all tests. Dredd uses [Mocha][] as a test framework.
It's default options are in the `test/mocha.opts` file.

### Windows

Dredd is tested on the [AppVeyor][], a Windows-based CI. There are still [several known limitations][windows issues] when using Dredd on Windows, but the intention is to support it without any compromises. Any help with fixing problems on Windows is greatly appreciated!

### Linting

Dredd uses [coffeelint][] to lint the CoffeeScript codebase. There is a plan
to converge with Apiary's [CoffeeScript Style Guide][], but as most of
the current code was written before the style guide was introduced, it's
a long run. The effective settings are in the [coffeelint.json][] file.

Linter is optional for local development to make easy prototyping and work
with unpolished code, but it's enforced on CI level. It is recommended you
integrate coffeelint with your favorite editor so you see violations
immediately during coding.

### Changelog

Changelog is in form of [GitHub Releases][]. Currently it's automatically
generated by [Semantic Release][]. See [above](#sem-rel) to learn
about how it works.

### Documentation

The main documentation is written in [Markdown][] using [MkDocs][]. Dredd uses
[ReadTheDocs][] to build and publish the documentation:

- [https://dredd.readthedocs.io](https://dredd.readthedocs.io) - preferred long URL
- [http://dredd.rtfd.org](http://dredd.rtfd.org) - preferred short URL

Source of the documentation can be found in the [docs][] directory. To contribute to Dredd's documentation, you will need to follow the [MkDocs installation instructions](http://www.mkdocs.org/#installation). Once installed, you may use following commands:

- `npm run docs:build` - Builds the documentation
- `npm run docs:serve` - Runs live preview of the documentation

#### Note

The `docs/contributing.md` file is a [symbolic link][] to the
`.github/CONTRIBUTING.md` file, where the actual content lives.
This is to be able to serve the same content also as
[GitHub contributing guidelines][] when someone opens a Pull Request.

[symbolic link]: https://en.wikipedia.org/wiki/Symbolic_link
[contributing guidelines]: https://github.com/blog/1184-contributing-guidelines

### Coverage

Dredd strives for as much test coverage as possible. [Coveralls][] help us to
monitor how successful we are in achieving the goal. If a Pull Request
introduces drop in coverage, it won't be accepted unless the author or reviewer
provides a good reason why an exception should be made.

The Travis CI build uses following commands to deliver coverage reports:

- `npm run test:coverage` - Tests Dredd and creates the `cov.info` file
- `npm run coveralls` - Uploads the `cov.info` file to Coveralls

The first mentioned command goes like this:

1. [coffee-coverage][] is used to instrument the CoffeeScipt code.
2. Instrumented code is copied into a separate directory. We run tests in the
   directory using Mocha with a special lcov reporter, which gives us
   information about which lines were executed in a standard lcov format.
3. Because some integration tests execute the `bin/dredd` script in
   a subprocess, we collect the coverage stats also in this file. The results
   are appended to a dedicated lcov file.
4. All lcov files are then merged into one using [lcov-result-merger][]
   and sent to Coveralls.

#### Notes

-  Hand-made combined Mocha reporter is used to achieve running tests and collecting
   coverage at the same time.
-  Both Dredd code and the combined reporter decide whether to collect coverage
   or not according to contents of the `COVERAGE_DIR` environment variable, which
   sets the directory for temporary LCOV files created during coverage collection.
   (If set, collecting takes place.)


### Hacking Apiary Reporter

If you want to build something on top of the Apiary Reporter, note that it uses a public API described in following documents:

- [Apiary Tests API for anonymous test reports][]
- [Apiary Tests API for authenticated test reports][]

Following data are sent over the wire to Apiary:

- [Apiary Reporter Test Data](data-structures.md#apiary-reporter-test-data)

There is also one environment variable you could find useful:

- `APIARY_API_URL='https://api.apiary.io'` - Allows to override host of the Apiary Tests API.

### Misc Tips

- When using long CLI options in tests or documentation, please always use the notation with `=`. For example,
  use `--path=/dev/null`, not `--path /dev/null`. While both should work, the version with `=` feels
  more like standard GNU-style long options and it makes arrays of arguments for `spawn` more readable.
- Using `127.0.0.1` (in code, tests, documentation) is preferred over `localhost`.
- Prefer explicit `<br>` tags instead of [two spaces][md-two-spaces] at the end of the line when writing documentation in Markdown.


[Apiary]: https://apiary.io/

[Semantic Versioning]: http://semver.org/
[coffee-coverage]: https://github.com/benbria/coffee-coverage
[coffeelint]: http://www.coffeelint.org/
[CoffeeScript]: http://coffeescript.org
[CoffeeScript Style Guide]: https://github.com/apiaryio/coffeescript-style-guide
[Coveralls]: https://coveralls.io/github/apiaryio/dredd
[lcov-result-merger]: https://github.com/mweibel/lcov-result-merger
[Markdown]: https://en.wikipedia.org/wiki/Markdown
[MkDocs]: http://www.mkdocs.org/
[ReadTheDocs]: https://readthedocs.org/
[test coverage]: https://coveralls.io/r/apiaryio/dredd?branch=master
[Mocha]: http://mochajs.org/
[Semantic Release]: https://github.com/semantic-release/semantic-release
[Conventional Changelog]: https://github.com/conventional-changelog/conventional-changelog-angular/blob/master/convention.md
[Commitizen CLI]: https://github.com/commitizen/cz-cli
[md-two-spaces]: https://daringfireball.net/projects/markdown/syntax#p
[AppVeyor]: http://appveyor.com/

[Drafter]: https://github.com/apiaryio/drafter
[API Blueprint]: https://apiblueprint.org/
[drafter.js]: https://github.com/apiaryio/drafter.js
[drafter-npm]: https://github.com/apiaryio/drafter-npm/
[Windows C++11]: https://github.com/apiaryio/drafter/wiki/Building-on-Windows
[Travis CI C++11]: https://github.com/apiaryio/protagonist/blob/master/.travis.yml
[npm Python]: http://stackoverflow.com/a/22433804/325365

[existing commits]: https://github.com/apiaryio/dredd/commits/master
[docs]: https://github.com/apiaryio/dredd/tree/master/docs
[coffeelint.json]: https://github.com/apiaryio/dredd/tree/master/coffeelint.json
[GitHub Releases]: https://github.com/apiaryio/dredd/releases

[upstream repository]: https://github.com/apiaryio/dredd
[issues]: https://github.com/apiaryio/dredd/issues
[windows issues]: https://github.com/apiaryio/dredd/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20label%3AWindows%20

[Apiary Tests API for anonymous test reports]: https://github.com/apiaryio/dredd/blob/master/ApiaryReportingApiAnonymous.apib
[Apiary Tests API for authenticated test reports]: https://github.com/apiaryio/dredd/blob/master/ApiaryReportingApi.apib
