## 3.0.0

* Bump Flutter version to >=3.22.0

## 2.2.0

* Added ColorScheme hints when using the color picker. Can be optionally disabled by passing `isColorPickerColorSchemeHintEnabled: false`. Thanks https://github.com/JoseAlba!

## 2.1.0

* Made `InspectorState` public to allow the developers to toggle the state of Inspector on/off. Thanks https://github.com/lublak!

## 2.0.1

* Fixed a minor bug with zoom gestures not working properly on mobile platforms.

## 2.0.0

* Fixed a bug where using keyboard shortcuts with the color picker would spam a lot of errors in the console.
* Added a magnifying glass

## 1.1.4

* Fix color picker index going out of bounds

## 1.1.3

* Bugfixes

## 1.1.2

* Added support for different properties on `RenderParagraph` and `RenderDecoratedBox`.
* Bugfixes related to bootstrapping Inspector on a portion of a screen.

## 1.1.1

* Minor README changes
* Deployed the example app to GitHub pages

## 1.1.0

* Added support for keyboard shortcuts. You can now press `Cmd` or `Alt` to toggle the widget inspector, and press `Shift` to toggle the color picker.
* Added customization options to `Inspector` - you can disable individual features, customize the shortcuts, or hide the panel.

## 1.0.5

* Minor README changes

## 1.0.4

* Enabling the inspector will absorb the pointers. This is done so that tappable widgets can also be inspected.

## 1.0.3

* Added a loading indicator for color picker
* Added widget tests

## 1.0.1, 1.0.2

* Minor README changes

## 1.0.0

* Initial release!
* Added widget inspector and a color picker.
