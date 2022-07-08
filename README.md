# rpi-ws281x-swift

Swift wrapper for [rpi-ws281x](https://github.com/richardghirst/rpi_ws281x)

### Usage
```swift
let strip = PixelStrip(numLEDs: 64, pin: 18, brightness: 40)
strip.begin()

let colors: [Color] = [.red, .green, .blue, .white, .black]
for i in 0..<64 {
  strip.setPixelColor(pos: i, color: colors[i % 5])
}
```
