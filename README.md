# inspector

[![Pub Version](https://img.shields.io/pub/v/inspector?label=pub)](https://pub.dev/packages/inspector)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/kekland/inspector/Test%20and%20analysis)](https://github.com/kekland/inspector/actions)
[![Coverage Status](https://coveralls.io/repos/github/kekland/inspector/badge.svg?branch=master)](https://coveralls.io/github/kekland/inspector?branch=master)
[![GitHub Repo stars](https://img.shields.io/github/stars/kekland/inspector?style=social)](https://github.com/kekland/inspector)

<img src="https://github.com/kekland/inspector/raw/master/img/inspector.png" width="100%">

A Flutter package for inspecting widgets. Also comes with an eyedropper and a magnifying glass. Useful for debugging widgets and for QA testing.

Supports keyboard shortcuts if you're using a physical keyboard.

Check out the [example web app!](https://kekland.github.io/inspector/#/)

Inspired by [inspx](https://github.com/raunofreiberg/inspx).

## WIP

Warning, the development of this package is still in progress and some things may break your app.

## Features

<img align="right" src="https://github.com/kekland/inspector/raw/master/img/example.gif" width="300px">

- [x] Color picker
- [x] Size inspection
- [x] Padding inspection
- [x] Keyboard shortcuts
- [x] Zooming 
- [ ] `BorderRadius` inspection
- [x] `TextStyle` inspection 

<br clear="right"/>

## Installing

Add the dependency: 

```bash
$ flutter pub add inspector
```

Import the package:

```dart
import 'package:inspector/inspector.dart';
```

Wrap `MaterialApp.builder` or `WidgetsApp.builder` with `Inspector`:

```dart
MaterialApp(
  home: ExampleApp(),
  builder: (context, child) => Inspector(child: child!), // Wrap [child] with [Inspector]
),
```

Optionally, you can pass `isEnabled` to the `Inspector` to disable it. By default, the inspector is disabled when `kReleaseMode == true`.

## Usage

If the inspector is enabled, then a panel appears on the right side of the screen,
with buttons to toggle size inspection and the color picker.

It's quite straightforward to use, just tap on the widget that you want to measure 
or tap on the pixel to get its color.

You can also use keyboard shortcuts - `Shift` will toggle the color picker, `Z` will toggle the zoom, and `Alt` or `Cmd` will toggle the widget inspector.

## Examples

<p align="middle">
  <img src="https://github.com/kekland/inspector/raw/master/img/screenshot-1.png" width="48%">
  <img src="https://github.com/kekland/inspector/raw/master/img/screenshot-2.png" width="48%">
</p>

## Contact me

Feel free to contact me at:

E-mail: **kk.erzhan@gmail.com**
