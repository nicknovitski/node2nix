node2nix
========
Deploy [NPM Package Manager](http://www.npmjs.org) (NPM) packages with the
[Nix package manager](http://www.nixos.org/nix)!

Table of Contents
================
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [node2nix](#node2nix)
- [Table of Contents](#table-of-contents)
- [Installation](#installation)
- [Usage](#usage)
    - [Deploying a Node.js development project](#deploying-a-nodejs-development-project)
    - [Generating a tarball from a Node.js development project](#generating-a-tarball-from-a-nodejs-development-project)
    - [Deploying a development environment of a Node.js development project](#deploying-a-development-environment-of-a-nodejs-development-project)
    - [Deploying a collection of NPM packages from the NPM registry](#deploying-a-collection-of-npm-packages-from-the-npm-registry)
    - [Generating packages for Node.js 5.x](#generating-packages-for-nodejs-5x)
- [Advanced options](#advanced-options)
    - [Development mode](#development-mode)
    - [Specifying paths](#specifying-paths)
    - [Using alternative NPM registries](#using-alternative-npm-registries)
    - [Adding unspecified dependencies](#adding-unspecified-dependencies)
    - [Adding additional/global NPM packages to a packaging process](#adding-additionalglobal-npm-packages-to-a-packaging-process)
    - [Disabling running NPM install](#disabling-running-npm-install)
- [API documentation](#api-documentation)
- [License](#license)
- [Acknowledgements](#acknowledgements)

<!-- markdown-toc end -->

Installation
============
There are two ways this package can installed.

To install this package through the Nix package manager, obtain a copy of
[Nixpkgs](http://nixos.org/nixpkgs) and run:

```bash
$ nix-env -f '<nixpkgs>' -iA nodePackages.node2nix
```

Alternatively, this package can also be installed through NPM by running:

```bash
$ npm install -g node2nix
```

Usage
=====
`node2nix` can be used for a variety of use cases.

Deploying a Node.js development project
---------------------------------------
The primary use case of `node2nix` is to deploy a development project as a NPM
package.

What Node.js developers typically do in a development setting is opening the
source code folder and running:

```bash
$ npm install
```

The above command-line instruction deploys all dependencies declared in the
[`package.json`](https://www.npmjs.org/doc/files/package.json.html) configuration
file so that the application can be run.

With `node2nix` you can use the Nix package manager for exactly the same purpose.
Running the following command generates a collection of Nix expressions from
`package.json`:

```bash
$ node2nix
```

The above command generates three files `node-packages.nix` containing Nix
expressions for the requested packge, `node-env.nix` contains the build logic
and `default.nix` is a composition expression allowing users to deploy the
package.

By running the following Nix command with these expressions, the project can be
built:

```bash
$ nix-build -A package
```

The above instruction places a `result` symlink in the current working dir
pointing to the build result. An executable part of the project can be run as
follows:

```bash
$ ./result/bin/node2nix
```

Generating a tarball from a Node.js development project
-------------------------------------------------------
The expressions that are generated by `node2nix` (shown earlier) can also be
used to generate a tarball from the project:

```bash
$ nix-build -A tarball
```

The above command-line instruction produces a tarball that can is placed in the
following location:

```bash
$ ls result/tarballs/node2nix-1.0.1.tgz
```

The above tarball can be distributed to others and installed with NPM by running:

```bash
$ npm install node2nix-1.0.1.tgz
```

Deploying a development environment of a Node.js development project
--------------------------------------------------------------------
Besides deploying a development project, it may also be useful to only install
the project's dependencies and spawning a shell session in which they can be
found.

The following command-line instruction uses the earlier generated expressions
to deploy all the dependencies and opens a development environment:

```bash
$ nix-shell -A shell
```

Within this shell session, files can be modified and run without any hassle.
For example, the following command should work without any trouble:

```bash
$ node bin/node2nix.js --help
```

Deploying a collection of NPM packages from the NPM registry
------------------------------------------------------------
The secondary use of `node2nix` is deploying existing NPM packages from the NPM
registry.

Deployment of packages from the registry is driven by a JSON specification that
looks as follows:

```json
[
  "async",
  "underscore",
  "slasp",
  { "mocha" : "1.21.x" },
  { "mocha" : "1.20.x" },
  { "nijs": "0.0.18" },
  { "node2nix": "git://github.com/svanderburg/node2nix.git" }
]
```

The above specification is basically an array of objects. For each element that
is a string, the `latest` version is obtained from the registry.

To obtain a specific version of a package, an object must defined in which the
keys are the name of the packages and the values the versions that must be
obtained.

Any version specification that NPM supports can be used, such as version numbers,
version ranges, HTTP(S) URLs, Git URLs, and GitHub identifiers.

Nix expressions can be generated from this JSON specification as follows:

```bash
$ node2nix -i node-packages.json
```

And by using the generated Nix expressions, we can install `async` through Nix as
follows:

```bash
$ nix-env -f default.nix -iA async
```

For every package for which the latest version has been requested, we can
directly refer to the name of the package to deploy it.

For packages for which a specific version has been specified, we must refer to
it using an attribute that name that is composed of its name and version
specifier.

The following command can be used to deploy the first specific version of `mocha`
declared in the JSON configuration:

```bash
$ nix-env -f default.nix -iA '"mocha-1.21.x"'
```

`node2nix` can be referenced as follows:

```bash
$ nix-env -f default.nix -iA '"node2nix-git://github.com/svanderburg/node2nix.git"'
```

Since every NPM package resolves to a package name and version number we can also
deploy any package by using an attribute consisting of its name and resolved
version number.

This command deploys NiJS version 0.0.18:

```bash
$ nix-env -f default.nix -iA '"nijs-0.0.18"'
```

Generating packages for Node.js 5.x
-----------------------------------
By default, `node2nix` generates Nix expressions that should be used in
conjuction with Node.js 4.x, the current LTS release. The feature branch (Node.js
5.x) contains the newer npm 3.x, that stores dependencies in a more flat
structure.

The flat structure can be simulated by adding the `--flatten` parameter.
Additionally, to enable all flags to make generation for Node.js 5.x work, add
the `-5` parameter. For example, running the following command generates
expressions that can be used with Node.js 5.x:

```bash
$ node2nix -5 -i node-package.json
```

By running the following command, Nix deploys NiJS version 0.0.18 using Node.js
5.x and npm 3.x:

```bash
$ nix-env -f default.nix -iA '"nijs-0.0.18"'
```

Advanced options
================
`node2nix` also has a number of advanced options.

Development mode
----------------
By default, NPM packages are deployed in production mode, meaning that the
development dependencies are not installed by default. By adding the
`--development` command line option, you can also deploy the development
dependencies:

```bash
$ node2nix --development
```

Specifying paths
----------------
If no options are specified, `node2nix` makes implicit assumptions on the
filenames of the input JSON specification and the output Nix expressions. These
filenames can be modified with command-line options:

```bash
$ node2nix --input package.json --output registry.nix --composition default.nix --node-env node-env.nix
```

Using alternative NPM registries
--------------------------------
You can also use an alternative NPM registry (such as a private one), by adding
the `--registry` option:

```bash
$ node2nix -i node-packages.json --registry http://private.registry.local
```

Adding unspecified dependencies
-------------------------------
A few exotic NPM packages may have dependencies on native libraries that reside
somewhere on the user's host system. Unfortunately, NPM's metadata does not
specify them, and as a consequence, it may result in failing Nix builds due to
missing dependencies.

As a solution, the generated expressions by `node2nix` are made overridable. The
override mechanism can be used to manually inject additional unspecified
dependencies.

The easiest way to do this is to create a wrapper Nix expression that imports
the generated composition expression from `node2nix` and injects additional
dependencies.

Consider the following package collection file (named: `node-packages.json`)
that installs one NPM package named `floomatic`:

```json
[
  "floomatic"
]
```

We can generate Nix expressions from the above specification, by running:

```bash
$ node2nix -i node-packages.json
```

One of floomatic's dependencies is an NPM package named `native-diff-match-patch`
that requires the Qt 4.x library and pkgconfig, which are native dependencies not
detected by the `node2nix` generator.

With the following wrapper expression (named: `override.nix`), we can inject
these dependencies ourselves:

```nix
{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem}:

let
  nodePackages = import ./default.nix {
    inherit pkgs system;
  };
in
nodePackages // {
  floomatic = nodePackages.floomatic.override (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.pkgconfig pkgs.qt4 ];
  });
}
```

The expression does the following:

* We import the composition expression (`default.nix`) generated by `node2nix`.
* We take the old derivation that builds the `floomatic` package, and we add the
  missing native dependencies as build inputs by defining an override.

With the above wrapper expression, we can correctly deploy floomatic, by running:

```bash
$ nix-build override.nix -A floomatic
```

Adding additional/global NPM packages to a packaging process
------------------------------------------------------------
Sometimes it may also be required to supplement a packaging process with
additional NPM packages. For example, when building certain NPM projects, some
dependencies have to be installed globally.

A prominent example of such a workflow is a [Grunt](http://gruntjs.com) project.
The grunt CLI is typically installed globally, whereas its plugins are installed
as development dependencies.

We can automate such a workflow as follows. Consider the following
`package.json` example:

```json
{
  "name": "grunt-test",
  "version": "0.0.1",
  "private": "true",
  "devDependencies": {
    "grunt": "*",
    "grunt-contrib-jshint": "*",
    "grunt-contrib-watch": "*"
  }
}
```

The above configuration declares grunt and two grunt plugins (`jshint` and
`watch`) as development dependencies.

We can create a supplemental package specification that represents additional
NPM packages that are supposed to be installed globally:

```json
[
  "grunt-cli"
]
```

The above configuration (`supplement.json`) states that we need the `grunt-cli`
as an additional package, installed globally.

Running the following command-line instruction generates the Nix expressions for
the project:

```bash
$ node2nix -d -i package.json --supplement-input supplement.json
```

By overriding the generated expressions, we can instruct the builder to execute
`grunt` after the dependencies have been deployed:

```nix
{ pkgs ? import <nixpkgs> {}
, system ? builtins.currentSystem
}:

let
  nodePackages = import ./default.nix {
    inherit pkgs system;
  };
in
nodePackages // {
  package = nodePackages.package.override {
    postInstall = "grunt";
  };
}
```

The above expression (`override.nix`) defines a `postInstall` hook that executes
grunt after the NPM package has been deployed.

Running the following command executes the packaging process, including the
grunt post-processing step:

```bash
$ nix-build override.nix -A package
```

Disabling running NPM install
-----------------------------
`node2nix` tries to mimic npm's dependency resolver as closely as possible.
However, it may happen that there is a small difference and the deployment fails
a result.

A mismatch is typically caused by versions that can't be reliably resolved (e.g.
due to wildcards) or errors in lifting bundled dependencies (with the
`--flatten` option enabled). In many cases, the package should still work
despite the error.

To prevent the deployment from failing, we can disable the `npm install` step,
by overriding the package:

```nix
{pkgs ? import <nixpkgs> {
  inherit system;
}, system ? builtins.currentSystem}:

let
  nodePackages = import ./default.nix {
    inherit pkgs system;
  };
in
nodePackages // {
  express = nodePackages.express.override (oldAttrs: {
    dontNpmInstall = true;
  });
}
```

By overriding a package and setting the `dontNpmInstall` parameter to `true`, we
skip the install step (which merely serves as a check). The generated expression
is actually responsible for obtaining and extracting the dependencies.

API documentation
=================
This package includes API documentation, which can be generated with
[JSDuck](https://github.com/senchalabs/jsduck). The Makefile in this package
contains a `duck` target to generate it and produces the HTML files in `build/`:

```bash
$ make duck
```

License
=======
The contents of this package is available under the [MIT license](http://opensource.org/licenses/MIT)

Acknowledgements
================
This package is based on ideas and principles pioneered in
[npm2nix](http://github.com/NixOS/npm2nix).
