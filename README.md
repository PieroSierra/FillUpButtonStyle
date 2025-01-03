**FillUpButtonStyle**

A style to be used for an action that requires a big build up & release, for example "new habit achieved!"

When applied to a a SwiftUI Button, this style:
* Sets up a pill visual style with icon + text
* Sets up the button to be reactive to press-and hold

When pressing-and-holding, the button progressively fills up, while playing a build-up sound and increasingly strong haptic vibration.  

If released early, it empties out.
If held until release, it stays colored, plays a release sound, and displays a Metal 'ripple' animation to indicate success
