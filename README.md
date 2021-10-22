# inspector

![Pub Version](https://img.shields.io/pub/v/inspector?label=pub)
[![Coverage Status](https://coveralls.io/repos/github/kekland/inspector/badge.svg?branch=master)](https://coveralls.io/github/kekland/inspector?branch=master)

<img src="https://github.com/kekland/inspector/raw/master/img/inspector.png" width="100%">

A Flutter package for inspecting widgets. Comes with size inspection and a color picker (eyedropper). Useful for debugging widgets and for QA testing.

Inspired by [inspx](https://github.com/raunofreiberg/inspx).

## WIP

Warning, the development of this package is still in progress and some things may break your app.

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

## Examples

<p align="middle">
  <img src="https://github.com/kekland/inspector/raw/master/img/screenshot-1.png" width="48%">
  <img src="https://github.com/kekland/inspector/raw/master/img/screenshot-2.png" width="48%">
</p>

## Contact me

Feel free to contact me at:

E-mail: **kk.erzhan@gmail.com**
