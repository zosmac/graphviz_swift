# Welcome to *GraphvizSwift*, the *Swift* language based macOS Graphviz Application.

![gomon](assets/gopher.png)

- [Overview](#overview)
- [Building *GraphvizSwift*](#building-graphviz-swift)
- [Installing *GraphvizSwift*](#installing-graphviz-swift)
- [Running *GraphvizSwift*](#running-graphviz-swift)

## Overview

*GraphvizSwift* is a [macOS](https://www.apple.com/os/macos/) application that reads [Graphviz](https://graphviz.org) [DOT Language](https://graphviz.org/doc/info/lang.html) files for display. DOT defines the nodes and edges of a network graph, which Graphviz interprets to draw a network graph diagram. On macOS, Graphviz can use [Quartz](https://developer.apple.com/documentation/quartz) to render the diagrams into the following image formats: BMP, GIF, JPEG, PDF, PNG, SVG, and TIFF.

## Building *GraphvizSwift*

Clone the GraphvizSwift repo:
```zsh
git clone git@github.com:zosmac/graphviz_swift.git
```
Proceed to the repo and `make` the installer package:
```zsh
cd graphviz_swift
make pkg
```
This creates a macOS package installer `graphvizswift-arm64.pkg` that can install the GraphvizSwift App locally or distributed to install on other macOS hosts.

## Installing *GraphvizSwift*

Open the installer package:
```zsh
open graphvizswift-arm64.pkg
```
Enter the password for your macOS system account when prompted, and the app will be installed in /Applications/GraphvizSwift.app.

## Running *GraphvizSwift*



