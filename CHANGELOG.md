## 4.0.1

* `Y` and `Z` shortcuts now require a modifier key (Alt, Ctrl, or Meta) to prevent accidental activation while typing on desktop.
* Exposed shortcut parameters (`inspectorShortcuts`, `inspectAndCompareShortcuts`, `colorPickerShortcuts`, `zoomShortcuts`) directly on the `Inspector` widget.
* Fixed a bug where releasing the modifier before the letter key left the inspector stuck in `inspectAndCompare` or `zoom` mode. Thanks @yelmuratoff!

## 4.0.0

* Major codebase improvements and better inspector handling for certain box types (e.g. `FittedBox`). Also supports inspecting inside of widgets like `InteractiveViewer`. Thanks @EArminjon!
* Exposed `BorderRadius` properties for better inspection of `DecoratedBox` widgets. Thanks @alpinnz!
* Major refactor - the codebase is now split into `InspectorController` and `Inspector`. This means that you can now build your own custom inspector UI by using the `InspectorController`, instead of being tied down to the default one. You can check out the example at `custom_inspector_example.dart`. Thanks @yelmuratoff!

## 3.1.0

* Added "compare" functionality - if a box is selected, you can now hold `Y` and hover another box to see the difference in the boxes' position. Thanks @EArminjon!
* Improved handling for selecting boxes - it now doesn't rely on hit testing, which should make it possible to select boxes that aren't hit-testable, but are visible on the screen. Thanks @EArminjon!
* Better text inspection - for rich text, it'll now display all the styles applied to the text. Thanks @EArminjon!

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
