/*
 WS281x.swift

 Copyright (c) 2022 Chris Simpson (apocolipse)
 Licensed under the MIT license, as follows:
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */

import rpi_ws281x
import CoreFoundation

public class PixelStrip {
  private var ledStrip: ws2811_t
  private typealias ChannelKeyPath = WritableKeyPath<(ws2811_channel_t, ws2811_channel_t), ws2811_channel_t>
  private var channel: ChannelKeyPath

  public init(numLEDs: Int32, pin: Int32, stripType: WSKind = .WS2811, dma: Int32 = 10, invert: Bool = false,
              brightness: UInt8 = 255, channel: UInt8 = 0, gamma: UInt8 = 0) {

    // Create ws2811_t structure and fill in parameters
    self.ledStrip = ws2811_t()

    // Initialize the channels to zero
    let channelKPs: [ChannelKeyPath] = [\.0, \.1]
    for kp in channelKPs {
      ledStrip.channel[keyPath: kp].count = 0
      ledStrip.channel[keyPath: kp].gpionum = 0
      ledStrip.channel[keyPath: kp].invert = 0
      ledStrip.channel[keyPath: kp].brightness = 0
    }

    // initialize channel in use
    self.channel = channel == 0 ? \.0 : \.1
    ledStrip.channel[keyPath: self.channel].gamma = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    ledStrip.channel[keyPath: self.channel].gamma.pointee = gamma
    ledStrip.channel[keyPath: self.channel].count = numLEDs
    ledStrip.channel[keyPath: self.channel].gpionum = pin
    ledStrip.channel[keyPath: self.channel].invert = invert ? 1 : 0
    ledStrip.channel[keyPath: self.channel].brightness = brightness
    ledStrip.channel[keyPath: self.channel].strip_type = stripType.cStriptype

    // initialize the controller
    ledStrip.freq = stripType.getDuty().frequency
    ledStrip.dmanum = dma
  }

  deinit {
    ws2811_fini(&ledStrip)
  }

  public func begin() {
    let resp = ws2811_init(&ledStrip)
    if resp != .init(0) {
      let respString = String(cString: ws2811_get_return_t_str(resp)!)
      fatalError("ws2811_init failed with code \(resp) (\(respString)")
    }

  }

  public func show() {
    let resp = ws2811_render(&ledStrip)
    if resp != .init(0) {
      let respString = String(cString: ws2811_get_return_t_str(resp)!)
      fatalError("ws2811_render failed with code \(resp) (\(respString)")
    }
  }

  public func setPixelColor(pos: Int, color: Color) {
    ledStrip.channel[keyPath: self.channel][pos] = ws2811_led_t(color: color)
  }

  public var brightness: UInt8 {
    get { ledStrip.channel[keyPath: self.channel].brightness }
    set { ledStrip.channel[keyPath: self.channel].brightness = newValue }
  }
}

public struct Color {
  public var red, green, blue: UInt8
  public var white: UInt8 = 0

  public init(red: UInt8, green: UInt8, blue: UInt8){
    self.red = red
    self.green = green
    self.blue = blue
  }

  public static var black = Color(red: 0, green: 0, blue: 0)
  public static var white = Color(red: 255, green: 255, blue: 255)
  public static var red = Color(red: 255, green: 0, blue: 0)
  public static var green = Color(red: 0, green: 255, blue: 0)
  public static var blue = Color(red: 0, green: 0, blue: 255)
}

private extension ws2811_led_t {
  init(color: Color) {
    self = 0
    self |= UInt32(color.white) << 24
    self |= UInt32(color.red)   << 16
    self |= UInt32(color.green) << 8
    self |= UInt32(color.blue)
  }

  var color: Color {
    return Color(red: UInt8(truncatingIfNeeded: self >> 16 & 0xff),
                 green: UInt8(truncatingIfNeeded: self >> 8 & 0xff),
                 blue: UInt8(truncatingIfNeeded: self & 0xff),
                 white: UInt8(truncatingIfNeeded: self >> 24 & 0xff))
  }
}

extension ws2811_channel_t {
  subscript(_ pos: Int) -> ws2811_led_t? {
    get {
      guard pos < count else { return nil }
      return UnsafeBufferPointer(start: leds, count: Int(count))[pos]
    }
    set {
      guard pos < count, let newValue = newValue else { return }
      UnsafeMutableBufferPointer(start: leds, count: Int(count))[pos] = newValue
    }
  }
}


// From uraimo/WS281x.swift
public enum WSKind {
  case WS2811       //T0H:0.5us  T0L:2.0us,  T1H:1.2us  T1L:1.3us ,  resDelay > 50us
  case WS2812       //T0H:0.35us T0L:0.8us,  T1H:0.7us  T1L:0.6us ,  resDelay > 50us
  case WS2812B      //T0H:0.35us T0L:0.9us,  T1H:0.9us  T1L:0.35us , resDelay > 50us
  case WS2812B2017  //T0H:0.35us T0L:0.9us,  T1H:0.9us  T1L:0.35us , resDelay > 300us 2017 revision of WS2812B
  case WS2812S      //T0H:0.4us  T0L:0.84us, T1H:0.85us T1L:0.4us ,  resDelay > 50us
  case WS2813       //T0H:0.35us T0L:0.9us,  T1H:0.9us  T1L:0.35us , resDelay > 250us ?
  case WS2813B      //T0H:0.25us T0L:0.6us,  T1H:0.6us  T1L:0.25us , resDelay > 280us ?

  fileprivate var cStriptype: Int32 {
    // FIXME:
    return WS2811_STRIP_GRB
  }
  public func getDuty() -> (zero: Int, one: Int, frequency: UInt32, resetDelay: Int){
    switch self{
    case .WS2811:      return (33,66,800_000,55)
    case .WS2812:      return (33,66,800_000,55)
    case .WS2812B:     return (33,66,800_000,55)
    case .WS2812B2017: return (33,66,800_000,300)
    case .WS2812S:     return (33,66,800_000,55)
    case .WS2813:      return (33,66,800_000,255)
    case .WS2813B:     return (30,70,800_000,280)
    }
  }
}
